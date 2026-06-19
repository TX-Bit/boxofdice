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
    @AppStorage(StatisticsStorageKey.longestGameTurns) private var longestGameTurns = 0
    @AppStorage(StatisticsStorageKey.shortestClearTurns) private var shortestClearTurns = 0
    @AppStorage(StatisticsStorageKey.remainingTileCounts) private var remainingTileCounts = ""

    @AppStorage(StatisticsStorageKey.bestScoreClassic) private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun) private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox) private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed) private var bestScoreBigBoxSpeed = 0

    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.classicWood.rawValue

    @State private var showResetConfirm = false

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    summaryGrid

                    statsSection(title: "Scores", rows: [
                        ("Average score",         averageScoreText),
                        ("Average winning score", averageWinningScoreText),
                        ("Average losing score",  averageLosingScoreText),
                        ("Perfect clears",        "\(perfectClears)"),
                    ])

                    bestScoresByModeSection

                    statsSection(title: "Streaks & Length", rows: [
                        ("Current win streak", "\(currentWinStreak)"),
                        ("Best win streak",    "\(bestWinStreak)"),
                        ("Longest game",       turnsText(longestGameTurns)),
                        ("Shortest clear",     turnsText(shortestClearTurns)),
                    ])

                    remainingTilesSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset", role: .destructive) { showResetConfirm = true }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Reset all statistics?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Summary grid (4 cards)

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())],
            spacing: 12
        ) {
            StatCard(title: "Played",     value: "\(gamesPlayed)", theme: theme)
            StatCard(title: "Won",        value: "\(gamesWon)",    theme: theme)
            StatCard(title: "Lost",       value: "\(losses)",      theme: theme)
            StatCard(title: "Best Score", value: bestScoreText,    theme: theme)
        }
    }

    // MARK: - Best scores by mode

    private var bestScoresByModeSection: some View {
        statsSection(title: "Best Score by Mode", rows: [
            (GameMode.classic.title,     bestText(bestScoreClassic)),
            (GameMode.speedRun.title,    bestText(bestScoreSpeedRun)),
            (GameMode.bigBox.title,      bestText(bestScoreBigBox)),
            (GameMode.bigBoxSpeed.title, bestText(bestScoreBigBoxSpeed)),
        ])
    }

    // MARK: - Generic section

    private func statsSection(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    rowItem(label: row.0, value: row.1)
                    if index < rows.count - 1 {
                        rowDivider
                    }
                }
            }
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
    }

    // MARK: - Remaining tiles bar chart section

    private var remainingTilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Most Common Remaining Tiles")

            VStack(spacing: 0) {
                if commonRemainingTiles.isEmpty {
                    Text("No data yet — play a few games first")
                        .font(GameTypography.label(size: 16))
                        .foregroundStyle(theme.text.opacity(0.52))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                } else {
                    let maxCount = commonRemainingTiles.first?.count ?? 1
                    ForEach(Array(commonRemainingTiles.enumerated()), id: \.element.tile) { index, entry in
                        TileBarRow(tile: entry.tile, count: entry.count, maxCount: maxCount, theme: theme)
                        if index < commonRemainingTiles.count - 1 {
                            rowDivider
                        }
                    }
                }
            }
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
    }

    // MARK: - Reusable sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(L10n.string(title).uppercased())
            .font(GameTypography.section(size: 12))
            .tracking(1.3)
            .foregroundStyle(theme.text.opacity(0.58))
            .padding(.horizontal, 4)
    }

    private func rowItem(label: String, value: String) -> some View {
        HStack {
            Text(L10n.string(label))
                .font(GameTypography.label(size: 16))
                .foregroundStyle(theme.text.opacity(0.82))
            Spacer()
            Text(value)
                .font(GameTypography.value(size: 16))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.08))
            .padding(.horizontal, 16)
    }

    // MARK: - Computed values

    private var bestScoreText: String { bestText(bestScore, requiresGames: true) }

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

    private func resetStats() {
        gamesPlayed = 0; gamesWon = 0; bestScore = 0; totalScore = 0
        perfectClears = 0; currentWinStreak = 0; bestWinStreak = 0
        winningScoreTotal = 0; losingScoreTotal = 0; losses = 0
        longestGameTurns = 0; shortestClearTurns = 0; remainingTileCounts = ""
        bestScoreClassic = 0; bestScoreSpeedRun = 0; bestScoreBigBox = 0; bestScoreBigBoxSpeed = 0
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

    private func bestText(_ score: Int, requiresGames: Bool = false) -> String {
        if requiresGames && gamesPlayed == 0 { return "-" }
        return score == 0 ? "-" : "\(score)"
    }

    private func formattedAverage(_ total: Int, count: Int) -> String {
        let average = Double(total) / Double(count)
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    private func turnsText(_ turns: Int) -> String {
        turns == 0 ? "-" : L10n.format("%d turns", turns)
    }
}

// MARK: - Stat card (summary)

private struct StatCard: View {
    let title: String
    let value: String
    let theme: GameTheme

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(GameTypography.display(size: 31))
                .foregroundStyle(Color(red: 0.18, green: 0.09, blue: 0.03))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(L10n.string(title).uppercased())
                .font(GameTypography.section(size: 10))
                .tracking(1.1)
                .foregroundStyle(Color(red: 0.30, green: 0.14, blue: 0.04).opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(colors: theme.button, startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.40), lineWidth: 1)
        )
    }
}

// MARK: - Tile bar row

private struct TileBarRow: View {
    let tile: Int
    let count: Int
    let maxCount: Int
    let theme: GameTheme

    var body: some View {
        HStack(spacing: 12) {
            Text("\(tile)")
                .font(GameTypography.tileNumber(size: 15))
                .foregroundStyle(Color(red: 0.16, green: 0.07, blue: 0.02))
                .frame(width: 30, height: 26)
                .background(
                    LinearGradient(colors: theme.button, startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.75)
                )

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))

                    let fraction = CGFloat(count) / CGFloat(max(maxCount, 1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.82, blue: 0.38),
                                Color(red: 0.88, green: 0.50, blue: 0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(8, geo.size.width * fraction))
                }
            }
            .frame(height: 10)

            Text("\(count)×")
                .font(GameTypography.value(size: 13))
                .foregroundStyle(theme.text.opacity(0.72))
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    StatsView()
}
