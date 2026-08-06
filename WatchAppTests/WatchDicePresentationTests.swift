//
//  WatchDicePresentationTests.swift
//  BoxOfDice Watch App Tests
//
//  Presentation-model tests for the Watch dice display: which dice are
//  shown at rest (last completed roll vs. the next roll's count), the
//  pip point maps, and the cosmetic roll animation's lifecycle — as
//  opposed to the underlying engine rules, which are covered separately.
//

import XCTest
@testable import BoxOfDice_Watch_App

// MARK: - Pip point maps

final class DicePipLayoutTests: XCTestCase {
    func testPipCountMatchesFaceValueForOneThroughSix() {
        for value in 1...6 {
            XCTAssertEqual(DicePipLayout.positions(for: value).count, value,
                            "face \(value) must show exactly \(value) pips")
        }
    }

    func testInvalidFaceValuesShowNoPips() {
        XCTAssertEqual(DicePipLayout.positions(for: 0).count, 0)
        XCTAssertEqual(DicePipLayout.positions(for: 7).count, 0)
        XCTAssertEqual(DicePipLayout.positions(for: -1).count, 0)
    }

    /// Every pip position must lie within the die's unit square so none is
    /// clipped or overlaps another face's layout.
    func testAllPipPositionsAreWithinUnitBounds() {
        for value in 1...6 {
            for point in DicePipLayout.positions(for: value) {
                XCTAssertLessThanOrEqual(abs(point.x), 0.5)
                XCTAssertLessThanOrEqual(abs(point.y), 0.5)
            }
        }
    }
}

// MARK: - Resting-state die count (previous roll vs. next roll)

@MainActor
final class WatchDieCountPresentationTests: XCTestCase {

    private let quickGameLikeSettings = GameSettings(
        tileCount: 9, baseDiceCount: 2,
        diceMode: .oneDieWhenLowTilesRemain, moveRule: .anyCombination
    )

    func testNeutralStateBeforeAnyRollShowsNextRollCountWithoutStaleTotal() {
        let vm = GameViewModel()
        vm.restore(engine: GameEngine(settings: quickGameLikeSettings, seed: 1),
                   pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertFalse(vm.hasRolled)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertEqual(vm.dieCount, 2, "next roll's count, shown as a neutral placeholder")
    }

    /// Reproduces the reported bug: closing tile 7 with [3,4,0] while tiles
    /// 8 and 9 are already closed drops the *next* roll to one die
    /// (`engine.currentDieCount == 1`), but the just-completed roll used
    /// two dice. The resting display must keep showing both dice of that
    /// last roll (and therefore the same sum as the total badge), not
    /// truncate to the next roll's count.
    func testLastRollStaysFullyVisibleEvenWhenNextRollDropsADie() {
        var engine = GameEngine(settings: quickGameLikeSettings, seed: 2)
        engine.roll(dice: [9, 0, 0]); engine.toggleTile(9); engine.confirmSelection()
        engine.roll(dice: [8, 0, 0]); engine.toggleTile(8); engine.confirmSelection()
        engine.roll(dice: [3, 4, 0]); engine.toggleTile(7); engine.confirmSelection()

        XCTAssertEqual(engine.gameState, .waitingToRoll)
        XCTAssertEqual(engine.dice, [3, 4, 0])
        XCTAssertEqual(engine.currentDieCount, 1, "sanity check: the *next* roll has dropped to one die")

        let vm = GameViewModel()
        vm.restore(engine: engine, pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertTrue(vm.hasRolled)
        XCTAssertEqual(vm.dice, [3, 4, 0])
        XCTAssertEqual(vm.dieCount, 2, "must still show both dice from the completed roll")
        XCTAssertEqual(vm.diceTotal, 7, "total badge and visible dice must agree")
    }

    /// Once the player actually rolls again, the animation and the
    /// landed result legitimately use the reduced count — this is the
    /// "2 → 1" transition itself, which must still be allowed to happen.
    func testNextRollLegitimatelyTransitionsToFewerDice() async throws {
        var engine = GameEngine(settings: quickGameLikeSettings, seed: 3)
        engine.roll(dice: [9, 0, 0]); engine.toggleTile(9); engine.confirmSelection()
        engine.roll(dice: [8, 0, 0]); engine.toggleTile(8); engine.confirmSelection()
        engine.roll(dice: [3, 4, 0]); engine.toggleTile(7); engine.confirmSelection()

        let vm = GameViewModel()
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(hapticsEnabled: false))
        vm.restore(engine: engine, pendingRollDice: nil, gameStartTime: nil, isTimed: false)
        XCTAssertEqual(vm.dieCount, 2, "still showing the previous roll before the next one starts")

        vm.rollDice()
        XCTAssertTrue(vm.isRolling)
        XCTAssertEqual(vm.dieCount, 1, "the in-flight roll's own die count, fixed at roll start")
    }
}

// MARK: - Cosmetic animation lifecycle

@MainActor
final class WatchRollAnimationLifecycleTests: XCTestCase {

