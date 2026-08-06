//
//  GameRestoreTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj / R1 in
//  docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//
//  BOD-006: exercises GameViewModel.restore(...) directly — the same method
//  ContentView calls after GameSaveStore.load() — covering the required
//  scenarios: before any roll, during tile selection, mid-roll (a dice
//  result already drawn but not yet committed when saved), and a timed
//  game whose clock must keep counting through the time it was gone.
//
//  Local Pass & Play player/score restoration lives in ContentView (the
//  view owns that state, not the view model) and isn't covered here — it
//  has no SwiftUI-independent seam to test against without a UI-testing
//  dependency, which this project deliberately doesn't add. It's covered
//  instead at the data level by GameSaveStoreTests (the saved fields
//  round-trip correctly); ContentView.restoreSavedGameIfAny() assigns them
//  to @State one line at a time with no further logic to go wrong.

import XCTest
@testable import BoxOfDice

@MainActor
final class GameRestoreTests: XCTestCase {

    private func makeViewModel() -> GameViewModel {
        GameViewModel(feedback: NoOpGameFeedback.shared)
    }

    // MARK: - Restore before any roll

    func testRestoreBeforeAnyRoll() {
        let vm = makeViewModel()
        let saved = GameEngine(settings: .default, seed: 21)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertEqual(vm.gameState, .waitingToRoll)
        XCTAssertEqual(vm.dice, [0, 0, 0])
        XCTAssertFalse(vm.isRolling)
        XCTAssertTrue(vm.canRoll)
    }

    // MARK: - Restore during tile selection

    func testRestoreDuringTileSelection() {
        let vm = makeViewModel()
        var saved = GameEngine(settings: .default, seed: 22)
        saved.roll(dice: [3, 4, 0])
        saved.toggleTile(3)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: nil, isTimed: false)

        XCTAssertEqual(vm.gameState, .selecting)
        XCTAssertEqual(vm.selectedTiles, [3])
        XCTAssertEqual(vm.dice, [3, 4, 0])
        XCTAssertFalse(vm.isRolling)
    }

    // MARK: - Restore mid-roll (dice already drawn, not yet committed)

    /// This is the scenario the requirements call out specifically: the app
    /// was backgrounded while a roll's animation was still playing. The
    /// dice were already drawn (consuming the random generator) before the
    /// animation started; restoring must commit that exact result — never
    /// leave the game stuck "rolling", and never draw a second, different
    /// result in its place.
    func testRestoreMidRollCommitsThePendingDiceWithoutRedrawingOrLocking() {
        let vm = makeViewModel()
        var saved = GameEngine(settings: .default, seed: 23) // still .waitingToRoll
        let pending = saved.randomDice() // mirrors rollDice() having already drawn dice pre-animation

        vm.restore(engine: saved, pendingRollDice: pending, gameStartTime: nil, isTimed: false)

        XCTAssertFalse(vm.isRolling, "must not be left stuck rolling")
        XCTAssertEqual(vm.dice, pending, "must commit the already-drawn result, not redraw")
        XCTAssertTrue(vm.gameState == .selecting || vm.gameState.isGameOver, "must have moved forward from waitingToRoll")
    }

    // MARK: - Restore a timed game

    /// Background/quit time must still count: the start time is restored
    /// as-is (an absolute wall-clock timestamp), so elapsed seconds is
    /// computed against real time, not reset or paused.
    func testRestoreTimedGameCountsTimeThatPassedWhileGone() {
        let vm = makeViewModel()
        let saved = GameEngine(settings: .default, seed: 24)
        let start = Date(timeIntervalSinceNow: -45) // pretend 45s passed while backgrounded/quit

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: start, isTimed: true)

        XCTAssertGreaterThanOrEqual(vm.elapsedSeconds, 45)
    }

    /// A finished game must never be restored as if it were still in
    /// progress: no timer should (re)start for it, since there's nothing
    /// left to play and its result was already final when it was saved.
    /// (ContentView's persistCurrentGame() never actually saves a finished
    /// game in the first place — see GameSaveStoreTests — this checks
    /// restore()'s own defensiveness if it were ever called with one.)
    func testRestoringAFinishedTimedGameDoesNotResumeItsClock() {
        let vm = makeViewModel()
        var saved = GameEngine(settings: GameSettings(tileCount: 1, baseDiceCount: 1, diceMode: .alwaysTwoDice, moveRule: .anyCombination), seed: 25)
        saved.roll(dice: [1, 0, 0])
        saved.toggleTile(1)
        saved.confirmSelection()
        XCTAssertTrue(saved.isGameOver)

        vm.restore(engine: saved, pendingRollDice: nil, gameStartTime: Date(timeIntervalSinceNow: -999), isTimed: true)

        XCTAssertEqual(vm.elapsedSeconds, 0)
    }
}

private extension GameState {
    var isGameOver: Bool {
        if case .gameOver = self { return true }
        return false
    }
}
