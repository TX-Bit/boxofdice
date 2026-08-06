//
//  DiceRollAndTileInteractionTests.swift
//  BoxOfDiceTests
//
//  Presentation-layer regression tests for the roll/close polish pass:
//  GameViewModel.dieCount (must show the last completed roll's actual dice,
//  not the next roll's count), the background-commit safeguard for a roll
//  in flight, and Reduce Motion shortening the roll's interaction lock.
//  Engine-level rules (allowed combinations, scoring) are covered elsewhere
//  (GameEngineTests, QuickGameTests) and are untouched by this pass.
//

import XCTest
@testable import BoxOfDice

@MainActor
final class DiceRollAndTileInteractionTests: XCTestCase {

    private let quickGameSettings = GameSettings(
        tileCount: 9, baseDiceCount: 2,
        diceMode: .oneDieWhenLowTilesRemain, moveRule: .anyCombination
    )

    // MARK: - dieCount: last roll must stay fully visible

    func testNeutralStateBeforeAnyRollShowsNextRollCount() {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        vm.restore(engine: GameEngine(settings: quickGameSettings, seed: 1),
                   pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertFalse(vm.hasRolled)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertEqual(vm.dieCount, 2)
    }

    /// Reproduces the reported bug: closing tile 7 with [3,4,0] while tiles
    /// 8 and 9 are already closed drops the *next* roll to one die, but the
    /// just-completed roll used two. The resting display must keep both
    /// dice of that last roll visible (matching the dice-total text), not
    /// truncate to the next roll's count.
    func testLastRollStaysFullyVisibleEvenWhenNextRollDropsADie() {
        var engine = GameEngine(settings: quickGameSettings, seed: 2)
        engine.roll(dice: [9, 0, 0]); engine.toggleTile(9); engine.confirmSelection()
        engine.roll(dice: [8, 0, 0]); engine.toggleTile(8); engine.confirmSelection()
        engine.roll(dice: [3, 4, 0]); engine.toggleTile(7); engine.confirmSelection()

        XCTAssertEqual(engine.currentDieCount, 1, "sanity check: the *next* roll has dropped to one die")

        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        vm.restore(engine: engine, pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertTrue(vm.hasRolled)
        XCTAssertEqual(vm.dice, [3, 4, 0])
        XCTAssertEqual(vm.dieCount, 2, "must still show both dice from the completed roll")
        XCTAssertEqual(vm.diceTotal, 7, "total and visible dice must agree")
    }

    func testNextRollLegitimatelyTransitionsToFewerDice() {
        var engine = GameEngine(settings: quickGameSettings, seed: 3)
        engine.roll(dice: [9, 0, 0]); engine.toggleTile(9); engine.confirmSelection()
        engine.roll(dice: [8, 0, 0]); engine.toggleTile(8); engine.confirmSelection()
        engine.roll(dice: [3, 4, 0]); engine.toggleTile(7); engine.confirmSelection()

        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions())
        vm.restore(engine: engine, pendingRollDice: nil, gameStartTime: nil, isTimed: false)
        XCTAssertEqual(vm.dieCount, 2)

        vm.rollDice()
        XCTAssertTrue(vm.isRolling)
        XCTAssertEqual(vm.dieCount, 1, "the in-flight roll's own die count, fixed at roll start")
    }

    // MARK: - Backgrounding mid-roll

    func testBackgroundingMidRollCommitsImmediatelyWithoutRedrawing() async throws {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions())

        vm.rollDice()
        XCTAssertTrue(vm.isRolling)

        vm.handleScenePhaseBackground()

        XCTAssertFalse(vm.isRolling)
        let committedDice = vm.dice
        XCTAssertTrue(committedDice.contains(where: { $0 > 0 }))

        // The original roll task's sleep would have resolved by now; the
        // committed dice must not change again afterward (no redraw, no
        // stray second commit).
        try await Task.sleep(nanoseconds: 1_500_000_000)
        XCTAssertEqual(vm.dice, committedDice)
    }

    func testBackgroundingWithNoPendingRollIsANoOp() {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        let before = (vm.dice, vm.gameState)

        vm.handleScenePhaseBackground()

        XCTAssertEqual(vm.dice, before.0)
        XCTAssertEqual(vm.gameState, before.1)
    }

    // MARK: - Reduce Motion shortens the roll lock, never lengthens it

    func testReduceMotionShortensRollDurationAndNeverLengthensIt() {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: false, reduceMotion: false)
        let normalDuration = vm.effectiveRollDurationNanoseconds

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: false, reduceMotion: true)
        let reducedDuration = vm.effectiveRollDurationNanoseconds

        XCTAssertLessThan(reducedDuration, normalDuration, "Reduce Motion must shorten the lock, not just change its look")
    }

    /// Reduce Motion must not become a way to shave time off a timed mode's
    /// clock beyond what it already does for every player equally — it's
    /// still strictly a *shortening*, same as the untimed case, not an
    /// exploit specific to timed games.
    func testReduceMotionShortensEvenTimedModeRollLock() {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: true, reduceMotion: true)
        let reducedTimedDuration = vm.effectiveRollDurationNanoseconds

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: true, reduceMotion: false)
        let normalTimedDuration = vm.effectiveRollDurationNanoseconds

        XCTAssertLessThan(reducedTimedDuration, normalTimedDuration)
    }

    // MARK: - Wrong sums are never confirmable (engine-level guard the UI relies on)

    func testWrongSumCanNeverBeConfirmed() {
        var engine = GameEngine(settings: .default, seed: 4)
        engine.roll(dice: [3, 4, 0]) // target 7
        engine.toggleTile(3) // selection total 3, not 7
        XCTAssertFalse(engine.canConfirm)
        engine.confirmSelection() // must be a no-op
        XCTAssertEqual(engine.gameState, .selecting)
        XCTAssertTrue(engine.tiles.first(where: { $0.id == 3 })!.isOpen, "confirmSelection() must not have closed anything")
    }
}
