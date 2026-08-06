//
//  WatchGameCoreRegressionTests.swift
//  BoxOfDice Watch App Tests
//
//  Wired into the "BoxOfDice Watch AppTests" target (see project.pbxproj /
//  R1 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//

import XCTest
@testable import BoxOfDice_Watch_App

@MainActor
final class WatchGameCoreRegressionTests: XCTestCase {

    /// A stale roll task must never mutate a game that has since been restarted.
    func testStaleRollTaskCannotMutateNewGame() async throws {
        let vm = GameViewModel()
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(hapticsEnabled: false))

        vm.rollDice()
        XCTAssertTrue(vm.isRolling)

        // Start a new game mid-animation, before the old roll task's sleep resolves.
        vm.newGame()

        // Let the stale roll task's Task.sleep resolve.
        try await Task.sleep(nanoseconds: 1_200_000_000)

        XCTAssertEqual(vm.gameState, .waitingToRoll)
        XCTAssertFalse(vm.isRolling)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertTrue(vm.tiles.allSatisfy(\.isOpen))
        XCTAssertEqual(vm.elapsedSeconds, 0)
        XCTAssertTrue(vm.moveHistory.isEmpty)
    }

    /// The timer from a previous (timed) game must not keep advancing elapsedSeconds after restart.
    func testStaleTimerCannotAdvanceNewGame() async throws {
        let vm = GameViewModel()
        vm.configure(diceAnimationSpeed: .short, feedbackOptions: FeedbackOptions(hapticsEnabled: false), isTimed: true)

        vm.rollDice() // starts the timer since isTimed == true
        try await Task.sleep(nanoseconds: 300_000_000) // let timer tick at least once

        vm.newGame() // restart while the old timer task is still looping

        try await Task.sleep(nanoseconds: 600_000_000)

        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    /// Rapid repeated newGame() calls must leave the game in a consistent, fresh state.
    func testRapidRepeatedNewGameCallsSettleCleanly() async throws {
        let vm = GameViewModel()
        vm.configure(diceAnimationSpeed: .normal, feedbackOptions: FeedbackOptions(hapticsEnabled: false))

        for _ in 0..<20 {
            vm.rollDice()
            vm.newGame()
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertEqual(vm.gameState, .waitingToRoll)
        XCTAssertFalse(vm.isRolling)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertTrue(vm.tiles.allSatisfy(\.isOpen))
        XCTAssertEqual(vm.elapsedSeconds, 0)
        XCTAssertTrue(vm.moveHistory.isEmpty)
    }

    // MARK: - BOD-002: timed-mode animation fairness

    /// Timed modes must always animate at the standard "normal" speed, ignoring
    /// the user's animation-speed setting entirely (including a mid-game change).
    func testEffectiveAnimationSpeedIgnoresSettingWhenTimed() {
        let vm = GameViewModel()

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(hapticsEnabled: false), isTimed: false)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .long, "untimed modes must honour the user's setting")

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(hapticsEnabled: false), isTimed: true)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .normal, "timed modes must not use the user's setting")

        // Changing the setting mid-timed-game must not change the effective speed.
        vm.configure(diceAnimationSpeed: .short, feedbackOptions: FeedbackOptions(hapticsEnabled: false), isTimed: true)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .normal, "switching the setting mid-game must not grant a time advantage")
    }

    /// R4 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md: a sub-second game with
    /// a 1.0s tolerance can't distinguish "recomputed at stop" from "stale
    /// periodic tick", since both round to 0. This version uses the
    /// injectable `now` clock (added for BOD-006's restore-time-continuity
    /// needs) to make the sequence deterministic instead of racing real
    /// time — see the identical iOS test in
    /// BoxOfDiceTests/GameViewModelTimedAnimationTests.swift for the full
    /// rationale: freeze the clock, let a real periodic tick record a
    /// "stale" 0, then jump the clock and end the game in the very next,
    /// non-`await`ing statement, so nothing else can run in between.
    func testElapsedSecondsFinalizedFromClockNotFromAStalePeriodicTick() async throws {
        let vm = GameViewModel()
        let t0 = Date()
        vm.now = { t0 }

        var saved = GameEngine(settings: GameSettings(tileCount: 1, baseDiceCount: 1, diceMode: .alwaysTwoDice, moveRule: .anyCombination))
        saved.roll(dice: [1, 0, 0])
        saved.toggleTile(1)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: t0, isTimed: true)
        XCTAssertEqual(vm.gameState, .selecting)

        // Let a real periodic tick land while the clock is frozen at t0
        // (watchOS ticks every 250ms; 300ms comfortably covers one).
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(vm.elapsedSeconds, 0, "sanity check: a stale tick was in fact recorded")

        vm.now = { t0.addingTimeInterval(1.6) }
        vm.confirmSelection()

        XCTAssertEqual(vm.gameState, .gameOver(won: true))
        XCTAssertEqual(vm.elapsedSeconds, 1, "must reflect the jumped clock (Int(1.6) == 1), not the stale tick's 0")
    }
}
