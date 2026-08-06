//
//  GameStatisticsRecorderTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj / R1 in
//  docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//

import XCTest
@testable import BoxOfDice

final class GameStatisticsRecorderTests: XCTestCase {

    /// A fresh, isolated UserDefaults store per test, so tests never touch
    /// the real app's saved statistics and never see another test's data.
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "GameStatisticsRecorderTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Old saved data (pre-BOD-005) is left alone

    /// Simulates a store that already has old-style combined statistics
    /// (as if saved by the app before this update). Recording a new game
    /// must not touch those old fields at all — they stay exactly as they
    /// were, satisfying "don't destroy old statistics" without pretending
    /// to know how much of the old combined total came from which mode.
    func testOldCombinedStatisticsAreLeftUntouched() {
        defaults.set(7, forKey: StatisticsStorageKey.gamesPlayed)
        defaults.set(123, forKey: StatisticsStorageKey.totalScore)
        defaults.set(11, forKey: StatisticsStorageKey.bestScore)
        defaults.set(80, forKey: StatisticsStorageKey.winningScoreTotal)
        defaults.set(43, forKey: StatisticsStorageKey.losingScoreTotal)

        GameStatisticsRecorder.recordCompletedGame(
            mode: .classic, won: true, baseScore: 5, elapsedSeconds: 0,
            turnCount: 4, remainingOpenTiles: [], defaults: defaults
        )

        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.totalScore), 123, "old combined total must be untouched")
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScore), 11, "old combined best must be untouched")
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.winningScoreTotal), 80)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.losingScoreTotal), 43)
        // gamesPlayed is a "sensible combined count" and does still advance.
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.gamesPlayed), 8)
    }

    // MARK: - First new result for a mode

    /// The very first game recorded for a mode (fresh store, or a store with
    /// only old combined data) must set that mode's best and average, not
    /// leave them at a stale zero.
    func testFirstResultForAModeSetsBestAndAverage() {
        GameStatisticsRecorder.recordCompletedGame(
            mode: .speedRun, won: false, baseScore: 9, elapsedSeconds: 12,
            turnCount: 3, remainingOpenTiles: [4, 8], defaults: defaults
        )

        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScoreSpeedRun), 21) // 9 + 12
        XCTAssertNotNil(defaults.object(forKey: StatisticsStorageKey.bestScoreSpeedRun), "must be recorded, not left absent")
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreTotalSpeedRun), 21)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreCountSpeedRun), 1)
    }

    // MARK: - A zero-score record

    /// A perfect-clear (score 0) game must be recorded as a real best of 0,
    /// distinguishable from "no games recorded yet" — the storage-key
    /// presence check (not just "score != 0") is what makes that possible.
    func testZeroScoreIsRecordedAsARealBest() {
        GameStatisticsRecorder.recordCompletedGame(
            mode: .classic, won: true, baseScore: 0, elapsedSeconds: 0,
            turnCount: 5, remainingOpenTiles: [], defaults: defaults
        )

        XCTAssertNotNil(defaults.object(forKey: StatisticsStorageKey.bestScoreClassic))
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScoreClassic), 0)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.perfectClears), 1)

        // A worse (higher) later score must not overwrite the zero best.
        GameStatisticsRecorder.recordCompletedGame(
            mode: .classic, won: true, baseScore: 4, elapsedSeconds: 0,
            turnCount: 6, remainingOpenTiles: [], defaults: defaults
        )
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScoreClassic), 0)
    }

    // MARK: - A timed result

    /// A timed mode's final score must include elapsed seconds in both the
    /// per-mode best and the per-mode average — and must never touch the
    /// untimed modes' figures.
    func testTimedResultIncludesElapsedSecondsInBestAndAverage() {
        GameStatisticsRecorder.recordCompletedGame(
            mode: .bigBoxSpeed, won: true, baseScore: 6, elapsedSeconds: 40,
            turnCount: 9, remainingOpenTiles: [], defaults: defaults
        )

        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScoreBigBoxSpeed), 46) // 6 + 40
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreTotalBigBoxSpeed), 46)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreCountBigBoxSpeed), 1)

        // Untimed Classic must be entirely unaffected.
        XCTAssertNil(defaults.object(forKey: StatisticsStorageKey.bestScoreClassic))
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreCountClassic), 0)
    }

    /// Two different modes must never mix into the same per-mode bucket —
    /// the concrete bug this update fixes.
    func testDifferentModesAccumulateSeparateAveragesAndBests() {
        GameStatisticsRecorder.recordCompletedGame(
            mode: .classic, won: true, baseScore: 10, elapsedSeconds: 0,
            turnCount: 3, remainingOpenTiles: [], defaults: defaults
        )
        GameStatisticsRecorder.recordCompletedGame(
            mode: .bigBox, won: true, baseScore: 40, elapsedSeconds: 0,
            turnCount: 3, remainingOpenTiles: [], defaults: defaults
        )

        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreTotalClassic), 10)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreCountClassic), 1)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreTotalBigBox), 40)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreCountBigBox), 1)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScoreClassic), 10)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.bestScoreBigBox), 40)
    }

    // MARK: - Repeated recording of the same result

    /// GameStatisticsRecorder itself has no notion of "which game" — calling
    /// it twice always records twice; that's expected and correct for this
    /// function. The actual once-only guard is `GameResultRecordGuard`
    /// (see GameResultRecordGuardTests.swift), which ContentView and
    /// WatchContentView call before ever reaching this function. This test
    /// only documents what *this* function does on repeated calls — it does
    /// not exercise, and cannot catch a regression in, the guard itself
    /// (R3 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
    func testCallingTwiceForTheSameResultDoublesEveryCount() {
        for _ in 0..<2 {
            GameStatisticsRecorder.recordCompletedGame(
                mode: .classic, won: true, baseScore: 3, elapsedSeconds: 0,
                turnCount: 4, remainingOpenTiles: [], defaults: defaults
            )
        }

        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.gamesPlayed), 2)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.gamesWon), 2)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreCountClassic), 2)
        XCTAssertEqual(defaults.integer(forKey: StatisticsStorageKey.modeScoreTotalClassic), 6)
    }
}
