//
//  WatchGameRestoreTests.swift
//  BoxOfDice Watch App Tests
//
//  Wired into the "BoxOfDice Watch AppTests" target (see project.pbxproj /
//  R1 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//
//  BOD-006: exercises the Watch GameViewModel.restore(...) directly — see
//  BoxOfDiceTests/GameRestoreTests.swift for the iOS counterpart and the
//  full rationale for each scenario.

import XCTest
@testable import BoxOfDice_Watch_App

@MainActor
final class WatchGameRestoreTests: XCTestCase {

    func testRestoreBeforeAnyRoll() {
        let vm = GameViewModel()
        let saved = GameEngine(settings: .default, seed: 31)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertEqual(vm.gameState, .waitingToRoll)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertFalse(vm.isRolling)
        XCTAssertTrue(vm.canRoll)
    }

    func testRestoreDuringTileSelection() {
        let vm = GameViewModel()
        var saved = GameEngine(settings: .default, seed: 32)
        saved.roll(dice: [3, 4, 0])
        saved.toggleTile(3)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertEqual(vm.gameState, .selecting)
        XCTAssertEqual(vm.selectedTiles, [3])
        XCTAssertEqual(vm.dice, [3, 4, 0])
        XCTAssertFalse(vm.isRolling)
    }

    /// The dice were already drawn (consuming the seeded generator) before
    /// the roll animation started; restoring must commit that exact result
    /// immediately — never leave the game "rolling" forever, and never draw
    /// a second, different result in its place.
    func testRestoreMidRollCommitsThePendingDiceWithoutRedrawingOrLocking() {
        let vm = GameViewModel()
        var saved = GameEngine(settings: .default, seed: 33) // still .waitingToRoll
        let pending = saved.randomDice()

        vm.restore(engine: saved, pendingRollDice: pending, gameStartTime: nil, isTimed: false)

        XCTAssertFalse(vm.isRolling, "must not be left stuck rolling")
        XCTAssertEqual(vm.dice, pending, "must commit the already-drawn result, not redraw")
        let isSelectingOrOver = vm.gameState == .selecting || {
            if case .gameOver = vm.gameState { return true }
            return false
        }()
        XCTAssertTrue(isSelectingOrOver, "must have moved forward from waitingToRoll")
    }

    /// Background/quit time must still count toward a timed result: the
    /// start time is restored as an absolute wall-clock timestamp, so
    /// elapsed seconds is computed against real time, not reset or paused.
    func testRestoreTimedGameCountsTimeThatPassedWhileGone() {
        let vm = GameViewModel()
        let saved = GameEngine(settings: .default, seed: 34)
        let start = Date(timeIntervalSinceNow: -50)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: start, isTimed: true)

        XCTAssertGreaterThanOrEqual(vm.elapsedSeconds, 50)
    }

    func testRestoringAFinishedTimedGameDoesNotResumeItsClock() {
        let vm = GameViewModel()
        var saved = GameEngine(settings: GameSettings(tileCount: 1, baseDiceCount: 1, diceMode: .alwaysTwoDice, moveRule: .anyCombination), seed: 35)
        saved.roll(dice: [1, 0, 0])
        saved.toggleTile(1)
        saved.confirmSelection()
        XCTAssertTrue(saved.isGameOver)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: Date(timeIntervalSinceNow: -999), isTimed: true)

        XCTAssertEqual(vm.elapsedSeconds, 0)
    }
}
