//
//  GameStatistics.swift
//  BoxOfDice
//

import Foundation

enum StatisticsStorageKey {
    static let gamesPlayed = "statistics.gamesPlayed"
    static let gamesWon = "statistics.gamesWon"
    static let bestScore = "statistics.bestScore"
    static let totalScore = "statistics.totalScore"
    static let perfectClears = "statistics.perfectClears"
    static let currentWinStreak = "statistics.currentWinStreak"
    static let bestWinStreak = "statistics.bestWinStreak"
    static let winningScoreTotal = "statistics.winningScoreTotal"
    static let losingScoreTotal = "statistics.losingScoreTotal"
    static let losses = "statistics.losses"
    static let longestGameTurns = "statistics.longestGameTurns"
    static let shortestClearTurns = "statistics.shortestClearTurns"
    static let remainingTileCounts = "statistics.remainingTileCounts"

    // Per-mode best scores (final score including any time penalty)
    static let bestScoreQuickGame = "statistics.bestScore.quickGame"
    static let bestScoreClassic = "statistics.bestScore.classic"
    static let bestScoreSpeedRun = "statistics.bestScore.speedRun"
    static let bestScoreBigBox = "statistics.bestScore.bigBox"
    static let bestScoreBigBoxSpeed = "statistics.bestScore.bigBoxSpeed"

    // Per-mode score totals/counts, used to compute a per-mode average.
    // totalScore/bestScore/winningScoreTotal/losingScoreTotal above mix final
    // scores across board sizes and timed/untimed modes and are no longer
    // written to going forward (kept only so old data isn't lost) — these
    // per-mode counters start at zero for every install and only count games
    // recorded from this update onward, since old combined totals can't be
    // split retroactively by mode.
    static let modeScoreTotalQuickGame = "statistics.modeScoreTotal.quickGame"
    static let modeScoreTotalClassic = "statistics.modeScoreTotal.classic"
    static let modeScoreTotalSpeedRun = "statistics.modeScoreTotal.speedRun"
    static let modeScoreTotalBigBox = "statistics.modeScoreTotal.bigBox"
    static let modeScoreTotalBigBoxSpeed = "statistics.modeScoreTotal.bigBoxSpeed"
    static let modeScoreCountQuickGame = "statistics.modeScoreCount.quickGame"
    static let modeScoreCountClassic = "statistics.modeScoreCount.classic"
    static let modeScoreCountSpeedRun = "statistics.modeScoreCount.speedRun"
    static let modeScoreCountBigBox = "statistics.modeScoreCount.bigBox"
    static let modeScoreCountBigBoxSpeed = "statistics.modeScoreCount.bigBoxSpeed"
}
