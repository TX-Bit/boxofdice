//
//  StatsView.swift
//  BoxOfDice
//

import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(StatisticsStorageKey.gamesPlayed) private var gamesPlayed = 0
    @AppStorage(StatisticsStorageKey.gamesWon) private var gamesWon = 0
    @AppStorage(StatisticsStorageKey.bestScore) private var bestScore = 0
    @AppStorage(StatisticsStorageKey.totalScore) private var totalScore = 0
    @AppStorage(StatisticsStorageKey.perfectClears) private var perfectClears = 0
    @AppStorage(StatisticsStorageKey.currentWinStreak) private var currentWinStreak = 0
    @AppStorage(StatisticsStorageKey.bestWinStreak) private var bestWinStreak = 0
    @AppStorage(StatisticsStorageKey.winningScoreTotal) private var winningScoreTotal = 0
    @AppStorage(StatisticsStorageKey.losingScoreTotal) private var losingScoreTotal = 0
    @AppStorage(StatisticsStorageKey.losses) private var losses = 0
    @AppStorage(StatisticsStorageKey.bestScore9) private var bestScore9 = 0
    @AppStorage(StatisticsStorageKey.bestScore10) private var bestScore10 = 0
    @AppStorage(StatisticsStorageKey.bestScore12) private var bestScore12 = 0
    @AppStorage(StatisticsStorageKey.longestGameTurns) private var longestGameTurns = 0
    @AppStorage(StatisticsStorageKey.shortestClearTurns) private var shortestClearTurns = 0
    @AppStorage(StatisticsStorageKey.remainingTileCounts) private var remainingTileCounts = ""
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.classicWood.rawValue

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        StatCard(title: "Played", value: "\(gamesPlayed)", theme: theme)
                        StatCard(title: "Won", value: "\(gamesWon)", theme: theme)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section("Scores") {
                    StatRow(title: "Win rate", value: winRateText)
                    StatRow(title: "Best score", value: bestScoreText)
                    StatRow(title: "Average score", value: averageScoreText)
                    StatRow(title: "Average winning score", value: averageWinningScoreText)
                    StatRow(title: "Average losing score", value: averageLosingScoreText)
                    StatRow(title: "Perfect clears", value: "\(perfectClears)")
                }
                .themedListRow(theme)

                Section("Best by Tile Count") {
                    StatRow(title: "9 tiles", value: bestScoreText(bestScore9))
                    StatRow(title: "10 tiles", value: bestScoreText(bestScore10))
                    StatRow(title: "12 tiles", value: bestScoreText(bestScore12))
                }
                .themedListRow(theme)

                Section("Streaks and Length") {
                    StatRow(title: "Current win streak", value: "\(currentWinStreak)")
                    StatRow(title: "Best win streak", value: "\(bestWinStreak)")
                    StatRow(title: "Longest game", value: turnsText(longestGameTurns))
                    StatRow(title: "Shortest clear", value: turnsText(shortestClearTurns))
                }
                .themedListRow(theme)

                Section("Most Common Remaining Tiles") {
                    if commonRemainingTiles.isEmpty {
                        Text("No remaining tile data yet")
                            .foregroundStyle(theme.text.opacity(0.7))
                    } else {
                        ForEach(commonRemainingTiles, id: \.tile) { entry in
                            StatRow(title: "Tile \(entry.tile)", value: "\(entry.count)x")
                        }
                    }
                }
                .themedListRow(theme)
            }
            .scrollContentBackground(.hidden)
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .foregroundStyle(theme.text)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var bestScoreText: String { bestScoreText(bestScore, requiresGames: true) }

    private var averageScoreText: String {
        guard gamesPlayed > 0 else { return "-" }
        return formattedAverage(totalScore, count: gamesPlayed)
    }

    private var averageWinningScoreText: String {
        guard gamesWon > 0 else { return "-" }
        return formattedAverage(winningScoreTotal, count: gamesWon)
    }

    private var averageLosingScoreText: String {
        guard losses > 0 else { return "-" }
        return formattedAverage(losingScoreTotal, count: losses)
    }

    private var winRateText: String {
        guard gamesPlayed > 0 else { return "-" }
        let rate = Double(gamesWon) / Double(gamesPlayed) * 100
        return rate.formatted(.number.precision(.fractionLength(1))) + "%"
    }

    private var commonRemainingTiles: [(tile: Int, count: Int)] {
        remainingTileCounts
            .split(separator: ",")
            .compactMap { pair -> (Int, Int)? in
                let parts = pair.split(separator: ":")
                guard parts.count == 2, let tile = Int(parts[0]), let count = Int(parts[1]) else { return nil }
                return (tile, count)
            }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 { return lhs.0 < rhs.0 }
                return lhs.1 > rhs.1
            }
            .prefix(5)
            .map { (tile: $0.0, count: $0.1) }
    }

    private func bestScoreText(_ score: Int, requiresGames: Bool = false) -> String {
        if requiresGames && gamesPlayed == 0 { return "-" }
        return score == 0 ? "-" : "\(score)"
    }

    private func formattedAverage(_ total: Int, count: Int) -> String {
        let average = Double(total) / Double(count)
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    private func turnsText(_ turns: Int) -> String {
        turns == 0 ? "-" : "\(turns) turns"
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let theme: GameTheme

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.09, blue: 0.03))
                .minimumScaleFactor(0.7)
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: theme.button,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
        )
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StatsView()
}
