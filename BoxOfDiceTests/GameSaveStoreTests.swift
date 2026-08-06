//
//  GameSaveStoreTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj / R1 in
//  docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//
//  BOD-006: local persistence for one in-progress game. These tests drive
//  GameSaveStore directly against an isolated temp directory (never the
//  real app's Application Support folder) via its `directory:` override.

import XCTest
@testable import BoxOfDice

final class GameSaveStoreTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GameSaveStoreTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    func testNoSavedFileLoadsAsNil() {
        XCTAssertNil(GameSaveStore.load(directory: tempDirectory))
    }

    func testSaveAndLoadRoundTripsEverything() {
        var engine = GameEngine(settings: .default, seed: 55)
        engine.roll(dice: [3, 4, 0])
        engine.toggleTile(3)
        engine.toggleTile(4)
        engine.confirmSelection()

        let start = Date(timeIntervalSinceNow: -120)
        let saved = SavedGame(
            gameMode: .speedRun,
            engine: engine,
            pendingRollDice: [2, 5, 0],
            gameStartTime: start,
            passAndPlayPlayerCount: 3,
            currentPassAndPlayPlayer: 1,
            passAndPlayScores: [10, 20]
        )
        GameSaveStore.save(saved, directory: tempDirectory)

        guard let loaded = GameSaveStore.load(directory: tempDirectory) else {
            return XCTFail("expected a saved game to load back")
        }
        XCTAssertEqual(loaded.gameMode, .speedRun)
        XCTAssertEqual(loaded.engine.tiles, engine.tiles)
        XCTAssertEqual(loaded.engine.gameState, engine.gameState)
        XCTAssertEqual(loaded.engine.moveHistory.count, engine.moveHistory.count)
        XCTAssertEqual(loaded.pendingRollDice, [2, 5, 0])
        XCTAssertNotNil(loaded.gameStartTime)
        XCTAssertEqual(loaded.gameStartTime!.timeIntervalSince(start), 0, accuracy: 0.001)
        XCTAssertEqual(loaded.passAndPlayPlayerCount, 3)
        XCTAssertEqual(loaded.currentPassAndPlayPlayer, 1)
        XCTAssertEqual(loaded.passAndPlayScores, [10, 20])
    }

    /// The seeded random generator's exact progress must survive the
    /// round-trip, so the next roll after a restore is the same roll the
    /// original, never-saved game would have produced.
    func testRandomGeneratorContinuesTheSameSequenceAfterRoundTrip() {
        var engine = GameEngine(settings: .default, seed: 99)
        engine.roll() // consumes some of the generator's sequence
        GameSaveStore.save(SavedGame(gameMode: .classic, engine: engine), directory: tempDirectory)

        guard var loaded = GameSaveStore.load(directory: tempDirectory)?.engine else {
            return XCTFail("expected a saved engine to load back")
        }

        var continuedOriginal = engine
        let nextFromOriginal = continuedOriginal.randomDice()
        let nextFromLoaded = loaded.randomDice()
        XCTAssertEqual(nextFromOriginal, nextFromLoaded)
    }

    func testNewSaveReplacesThePreviousOne() {
        GameSaveStore.save(SavedGame(gameMode: .speedRun, engine: GameEngine(settings: .default, seed: 1), pendingRollDice: [1, 2, 0]), directory: tempDirectory)
        GameSaveStore.save(SavedGame(gameMode: .classic, engine: GameEngine(settings: .default, seed: 2)), directory: tempDirectory)

        let loaded = GameSaveStore.load(directory: tempDirectory)
        XCTAssertEqual(loaded?.gameMode, .classic)
        XCTAssertNil(loaded?.pendingRollDice, "the old pending roll must not leak into the new save")
    }

    func testClearRemovesTheSavedGame() {
        GameSaveStore.save(SavedGame(gameMode: .classic, engine: GameEngine()), directory: tempDirectory)
        XCTAssertNotNil(GameSaveStore.load(directory: tempDirectory))
        GameSaveStore.clear(directory: tempDirectory)
        XCTAssertNil(GameSaveStore.load(directory: tempDirectory))
    }

    func testClearingWithNothingSavedDoesNotThrowOrCrash() {
        GameSaveStore.clear(directory: tempDirectory) // must simply do nothing
        XCTAssertNil(GameSaveStore.load(directory: tempDirectory))
    }

    // MARK: - Corrupt / unknown save data must never crash

    func testCorruptFileLoadsAsNilInsteadOfCrashing() throws {
        let url = try XCTUnwrap(GameSaveStore.fileURL(directory: tempDirectory))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("this is not JSON at all { [ }".utf8).write(to: url)

        XCTAssertNil(GameSaveStore.load(directory: tempDirectory))
    }

    func testUnrecognizedJSONShapeLoadsAsNilInsteadOfCrashing() throws {
        let url = try XCTUnwrap(GameSaveStore.fileURL(directory: tempDirectory))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"{"somethingElse": true, "notASavedGame": [1,2,3]}"#.utf8).write(to: url)

        XCTAssertNil(GameSaveStore.load(directory: tempDirectory))
    }

    func testEmptyFileLoadsAsNilInsteadOfCrashing() throws {
        let url = try XCTUnwrap(GameSaveStore.fileURL(directory: tempDirectory))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: url)

        XCTAssertNil(GameSaveStore.load(directory: tempDirectory))
    }
}