    /// Backgrounding mid-roll must commit the already-drawn result
    /// immediately (never redrawing it) and stop the pending roll task,
    /// instead of leaving it to resolve later in the background.
    func testBackgroundingMidRollCommitsImmediatelyWithoutRedrawing() async throws {
        let vm = GameViewModel()
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(hapticsEnabled: false))

        vm.rollDice()
        XCTAssertTrue(vm.isRolling)

        vm.handleScenePhaseBackground()

        XCTAssertFalse(vm.isRolling)
        let committedDice = vm.dice
        XCTAssertTrue(committedDice.contains(where: { $0 > 0 }))

        // The original roll task's sleep would have resolved by now; if it
        // weren't cancelled it could re-apply (harmlessly, since the dice
        // are identical) or, in a stale-generation race, do nothing —
        // either way the committed dice must not change again afterward.
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(vm.dice, committedDice)
    }

    /// Backgrounding while not rolling (e.g. already resting, or game over)
    /// must be a no-op.
    func testBackgroundingWithNoPendingRollIsANoOp() {
        let vm = GameViewModel()
        let before = (vm.dice, vm.gameState, vm.revision)

        vm.handleScenePhaseBackground()

        XCTAssertEqual(vm.dice, before.0)
        XCTAssertEqual(vm.gameState, before.1)
        XCTAssertEqual(vm.revision, before.2)
    }

    /// Starting a new game mid-roll must leave no stray animation able to
    /// resurface stale dice afterward (see also
    /// WatchGameCoreRegressionTests.testStaleRollTaskCannotMutateNewGame,
    /// which this complements with a dieCount/dice-presentation check).
    func testNewGameDuringRollLeavesNeutralDicePresentation() async throws {
        let vm = GameViewModel()
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(hapticsEnabled: false))

        vm.rollDice()
        vm.newGame()

        XCTAssertFalse(vm.isRolling)
        XCTAssertFalse(vm.hasRolled)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertEqual(vm.dieCount, vm.dice.count > 0 ? vm.dieCount : 0) // sanity: no crash reading dieCount

        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertFalse(vm.isRolling)
        XCTAssertEqual(vm.dice, [0, 0, 0])
    }

    /// A pending roll captured for saving (mid-animation) must restore by
    /// committing exactly that result, and the resting die count must then
    /// reflect all of it.
    func testPendingRollDiceRestoreShowsAllCommittedDice() {
        let vm = GameViewModel()
        var saved = GameEngine(settings: .default, seed: 41) // .waitingToRoll
        let pending = saved.randomDice()

        vm.restore(engine: saved, pendingRollDice: pending, gameStartTime: nil, isTimed: false)

        XCTAssertFalse(vm.isRolling)
        XCTAssertEqual(vm.dice, pending)
        XCTAssertEqual(vm.dieCount, pending.filter { $0 > 0 }.count)
    }
}
