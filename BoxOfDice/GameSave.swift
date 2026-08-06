//
//  GameSave.swift
//  BoxOfDice
//

import Foundation

// Local, on-device persistence for one in-progress game (BOD-006). Shared
// verbatim by the iOS and watchOS targets — see this file's explicit
// membership in both targets in project.pbxproj, same as GameEngine.swift.
// No cloud sync, no Core Data: a single versioned Codable snapshot, written
// atomically to a JSON file in each app's own Application Support directory.

/// Everything needed to resume exactly where a game left off: the mode and
/// rules it was started with, the full engine state (tiles, dice, selection,
/// game phase, move history, and the seeded random generator's exact
/// progress so future rolls don't change because of the save), a dice roll
/// that had already been drawn but not yet committed when the app was
/// backgrounded mid-animation, the wall-clock start time for timed modes
/// (so backgrounded/quit time still counts), and local Pass & Play progress.
struct SavedGame: Codable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int = SavedGame.currentSchemaVersion
    var gameMode: GameMode
    var engine: GameEngine

    /// Dice already drawn by `randomDice()` for a roll that hadn't been
    /// committed to the engine yet (the animation was still in flight) when
    /// this was saved. On restore this must be committed via
    /// `engine.roll(dice:)` immediately — never redrawn, and never left
    /// pending forever.
    var pendingRollDice: [Int]?

    /// Wall-clock time the timed-mode clock started. Restoring this instead
    /// of resetting it is what makes background/quit time still count
    /// toward a timed result.
    var gameStartTime: Date?

    var passAndPlayPlayerCount: Int
    var currentPassAndPlayPlayer: Int
    var passAndPlayScores: [Int]

    init(
        gameMode: GameMode,
        engine: GameEngine,
        pendingRollDice: [Int]? = nil,
        gameStartTime: Date? = nil,
        passAndPlayPlayerCount: Int = 2,
        currentPassAndPlayPlayer: Int = 0,
        passAndPlayScores: [Int] = []
    ) {
        self.gameMode = gameMode
        self.engine = engine
        self.pendingRollDice = pendingRollDice
        self.gameStartTime = gameStartTime
        self.passAndPlayPlayerCount = passAndPlayPlayerCount
        self.currentPassAndPlayPlayer = currentPassAndPlayPlayer
        self.passAndPlayScores = passAndPlayScores
    }
}

/// Reads/writes the single active-game save file. Every failure mode —
/// missing file, unreadable file, corrupt/unrecognized JSON — is handled by
/// returning `nil` (treated as "no saved game"); this type never throws out
/// to a caller and never crashes the app on bad data.
enum GameSaveStore {

    /// Override point for tests, so they never touch the real app's saved
    /// game file. Production code always uses the default.
    static func fileURL(directory: URL? = nil) -> URL? {
        let base: URL?
        if let directory {
            base = directory
        } else {
            base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        }
        guard let base else { return nil }
        let appDirectory = base.appendingPathComponent("BoxOfDice", isDirectory: true)
        return appDirectory.appendingPathComponent("active_game.json", isDirectory: false)
    }

    /// Saves the given game, overwriting whatever was saved before (a new
    /// game — or the next action in the same game — replaces the previous
    /// snapshot; there is only ever one saved game). Failures are silently
    /// ignored: a failed save just means the next background/relaunch falls
    /// back to starting fresh, which is safe.
    static func save(_ game: SavedGame, directory: URL? = nil) {
        guard let url = fileURL(directory: directory) else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(game)
            // `.atomic` writes to a temporary file and renames it into place,
            // so a crash or termination mid-write can never leave a
            // half-written (corrupt) save file.
            try data.write(to: url, options: .atomic)
        } catch {
            // Best-effort persistence: nothing meaningful to do with a save
            // failure other than leave the previous (or no) save in place.
        }
    }

    /// Loads the saved game, if any. Returns `nil` for a missing file, an
    /// unreadable file, or JSON that doesn't decode as `SavedGame` —
    /// including a schema from a future/incompatible version of the app.
    static func load(directory: URL? = nil) -> SavedGame? {
        guard let url = fileURL(directory: directory),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SavedGame.self, from: data)
    }

    /// Deletes the saved game, if any. Called once a game finishes (nothing
    /// left to resume) and safe to call when there is nothing to delete.
    static func clear(directory: URL? = nil) {
        guard let url = fileURL(directory: directory) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
