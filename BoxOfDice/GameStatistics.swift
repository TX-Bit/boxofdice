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
    static let bestScoreClassic = "statistics.bestScore.classic"
    static let bestScoreSpeedRun = "statistics.bestScore.speedRun"
    static let bestScoreBigBox = "statistics.bestScore.bigBox"
    static let bestScoreBigBoxSpeed = "statistics.bestScore.bigBoxSpeed"
}
