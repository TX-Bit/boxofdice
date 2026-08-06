//
//  WatchGameModeSupportTests.swift
//  BoxOfDice Watch App Tests
//
//  Covers the centralized Watch-supported-mode roster and legacy-mode
//  normalization (GameMode.supportedOnWatch / normalizedForWatch), plus the
//  restore-time guard against an incompatible in-progress save (e.g. an
//  18-tile Big Box engine that must never be mislabeled as 12-tile Classic).
//

import XCTest
@testable import BoxOfDice_Watch_App

final class WatchGameModeSupportTests: XCTestCase {

    func testSupportedRosterIsExactlyQuickGameClassicSpeedRunPassAndPlayInOrder() {
        XCTAssertEqual(GameMode.supportedOnWatch, [.quickGame, .classic, .speedRun, .passAndPlay])
    }

    func testEveryWatchSupportedModeNormalizesToItself() {
        for mode in GameMode.supportedOnWatch {
            XCTAssertEqual(GameMode.normalizedForWatch(mode), mode,
                            "\(mode) is Watch-supported and must pass through unchanged")
        }
    }

    func testBigBoxFamilyNormalizesToClassic() {
        XCTAssertEqual(GameMode.normalizedForWatch(.bigBox), .classic)
        XCTAssertEqual(GameMode.normalizedForWatch(.bigBoxSpeed), .classic)
    }

    func testNormalizedForWatchFromRawValueHandlesEveryCaseAndUnknownValues() {
        for mode in GameMode.allCases {
            let expected = GameMode.normalizedForWatch(mode)
            XCTAssertEqual(GameMode.normalizedForWatch(rawValue: mode.rawValue), expected)
        }
        XCTAssertEqual(GameMode.normalizedForWatch(rawValue: "not-a-real-mode"), .classic)
    }

    // MARK: - 9 vs. 12 tile launch settings

    func testQuickGameUsesNineTilesAndOtherSupportedModesUseTwelve() {
        for mode in GameMode.supportedOnWatch {
            let settings = GameSettings.from(mode: mode, diceMode: mode.diceMode, moveRule: .anyCombination)
            if mode == .quickGame {
                XCTAssertEqual(settings.tileCount, 9)
                XCTAssertEqual(settings.diceMode, .oneDieWhenLowTilesRemain)
            } else {
                XCTAssertEqual(settings.tileCount, 12, "\(mode) must use 12 tiles on Watch")
                XCTAssertEqual(settings.diceMode, .alwaysTwoDice)
            }
            XCTAssertEqual(settings.baseDiceCount, 2)
        }
    }
}

// MARK: - Restore-time incompatible-save handling

final class WatchSavedGameCompatibilityTests: XCTestCase {

    private func withIsolatedSaveDirectory(_ body: (URL) -> Void) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("WatchSaveCompatTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        body(dir)
    }

    /// A save whose recorded mode and engine agree (Classic, 12 tiles) must
    /// load normally.
    func testCompatibleSaveLoadsNormally() {
        withIsolatedSaveDirectory { dir in
            let engine = GameEngine(settings: GameSettings.from(mode: .classic, diceMode: .alwaysTwoDice, moveRule: .anyCombination))
            let saved = SavedGame(gameMode: .classic, engine: engine)
            GameSaveStore.save(saved, directory: dir)

            let loaded = GameSaveStore.load(directory: dir)
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded?.engine.settings.tileCount, GameMode.normalizedForWatch(loaded!.gameMode).tileCount)
        }
    }

    /// An old Big Box save (18 tiles) must never be presented as a 12-tile
    /// Classic game — the tile count wouldn't match what "Classic" implies
    /// on this Watch build (the mismatch this test guards against is the one
    /// `WatchContentView.restoreSavedGameIfAny()` checks for before
    /// restoring).
    func testIncompatibleBigBoxSaveIsDetectedAndNotMislabeled() {
        withIsolatedSaveDirectory { dir in
            let bigBoxSettings = GameSettings(tileCount: 18, baseDiceCount: 3, diceMode: .alwaysTwoDice, moveRule: .anyCombination)
            let engine = GameEngine(settings: bigBoxSettings)
            let saved = SavedGame(gameMode: .bigBox, engine: engine)
            GameSaveStore.save(saved, directory: dir)

            let loaded = GameSaveStore.load(directory: dir)
            XCTAssertNotNil(loaded)
            let normalizedMode = GameMode.normalizedForWatch(loaded!.gameMode)
            XCTAssertEqual(normalizedMode, .classic)
            XCTAssertNotEqual(loaded!.engine.settings.tileCount, normalizedMode.tileCount,
                               "sanity check: this is exactly the incompatible case that must be rejected, not silently relabeled")
        }
    }
}
