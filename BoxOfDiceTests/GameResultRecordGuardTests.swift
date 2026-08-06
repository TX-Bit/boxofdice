//
//  GameResultRecordGuardTests.swift
//  BoxOfDiceTests
//
//  NOTE: This file is not yet wired into an Xcode test target.
//  In Xcode: File > New > Target… > Unit Testing Bundle (attach to
//  "BoxOfDice"), then add this target.
//
//  R3 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md: the previous
//  double-recording test (in GameStatisticsRecorderTests.swift) called
//  GameStatisticsRecorder twice directly and never touched the guard that
//  actually prevents double recording in the app (which lived as a raw
//  `@State private var hasRecordedCurrentGameResult` inside ContentView).
//  Removing that guard wouldn't have failed that test. GameResultRecordGuard
//  is that same guard, pulled out into its own testable type (ContentView
//  and WatchContentView now hold one instead of a raw Bool) — this tests it
//  directly, so weakening or removing the guard's logic fails here.

import XCTest
@testable import BoxOfDice

final class GameResultRecordGuardTests: XCTestCase {

    func testRecordsOnlyOnceUntilReset() {
        var guardValue = GameResultRecordGuard()

        XCTAssertTrue(guardValue.recordIfNeeded(), "the first call for a finished game must record")
        XCTAssertFalse(guardValue.recordIfNeeded(), "a second call for the same game must not record again")
        XCTAssertFalse(guardValue.recordIfNeeded(), "nor a third, or any further call before reset")
    }

    func testResetAllowsRecordingAgainForTheNextGame() {
        var guardValue = GameResultRecordGuard()

        XCTAssertTrue(guardValue.recordIfNeeded())
        XCTAssertFalse(guardValue.recordIfNeeded())

        guardValue.reset()

        XCTAssertTrue(guardValue.recordIfNeeded(), "a new game must be able to record its own result")
        XCTAssertFalse(guardValue.recordIfNeeded())
    }

    /// Mirrors two identical "the game just ended" events arriving for the
    /// same game (the scenario the requirements call out), by driving the
    /// guard the same way ContentView.handleGameOver does.
    func testTwoIdenticalGameOverEventsForTheSameGameRecordOnlyOnce() {
        var guardValue = GameResultRecordGuard()
        var recordedCount = 0

        func handleGameOverEvent() {
            guard guardValue.recordIfNeeded() else { return }
            recordedCount += 1
        }

        handleGameOverEvent()
        handleGameOverEvent() // the same finished game "ending" a second time
        XCTAssertEqual(recordedCount, 1)

        guardValue.reset() // a new game begins
        handleGameOverEvent()
        XCTAssertEqual(recordedCount, 2, "recording must work again after a new game starts")
    }
}
