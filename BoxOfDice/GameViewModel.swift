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

    private let feedback: GameFeedbackProviding
    private var rollTask: Task<Void, Never>?
    private var autoRollTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var gameStartTime: Date?
    private var diceAnimationSpeed: DiceAnimationSpeed = .normal
    private var feedbackOptions = FeedbackOptions()
    private var isTimed: Bool = false

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
    var dieCount: Int { isRolling ? rollingDieCount : engine.currentDieCount }
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

    // MARK: - Actions

    func configure(diceAnimationSpeed: DiceAnimationSpeed, feedbackOptions: FeedbackOptions, isTimed: Bool = false) {
        self.diceAnimationSpeed = diceAnimationSpeed
        self.feedbackOptions = feedbackOptions
        self.isTimed = isTimed
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

        rollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 820_000_000)
            guard !Task.isCancelled else { return }
            engine.roll(dice: finalDice)
            if case .gameOver(let won) = engine.gameState {
                if won { successFeedback() } else { errorFeedback() }
                gameOverSound(won: won)
                stopTimer()
            }
            isRolling = false
            rollTask = nil
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
        if let isTimed { self.isTimed = isTimed }
        engine.reset(settings: settings, seed: seed)
        animationDice = [0, 0, 0]
        rollingDieCount = engine.currentDieCount
        highlightedHint = []
        isRolling = false
        // The opening throw stays manual (the Roll button); only the throws after a
        // confirmed move are automatic.
    }

    // MARK: - Timer

    private func startTimer() {
        gameStartTime = Date()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled, let start = gameStartTime else { break }
                elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Private helpers

    private func nextAnimationDice(avoiding current: [Int], dieCount: Int) -> [Int] {
        var next = randomDiceValues(dieCount: dieCount)
        while next == current {
            next = randomDiceValues(dieCount: dieCount)
        }
        return next
    }

    private func randomDiceValues(dieCount: Int) -> [Int] {
        var result = [0, 0, 0]
        for i in 0..<dieCount {
            result[i] = Int.random(in: 1...6)
        }
        return result
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
