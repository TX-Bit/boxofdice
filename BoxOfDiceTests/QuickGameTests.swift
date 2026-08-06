//
//  QuickGameTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj / R1 in
//  docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//
//  BOD-011: the nine-tile "Quick Game" mode (docs/CLAUDE_UUDET_OMINAISUUDET.md).

import XCTest
@testable import BoxOfDice

final class QuickGameTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuickGameTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    private func quickGameSettings() -> GameSettings {
        GameSettings.from(mode: .quickGame, diceMode: GameMode.quickGame.diceMode, moveRule: .anyCombination)
    }

    // MARK: - Starting state

    func testQuickGameStartsWithNineTilesTwoDiceAndScore45() {
        let engine = GameEngine(settings: quickGameSettings())
        XCTAssertEqual(engine.tiles.map(\.id), Array(1...9))
        XCTAssertTrue(engine.tiles.allSatisfy(\.isOpen))
        XCTAssertEqual(engine.currentDieCount, 2)
        XCTAssertEqual(engine.score, 45) // 1+2+...+9
    }

    func testClassicStillHasTwelveTilesAndItsOwnRules() {
        let engine = GameEngine(settings: GameSettings.from(mode: .classic, diceMode: GameMode.classic.diceMode, moveRule: .anyCombination))
        XCTAssertEqual(engine.tiles.map(\.id), Array(1...12))
        XCTAssertEqual(engine.currentDieCount, 2) // Classic never drops to one die
        XCTAssertEqual(engine.score, 78) // 1+2+...+12
    }

    // MARK: - Dropping to one die

    func testSwitchesToOneDieOnceTilesSevenThroughNineAreAllClosed() {
        var engine = GameEngine(settings: quickGameSettings())
        XCTAssertEqual(engine.currentDieCount, 2, "still two dice while any of 7,8,9 is open")

        // Close 9, 8, 7 one at a time (each alone, matching a single die's max of 6 is
        // impossible directly, so use two-die rolls that sum to each tile while it's
        // still the only way to reach it exactly).
        for tile in [9, 8, 7] {
            let pairSummingToTile = dicePair(summingTo: tile)
            engine.roll(dice: [pairSummingToTile[0], pairSummingToTile[1], 0])
            engine.toggleTile(tile)
            engine.confirmSelection()
        }

        XCTAssertTrue(engine.openTiles.allSatisfy { $0 <= 6 }, "only tiles 1...6 remain open")
        XCTAssertEqual(engine.currentDieCount, 1, "must have switched to a single die")
    }

    func testStaysAtTwoDiceIfAnyOfSevenEightNineIsStillOpen() {
        var engine = GameEngine(settings: quickGameSettings())
        // Close only 9 and 8, leaving 7 (and 1...6) open.
        for tile in [9, 8] {
            let pair = dicePair(summingTo: tile)
            engine.roll(dice: [pair[0], pair[1], 0])
            engine.toggleTile(tile)
            engine.confirmSelection()
        }
        XCTAssertTrue(engine.openTiles.contains(7))
        XCTAssertEqual(engine.currentDieCount, 2, "tile 7 is still open, so two dice remain")
    }

    // MARK: - Any combination of open tiles is allowed

    func testAnyCombinationOfOpenTilesIsAcceptedInQuickGame() {
        var engine = GameEngine(settings: quickGameSettings())
        engine.roll(dice: [3, 4, 0]) // total 7: both [7] and [3,4] (and others) are valid
        let moves = engine.validMoves()
        XCTAssertTrue(moves.contains([7]))
        XCTAssertTrue(moves.contains { Set($0) == Set([3, 4]) })
    }

    // MARK: - Statistics stay separate from Classic

    func testQuickGameResultAndBestScoreDoNotAffectClassicStatistics() {
        GameStatisticsRecorder.recordCompletedGame(
            mode: .quickGame, won: true, baseScore: 5, elapsedSeconds: 0,
            turnCount: 4, remainingOpenTiles: [], defaults: defaultsForTest
        )

        XCTAssertEqual(defaultsForTest.integer(forKey: StatisticsStorageKey.bestScoreQuickGame), 5)
        XCTAssertNotNil(defaultsForTest.object(forKey: StatisticsStorageKey.bestScoreQuickGame))
        XCTAssertEqual(defaultsForTest.integer(forKey: StatisticsStorageKey.modeScoreCountQuickGame), 1)

        // Classic's own records/averages must be completely untouched.
        XCTAssertNil(defaultsForTest.object(forKey: StatisticsStorageKey.bestScoreClassic))
        XCTAssertEqual(defaultsForTest.integer(forKey: StatisticsStorageKey.modeScoreCountClassic), 0)
    }

    private lazy var defaultsForTest: UserDefaults = {
        UserDefaults(suiteName: "QuickGameTests.\(UUID().uuidString)")!
    }()

    // MARK: - Save/restore uses the game's own mode and rules

    func testQuickGameSaveRestoresAsQuickGameNotClassic() {
        var engine = GameEngine(settings: quickGameSettings())
        engine.roll(dice: [3, 4, 0])
        engine.toggleTile(7)
        let saved = SavedGame(gameMode: .quickGame, engine: engine)
        GameSaveStore.save(saved, directory: tempDirectory)

        guard let loaded = GameSaveStore.load(directory: tempDirectory) else {
            return XCTFail("expected the Quick Game save to load back")
        }
        XCTAssertEqual(loaded.gameMode, .quickGame)
        XCTAssertEqual(loaded.engine.tiles.count, 9)
        XCTAssertEqual(loaded.engine.selectedTiles, [7])
    }

    func testOldClassicSaveStillRestoresAsATwelveTileGame() {
        // Simulates a save written before Quick Game existed: a Classic
        // engine snapshot, saved under the Classic mode.
        let engine = GameEngine(settings: GameSettings.from(mode: .classic, diceMode: .alwaysTwoDice, moveRule: .anyCombination))
        GameSaveStore.save(SavedGame(gameMode: .classic, engine: engine), directory: tempDirectory)

        guard let loaded = GameSaveStore.load(directory: tempDirectory) else {
            return XCTFail("expected the old Classic save to load back")
        }
        XCTAssertEqual(loaded.gameMode, .classic)
        XCTAssertEqual(loaded.engine.tiles.count, 12)
    }

    // MARK: - Helpers

    /// Two die faces (1...6 each) that sum to `total`, for constructing
    /// specific rolls without depending on random generation.
    private func dicePair(summingTo total: Int) -> [Int] {
        for a in 1...6 {
            let b = total - a
            if (1...6).contains(b) { return [a, b] }
        }
        preconditionFailure("no die pair sums to \(total)")
    }
}
