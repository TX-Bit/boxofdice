//
//  GameViewModelTimedAnimationTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj / R1 in
//  docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//

import XCTest
@testable import BoxOfDice

@MainActor
final class GameViewModelTimedAnimationTests: XCTestCase {

    // MARK: - BOD-002: timed-mode animation fairness

    /// Timed modes (Speed Run, Big Box Speed) must always animate at the
    /// standard "normal" speed, ignoring the user's animation-speed setting
    /// entirely — including a setting change made mid-timed-game.
    func testEffectiveAnimationSpeedIgnoresSettingWhenTimed() {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: false)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .long, "untimed modes must honour the user's setting")

        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: true)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .normal, "timed modes must not use the user's setting")

        // Changing the setting mid-timed-game must not change the effective speed.
        vm.configure(diceAnimationSpeed: .short, feedbackOptions: FeedbackOptions(), isTimed: true)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .normal, "switching the setting mid-game must not grant a time advantage")
    }

    /// R4 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md: a sub-second game with
    /// a 1.0s tolerance can't distinguish "recomputed at stop" from "stale
    /// periodic tick", since both round to 0. This version uses the
    /// injectable `now` clock (added for BOD-006's restore-time-continuity
    /// needs) to make the sequence deterministic instead of racing real
    /// time: freeze the clock, let a real periodic tick fire and record a
    /// "stale" 0, then jump the clock forward and, in the very next
    /// (synchronous, non-`await`ing) statement, end the game. Nothing else
    /// can run on the main actor between the jump and the end-of-game call,
    /// so there is no timing race — if `stopTimer()` ever regressed to
    /// trusting the last periodic tick instead of recomputing, this fails
    /// every time, not occasionally.
    func testElapsedSecondsFinalizedFromClockNotFromAStalePeriodicTick() async throws {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        let t0 = Date()
        vm.now = { t0 }

        // A 1-tile board (tile "1") whose die has already been rolled to 1
        // and pre-selected: confirmSelection() below will close the only
        // tile and win immediately, entirely synchronously (no animation
        // delay to race against, unlike rollDice()).
        var saved = GameEngine(settings: GameSettings(tileCount: 1, baseDiceCount: 1, diceMode: .alwaysTwoDice, moveRule: .anyCombination))
        saved.roll(dice: [1, 0, 0])
        saved.toggleTile(1)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: t0, isTimed: true)
        XCTAssertEqual(vm.gameState, .selecting)

        // Let a real periodic tick land while the clock is still frozen at
        // t0, so it records the "stale" value a regression would leave in
        // place (250ms comfortably covers watchOS's slower tick; iOS ticks
        // every 100ms).
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(vm.elapsedSeconds, 0, "sanity check: a stale tick was in fact recorded")

        // Jump the clock and end the game in the same synchronous step —
        // no `await` between them, so no periodic tick can interleave.
        vm.now = { t0.addingTimeInterval(1.6) }
        vm.confirmSelection()

        XCTAssertEqual(vm.gameState, .gameOver(won: true))
        XCTAssertEqual(vm.elapsedSeconds, 1, "must reflect the jumped clock (Int(1.6) == 1), not the stale tick's 0")
    }

    /// The visible dice animation and the interaction lock must share the same
    /// effective duration: both derive from `effectiveDiceAnimationSpeed`, so a
    /// caller (the view) that reads `viewModel.effectiveDiceAnimationSpeed` for
    /// its animation timing can never drift from the roll lock's duration.
    func testVisibleAnimationDurationMatchesInteractionLockDuration() {
        let vm = GameViewModel(feedback: NoOpGameFeedback.shared)
        vm.configure(diceAnimationSpeed: .long, feedbackOptions: FeedbackOptions(), isTimed: true)

        let visibleDuration = vm.effectiveDiceAnimationSpeed.tumbleDuration
        let lockDurationNanoseconds = vm.effectiveDiceAnimationSpeed.totalRollDurationNanoseconds(dieCount: 2)

        // The lock duration includes the tumble plus a small fixed stagger/settle
        // margin (see totalRollDurationNanoseconds); it must never be shorter
        // than the visible tumble itself, and both must come from the same speed.
        XCTAssertGreaterThanOrEqual(Double(lockDurationNanoseconds) / 1_000_000_000, visibleDuration)
        XCTAssertEqual(vm.effectiveDiceAnimationSpeed, .normal)
    }
}
