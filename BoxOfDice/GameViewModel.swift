//
//  GameViewModel.swift
//  BoxOfDice
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {

    @Published private var engine = GameEngine()
    @Published private(set) var isRolling = false
    @Published private var animationDice: [Int] = [0, 0, 0]
    @Published private(set) var highlightedHint: Set<Int> = []
    @Published private(set) var elapsedSeconds: Int = 0

    /// Bumped after every meaningful action (roll settling, tile toggle,
    /// confirm, undo, new game, restore). BOD-006: the view observes this to
    /// know when to persist the current game — a single counter is simpler
    /// and can't miss a case the way hooking every individual published
    /// property could.
    @Published private(set) var revision: Int = 0

    private let feedback: GameFeedbackProviding
    private var rollTask: Task<Void, Never>?
    private var autoRollTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var gameStartTime: Date?

    /// Test seam (R4 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md): every
    /// "current time" read in the timer path goes through this instead of
    /// calling `Date()` directly, so a test can freeze/advance time deterministically
    /// rather than racing the real periodic tick's ~100ms cadence against a
    /// real-time sleep. Production code never sets this — it defaults to the
    /// real clock and behaves exactly like `Date()`.
    var now: () -> Date = Date.init
    private var diceAnimationSpeed: DiceAnimationSpeed = .normal
    private var feedbackOptions = FeedbackOptions()
    private var isTimed: Bool = false
    private var reduceMotion: Bool = false

    /// Dice already drawn for a roll that hasn't been committed to the
    /// engine yet (the animation is still in flight). Exposed so a save
    /// triggered while backgrounding mid-roll can capture it — the restore
    /// path commits this directly instead of redrawing or losing it.
    private(set) var pendingRollDiceForSaving: [Int]?

    // A future WatchGameView can reuse this view model with either GameFeedback.shared
    // or a watchOS-specific GameFeedbackProviding adapter.
    init(feedback: GameFeedbackProviding? = nil) {
        self.feedback = feedback ?? GameFeedback.shared
    }

    // MARK: - Forwarded Game State

    var tiles: [Tile] { engine.tiles }
    var selectedTiles: Set<Int> { engine.selectedTiles }
    var gameState: GameState { engine.gameState }
    var score: Int { engine.score }
    var remainingOpenTiles: [Int] { engine.openTiles }
    var selectionTotal: Int { engine.selectionTotal }
    /// Number of dice to display at rest. While rolling, this is the
    /// animation's own die count (`rollingDieCount`, fixed at roll start).
    /// Once a roll has landed, it must reflect how many dice were actually
    /// rolled last — NOT `engine.currentDieCount`, which can already
    /// describe the *next* roll (Quick Game drops from two dice to one once
    /// only low tiles remain). Using the next roll's count here would hide
    /// one of the just-completed roll's dice while its result — and the
    /// dice-total text — are still showing. Before any roll, there is no
    /// "last roll" to reflect, so this shows the upcoming roll's count.
    var dieCount: Int {
        if isRolling { return rollingDieCount }
        if hasRolled { return dice.filter { $0 > 0 }.count }
        return engine.currentDieCount
    }
    var canRoll: Bool {
        guard !isRolling, case .waitingToRoll = engine.gameState else { return false }
        return true
    }
    var canSelectTiles: Bool {
        guard !isRolling, case .selecting = engine.gameState else { return false }
        return true
    }
    var canConfirm: Bool { !isRolling && engine.canConfirm }
    var canUndo: Bool { !isRolling && engine.canUndo }
    var moveHistory: [MoveRecord] { engine.moveHistory }
    var turnCount: Int { engine.turnCount }
    var possibleMoveCount: Int { engine.validMoves().count }

    /// Timed modes (Speed Run, Big Box Speed) always animate at the standard
    /// "normal" speed regardless of the user's animation-speed setting, so the
    /// setting cannot be used to shave time off the clock. Untimed modes honour
    /// the user's choice as before. The view reads this (not the raw setting)
    /// for the visible dice animation, so it always matches the interaction lock.
    var effectiveDiceAnimationSpeed: DiceAnimationSpeed { isTimed ? .normal : diceAnimationSpeed }

    /// Reduce Motion replaces the tumble with a short, calm state change —
    /// both here (how long the roll locks interaction) and in `Dice3DView`
    /// (what it shows during that time). Timed modes still get this: it
    /// shortens the lock, it doesn't lengthen anything, so there's no way to
    /// use it to shave time off the clock unfairly.
    var effectiveRollDurationNanoseconds: UInt64 {
        reduceMotion ? 220_000_000 : effectiveDiceAnimationSpeed.totalRollDurationNanoseconds(dieCount: rollingDieCount)
    }

    // MARK: - End-of-game result flags (read by the celebration layer)

    /// Every tile is closed.
    var didClearBoard: Bool { engine.isWinner }

    /// The board is cleared with no open tiles left (tile score 0). Combined with
    /// the mode (Classic) by the caller to decide a Perfect Clear.
    var isPerfectClear: Bool { engine.isWinner && engine.score == 0 }

    /// The score that counts for stats and best-score comparisons, including the
    /// elapsed-seconds penalty in timed modes.
    var finalScore: Int { engine.score + (isTimed ? elapsedSeconds : 0) }

    private var rollingDieCount = 2

    // During rolling, display the animation frames; afterwards show the real dice.
    var dice: [Int] { isRolling ? animationDice : engine.dice }
    var diceTotal: Int { dice.reduce(0, +) }
    var hasRolled: Bool { engine.hasRolled }

    // MARK: - Save/restore (BOD-006)

    /// A snapshot of the pure engine state, for `GameSaveStore`. Everything
    /// SwiftUI-, feedback-, and timing-related is gathered separately by the
    /// view alongside this.
    var engineSnapshot: GameEngine { engine }
    var gameStartTimeForSaving: Date? { gameStartTime }

    // MARK: - Actions

    func configure(diceAnimationSpeed: DiceAnimationSpeed, feedbackOptions: FeedbackOptions, isTimed: Bool = false, reduceMotion: Bool = false) {
        self.diceAnimationSpeed = diceAnimationSpeed
        self.feedbackOptions = feedbackOptions
        self.isTimed = isTimed
        self.reduceMotion = reduceMotion
    }

    func rollDice() {
        guard case .waitingToRoll = engine.gameState, !isRolling else {
            errorFeedback()
            return
        }

        // Start timer on the very first roll of a timed game
        if isTimed && gameStartTime == nil {
            startTimer()
        }

        highlightedHint = []
        autoRollTask?.cancel()
        rollTask?.cancel()
        isRolling = true
        rollingDieCount = engine.currentDieCount

        // Play the rattle as the dice are thrown so it tracks the tumble, rather
        // than firing when they settle (~0.86s later, which read as a lag).
        soundDiceRoll()

        let finalDice = engine.randomDice()
        animationDice = finalDice
        pendingRollDiceForSaving = finalDice
        let rollDuration = effectiveRollDurationNanoseconds

        rollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: rollDuration)
            guard !Task.isCancelled else { return }
            engine.roll(dice: finalDice)
            pendingRollDiceForSaving = nil
            if case .gameOver(let won) = engine.gameState {
                if won { successFeedback() } else { errorFeedback() }
                gameOverSound(won: won)
                stopTimer()
            }
            isRolling = false
            rollTask = nil
            bumpRevision()
        }
    }

    func toggleTile(_ number: Int) {
        guard !isRolling, case .selecting = engine.gameState,
              engine.tiles.first(where: { $0.id == number })?.isOpen == true else {
            errorFeedback()
            return
        }

        highlightedHint = []
        engine.toggleTile(number)
        lightFeedback()
        bumpRevision()
    }

    func confirmSelection() {
        guard !isRolling, engine.canConfirm else {
            errorFeedback()
            return
        }

        engine.confirmSelection()
        mediumFeedback()
        soundTileFlip()
        highlightedHint = []

        if case .gameOver(let won) = engine.gameState {
            if won { successFeedback() }
            gameOverSound(won: won)
            stopTimer()
        }

        // If the game continues, throw the next dice automatically after a short
        // beat so the player doesn't have to tap Roll every turn.
        if case .waitingToRoll = engine.gameState {
            scheduleAutoRoll()
        }
        bumpRevision()
    }

    private func scheduleAutoRoll(delay: UInt64 = 450_000_000) {
        autoRollTask?.cancel()
        autoRollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            guard case .waitingToRoll = engine.gameState, !isRolling else { return }
            rollDice()
        }
    }

    func showHint() {
        guard !isRolling, case .selecting = engine.gameState, let hint = engine.bestHint() else {
            errorFeedback()
            return
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.7)) {
            highlightedHint = Set(hint)
        }
        lightFeedback()
    }

    func undoLastMove() {
        guard !isRolling, engine.canUndo else {
            errorFeedback()
            return
        }
        engine.undoLastMove()
        highlightedHint = []
        lightFeedback()
        bumpRevision()
    }

    /// Called when the app moves to the background. A roll in flight has
    /// already drawn its final dice (`pendingRollDiceForSaving`) — this
    /// commits that same result immediately instead of leaving the
    /// animation's sleep timer running while suspended. Never changes the
    /// actual result, only how soon it's applied; mirrors what `restore(...)`
    /// already does for a pending roll saved mid-animation. Game
    /// progression (and `persistCurrentGame()`, driven by `revision`) never
    /// depended on this task finishing on its own — this only tidies up the
    /// in-flight animation state promptly instead of leaving it stranded.
    func handleScenePhaseBackground() {
        guard isRolling, let finalDice = pendingRollDiceForSaving else { return }
        rollTask?.cancel()
        rollTask = nil
        engine.roll(dice: finalDice)
        pendingRollDiceForSaving = nil
        if case .gameOver = engine.gameState { stopTimer() }
        isRolling = false
        bumpRevision()
    }

    func diceSettledFeedback() {
        // The rattle already played at the throw; the settle just gets a soft
        // landing tap.
        mediumFeedback()
    }

    func newGame(settings: GameSettings? = nil, seed: UInt64? = nil, isTimed: Bool? = nil) {
        rollTask?.cancel()
        rollTask = nil
        autoRollTask?.cancel()
        autoRollTask = nil
        stopTimer()
        gameStartTime = nil
        elapsedSeconds = 0
        pendingRollDiceForSaving = nil
        if let isTimed { self.isTimed = isTimed }
        engine.reset(settings: settings, seed: seed)
        animationDice = [0, 0, 0]
        rollingDieCount = engine.currentDieCount
        highlightedHint = []
        isRolling = false
        // The opening throw stays manual (the Roll button); only the throws after a
        // confirmed move are automatic.
        bumpRevision()
    }

    // MARK: - Save/restore (BOD-006)

    /// Adopts a previously saved engine snapshot in place of the current
    /// game. Cancels any in-flight roll/auto-roll/timer the same way
    /// `newGame` does. A pending roll (dice already drawn but not yet
    /// committed when the app was saved, e.g. backgrounded mid-animation) is
    /// committed immediately — never redrawn, and the game is never left
    /// stuck "rolling" forever.
    func restore(engine restoredEngine: GameEngine, pendingRollDice: [Int]?, gameStartTime restoredStartTime: Date?, isTimed restoredIsTimed: Bool) {
        rollTask?.cancel()
        rollTask = nil
        autoRollTask?.cancel()
        autoRollTask = nil
        stopTimer()
        pendingRollDiceForSaving = nil

        engine = restoredEngine
        isTimed = restoredIsTimed
        highlightedHint = []
        isRolling = false
        animationDice = engine.dice
        rollingDieCount = engine.currentDieCount

        if let pendingRollDice, case .waitingToRoll = engine.gameState {
            engine.roll(dice: pendingRollDice)
        }

        if isTimed, let restoredStartTime, !engine.isGameOver {
            gameStartTime = restoredStartTime
            elapsedSeconds = Int(now().timeIntervalSince(restoredStartTime))
            beginTimerLoop()
        } else {
            gameStartTime = nil
            elapsedSeconds = 0
        }
        bumpRevision()
    }

    // MARK: - Timer

    private func startTimer() {
        gameStartTime = now()
        beginTimerLoop()
    }

    /// Starts the periodic elapsed-seconds tick from whatever `gameStartTime`
    /// already is — shared by a fresh `startTimer()` and by `restore(...)`
    /// resuming a timed game's clock from its original (possibly long-past,
    /// even pre-relaunch) start time.
    private func beginTimerLoop() {
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled, let start = gameStartTime else { break }
                elapsedSeconds = Int(now().timeIntervalSince(start))
            }
        }
    }

    private func stopTimer() {
        // Recompute directly from the start time so the final result isn't stale
        // by up to one timer tick's worth of the periodic update below.
        if let start = gameStartTime {
            elapsedSeconds = Int(now().timeIntervalSince(start))
        }
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Private helpers

    private func bumpRevision() {
        revision += 1
    }

    private func lightFeedback() {
        guard feedbackOptions.hapticsEnabled else { return }
        feedback.tileSelected()
    }

    private func mediumFeedback() {
        guard feedbackOptions.hapticsEnabled else { return }
        feedback.validMoveConfirmed()
    }

    private func errorFeedback() {
        guard feedbackOptions.hapticsEnabled else { return }
        feedback.invalidAction()
    }

    private func successFeedback() {
        guard feedbackOptions.hapticsEnabled else { return }
        feedback.boardCleared()
    }

    private func soundDiceRoll() {
        guard feedbackOptions.soundsEnabled else { return }
        feedback.playDiceRoll()
    }

    private func soundTileFlip() {
        guard feedbackOptions.soundsEnabled else { return }
        feedback.playTileFlip()
    }

    private func gameOverSound(won: Bool) {
        guard feedbackOptions.soundsEnabled else { return }
        if won {
            feedback.playVictory()
        } else {
            feedback.playGameOver()
        }
    }
}

struct FeedbackOptions: Equatable {
    var hapticsEnabled = true
    var soundsEnabled = true
}
