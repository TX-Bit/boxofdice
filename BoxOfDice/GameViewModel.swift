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
    @Published private var animationDice: (Int, Int) = (0, 0)
    @Published private(set) var highlightedHint: Set<Int> = []

    private let feedback: GameFeedbackProviding
    private var rollTask: Task<Void, Never>?
    private var confirmBehavior: ConfirmBehavior = .manual
    private var diceAnimationSpeed: DiceAnimationSpeed = .normal
    private var feedbackOptions = FeedbackOptions()

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

    private var rollingDieCount = 2

    // During rolling, display the animation frames; afterwards show the real dice.
    var dice: (Int, Int) { isRolling ? animationDice : engine.dice }
    var diceTotal: Int { dice.0 + dice.1 }
    var hasRolled: Bool { isRolling || engine.hasRolled }

    // MARK: - Actions

    func configure(confirmBehavior: ConfirmBehavior, diceAnimationSpeed: DiceAnimationSpeed, feedbackOptions: FeedbackOptions) {
        self.confirmBehavior = confirmBehavior
        self.diceAnimationSpeed = diceAnimationSpeed
        self.feedbackOptions = feedbackOptions
    }

    func rollDice() {
        guard case .waitingToRoll = engine.gameState, !isRolling else {
            errorFeedback()
            return
        }

        highlightedHint = []
        rollTask?.cancel()
        isRolling = true
        rollingDieCount = engine.currentDieCount
        soundDiceRoll()

        let finalDice = engine.randomDice()
        animationDice = nextAnimationDice(avoiding: engine.dice, dieCount: rollingDieCount)

        rollTask = Task { @MainActor in
            let frameDelays = diceAnimationSpeed.frameDelays

            for delay in frameDelays {
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: Double(delay) / 1_000)) {
                    animationDice = nextAnimationDice(avoiding: animationDice, dieCount: rollingDieCount)
                }
                try? await Task.sleep(nanoseconds: delay * 1_000_000)
            }

            guard !Task.isCancelled else { return }
            withAnimation(.interpolatingSpring(stiffness: 260, damping: 18)) {
                animationDice = finalDice
            }
            try? await Task.sleep(nanoseconds: 170_000_000)

            guard !Task.isCancelled else { return }
            engine.roll(dice: finalDice)
            if case .gameOver(let won) = engine.gameState, won {
                successFeedback()
            } else if case .gameOver = engine.gameState {
                errorFeedback()
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

        if confirmBehavior == .automatic, engine.canConfirm {
            confirmSelection()
        }
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

        if case .gameOver(let won) = engine.gameState, won {
            successFeedback()
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

    func newGame(settings: GameSettings? = nil, seed: UInt64? = nil) {
        rollTask?.cancel()
        rollTask = nil
        engine.reset(settings: settings, seed: seed)
        animationDice = (0, 0)
        rollingDieCount = engine.currentDieCount
        highlightedHint = []
        isRolling = false
    }

    private func nextAnimationDice(avoiding current: (Int, Int), dieCount: Int) -> (Int, Int) {
        var next = randomDice(dieCount: dieCount)
        while next == current {
            next = randomDice(dieCount: dieCount)
        }
        return next
    }

    private func randomDice(dieCount: Int) -> (Int, Int) {
        if dieCount == 1 {
            return (Int.random(in: 1...6), 0)
        }
        return (Int.random(in: 1...6), Int.random(in: 1...6))
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
}

struct FeedbackOptions: Equatable {
    var hapticsEnabled = true
    var soundsEnabled = true
}
