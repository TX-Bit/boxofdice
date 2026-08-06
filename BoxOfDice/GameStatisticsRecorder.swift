//
//  GameStatisticsRecorder.swift
//  BoxOfDice
//

import Foundation

/// Records a completed game's statistics directly against a `UserDefaults`
/// store, using the same keys `ContentView`'s `@AppStorage` properties bind
/// to. Pulled out of `ContentView` (BOD-005) so this logic — comparability
/// of per-mode scores, per-mode averages starting from this update, and
/// preservation of old combined counts/records — can be exercised directly
/// in tests against an isolated `UserDefaults` store, without going through
/// SwiftUI.
enum GameStatisticsRecorder {

    /// Records one finished, non-multiplayer game. Call exactly once per
    /// finished game — the caller (`ContentView.handleGameOver`) is
    /// responsible for not calling this twice for the same game.
    static func recordCompletedGame(
        mode: GameMode,
        won: Bool,
        baseScore: Int,
        elapsedSeconds: Int,
        turnCount: Int,
        remainingOpenTiles: [Int],
        defaults: UserDefaults = .standard
    ) {
        let finalScore = mode.finalScore(baseScore: baseScore, elapsedSeconds: elapsedSeconds)

        increment(StatisticsStorageKey.gamesPlayed, in: defaults)
        setMax(StatisticsStorageKey.longestGameTurns, to: turnCount, in: defaults)
        updateBestScoreByMode(mode: mode, finalScore: finalScore, defaults: defaults)
        updateModeScoreAverage(mode: mode, finalScore: finalScore, defaults: defaults)
        updateRemainingTileCounts(remainingOpenTiles, defaults: defaults)

        if won {
            increment(StatisticsStorageKey.gamesWon, in: defaults)
            if baseScore == 0 {
                increment(StatisticsStorageKey.perfectClears, in: defaults)
            }
            let newStreak = defaults.integer(forKey: StatisticsStorageKey.currentWinStreak) + 1
            defaults.set(newStreak, forKey: StatisticsStorageKey.currentWinStreak)
            setMax(StatisticsStorageKey.bestWinStreak, to: newStreak, in: defaults)

            let shortest = defaults.integer(forKey: StatisticsStorageKey.shortestClearTurns)
            defaults.set(shortest == 0 ? turnCount : min(shortest, turnCount), forKey: StatisticsStorageKey.shortestClearTurns)
        } else {
            increment(StatisticsStorageKey.losses, in: defaults)
            defaults.set(0, forKey: StatisticsStorageKey.currentWinStreak)
        }
    }

    // MARK: - Per-mode best score (existing behaviour, preserved verbatim)

    private static func updateBestScoreByMode(mode: GameMode, finalScore: Int, defaults: UserDefaults) {
        let key: String
        switch mode {
        case .quickGame:    key = StatisticsStorageKey.bestScoreQuickGame
        case .classic:      key = StatisticsStorageKey.bestScoreClassic
        case .speedRun:     key = StatisticsStorageKey.bestScoreSpeedRun
        case .bigBox:       key = StatisticsStorageKey.bestScoreBigBox
        case .bigBoxSpeed:  key = StatisticsStorageKey.bestScoreBigBoxSpeed
        case .passAndPlay:  return
        }
        let hasExisting = defaults.object(forKey: key) != nil
        let current = defaults.integer(forKey: key)
        defaults.set(hasExisting ? min(current, finalScore) : finalScore, forKey: key)
    }

    // MARK: - Per-mode score total/count (BOD-005)

    private static func updateModeScoreAverage(mode: GameMode, finalScore: Int, defaults: UserDefaults) {
        let totalKey: String
        let countKey: String
        switch mode {
        case .quickGame:    totalKey = StatisticsStorageKey.modeScoreTotalQuickGame; countKey = StatisticsStorageKey.modeScoreCountQuickGame
        case .classic:      totalKey = StatisticsStorageKey.modeScoreTotalClassic;     countKey = StatisticsStorageKey.modeScoreCountClassic
        case .speedRun:     totalKey = StatisticsStorageKey.modeScoreTotalSpeedRun;    countKey = StatisticsStorageKey.modeScoreCountSpeedRun
        case .bigBox:       totalKey = StatisticsStorageKey.modeScoreTotalBigBox;      countKey = StatisticsStorageKey.modeScoreCountBigBox
        case .bigBoxSpeed:  totalKey = StatisticsStorageKey.modeScoreTotalBigBoxSpeed; countKey = StatisticsStorageKey.modeScoreCountBigBoxSpeed
        case .passAndPlay:  return
        }
        defaults.set(defaults.integer(forKey: totalKey) + finalScore, forKey: totalKey)
        increment(countKey, in: defaults)
    }

    // MARK: - Remaining open tiles histogram (existing behaviour, preserved verbatim)

    private static func updateRemainingTileCounts(_ tiles: [Int], defaults: UserDefaults) {
        var counts = parseRemainingTileCounts(defaults.string(forKey: StatisticsStorageKey.remainingTileCounts) ?? "")
        for tile in tiles {
            counts[tile, default: 0] += 1
        }
        let encoded = counts
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")
        defaults.set(encoded, forKey: StatisticsStorageKey.remainingTileCounts)
    }

    private static func parseRemainingTileCounts(_ raw: String) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for pair in raw.split(separator: ",") {
            let parts = pair.split(separator: ":")
            guard parts.count == 2, let tile = Int(parts[0]), let count = Int(parts[1]) else { continue }
            counts[tile] = count
        }
        return counts
    }

    // MARK: - Small helpers

    private static func increment(_ key: String, in defaults: UserDefaults) {
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    private static func setMax(_ key: String, to candidate: Int, in defaults: UserDefaults) {
        defaults.set(max(defaults.integer(forKey: key), candidate), forKey: key)
    }
}
