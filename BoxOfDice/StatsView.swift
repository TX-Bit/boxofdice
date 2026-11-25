//
//  StatsView.swift
//  BoxOfDice
//

import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(StatisticsStorageKey.gamesPlayed) private var gamesPlayed = 0
    @AppStorage(StatisticsStorageKey.gamesWon) private var gamesWon = 0
    @AppStorage(StatisticsStorageKey.perfectClears) private var perfectClears = 0
    @AppStorage(StatisticsStorageKey.currentWinStreak) private var currentWinStreak = 0
    @AppStorage(StatisticsStorageKey.bestWinStreak) private var bestWinStreak = 0
    @AppStorage(StatisticsStorageKey.losses) private var losses = 0
    @AppStorage(StatisticsStorageKey.longestGameTurns) private var longestGameTurns = 0
    @AppStorage(StatisticsStorageKey.shortestClearTurns) private var shortestClearTurns = 0
    @AppStorage(StatisticsStorageKey.remainingTileCounts) private var remainingTileCounts = ""

    @AppStorage(StatisticsStorageKey.bestScoreQuickGame) private var bestScoreQuickGame = 0
    @AppStorage(StatisticsStorageKey.bestScoreClassic) private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun) private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox) private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed) private var bestScoreBigBoxSpeed = 0

    // Per-mode score totals/counts (BOD-005) — see GameStatistics.swift.
    @AppStorage(StatisticsStorageKey.modeScoreTotalQuickGame) private var modeScoreTotalQuickGame = 0
    @AppStorage(StatisticsStorageKey.modeScoreTotalClassic) private var modeScoreTotalClassic = 0
    @AppStorage(StatisticsStorageKey.modeScoreTotalSpeedRun) private var modeScoreTotalSpeedRun = 0
    @AppStorage(StatisticsStorageKey.modeScoreTotalBigBox) private var modeScoreTotalBigBox = 0
    @AppStorage(StatisticsStorageKey.modeScoreTotalBigBoxSpeed) private var modeScoreTotalBigBoxSpeed = 0
    @AppStorage(StatisticsStorageKey.modeScoreCountQuickGame) private var modeScoreCountQuickGame = 0
    @AppStorage(StatisticsStorageKey.modeScoreCountClassic) private var modeScoreCountClassic = 0
    @AppStorage(StatisticsStorageKey.modeScoreCountSpeedRun) private var modeScoreCountSpeedRun = 0
    @AppStorage(StatisticsStorageKey.modeScoreCountBigBox) private var modeScoreCountBigBox = 0
    @AppStorage(StatisticsStorageKey.modeScoreCountBigBoxSpeed) private var modeScoreCountBigBoxSpeed = 0

    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.defaultTheme.rawValue

    @State private var showResetConfirm = false

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .defaultTheme)
    }

    var body: some View {
        CompatibleNavigationContainer {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    summaryGrid

                    bestScoresByModeSection
                    averageScoresByModeSection

                    statsSection(title: "Streaks & Length", rows: [
                        ("Current win streak", "\(currentWinStreak)"),
                        ("Best win streak",    "\(bestWinStreak)"),
                        ("Longest game",       movesText(longestGameTurns)),
                        ("Fewest moves to win",     movesText(shortestClearTurns)),
                    ])

                    remainingTilesSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .compatibleHiddenScrollBackground()
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
                        .compatibleSemibold()
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
            StatCard(title: "Played",  value: "\(gamesPlayed)",  theme: theme)
            StatCard(title: "Won",     value: "\(gamesWon)",     theme: theme)
            StatCard(title: "Lost",    value: "\(losses)",       theme: theme)
            StatCard(title: "Perfect", value: "\(perfectClears)", theme: theme)
        }
    }

    // MARK: - Best / average scores by mode

    /// A mode label that always makes clear whether its score includes time,
    /// since Speed Run / Big Box Speed scores are not comparable to the
    /// untimed modes.
    private func modeLabel(_ mode: GameMode) -> String {
        mode.isTimed ? L10n.format("%@ (+ time)", mode.title) : mode.title
    }

    private var bestScoresByModeSection: some View {
        statsSection(title: "Best Score by Mode", rows: [
            (modeLabel(.quickGame),   bestText(bestScoreQuickGame, storageKey: StatisticsStorageKey.bestScoreQuickGame)),
            (modeLabel(.classic),     bestText(bestScoreClassic, storageKey: StatisticsStorageKey.bestScoreClassic)),
            (modeLabel(.speedRun),    bestText(bestScoreSpeedRun, storageKey: StatisticsStorageKey.bestScoreSpeedRun)),
            (modeLabel(.bigBox),      bestText(bestScoreBigBox, storageKey: StatisticsStorageKey.bestScoreBigBox)),
            (modeLabel(.bigBoxSpeed), bestText(bestScoreBigBoxSpeed, storageKey: StatisticsStorageKey.bestScoreBigBoxSpeed)),
        ])
    }

    /// Per-mode average score. Unlike the old combined average (removed —
    /// it mixed board sizes and timed/untimed modes), these start counting
    /// from games recorded after this update; a caption below the section
    /// says so, since old combined totals can't be split by mode after
    /// the fact.
    private var averageScoresByModeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            statsSection(title: "Average Score by Mode", rows: [
                (modeLabel(.quickGame),   averageText(total: modeScoreTotalQuickGame, count: modeScoreCountQuickGame)),
                (modeLabel(.classic),     averageText(total: modeScoreTotalClassic, count: modeScoreCountClassic)),
                (modeLabel(.speedRun),    averageText(total: modeScoreTotalSpeedRun, count: modeScoreCountSpeedRun)),
                (modeLabel(.bigBox),      averageText(total: modeScoreTotalBigBox, count: modeScoreCountBigBox)),
                (modeLabel(.bigBoxSpeed), averageText(total: modeScoreTotalBigBoxSpeed, count: modeScoreCountBigBoxSpeed)),
            ])
            Text(L10n.string("Averages count games played after this update."))
                .font(GameTypography.caption(size: 11))
                .foregroundStyle(theme.text.opacity(0.48))
                .padding(.horizontal, 4)
        }
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

    private func averageText(total: Int, count: Int) -> String {
        guard count > 0 else { return "-" }
        return formattedAverage(total, count: count)
    }

    private func resetStats() {
        gamesPlayed = 0; gamesWon = 0
        perfectClears = 0; currentWinStreak = 0; bestWinStreak = 0
        losses = 0
        longestGameTurns = 0; shortestClearTurns = 0; remainingTileCounts = ""
        bestScoreQuickGame = 0; bestScoreClassic = 0; bestScoreSpeedRun = 0; bestScoreBigBox = 0; bestScoreBigBoxSpeed = 0
        modeScoreTotalQuickGame = 0; modeScoreTotalClassic = 0; modeScoreTotalSpeedRun = 0; modeScoreTotalBigBox = 0; modeScoreTotalBigBoxSpeed = 0
        modeScoreCountQuickGame = 0; modeScoreCountClassic = 0; modeScoreCountSpeedRun = 0; modeScoreCountBigBox = 0; modeScoreCountBigBoxSpeed = 0
        [StatisticsStorageKey.bestScoreQuickGame,
         StatisticsStorageKey.bestScoreClassic,
         StatisticsStorageKey.bestScoreSpeedRun,
         StatisticsStorageKey.bestScoreBigBox,
         StatisticsStorageKey.bestScoreBigBoxSpeed,
         // Old combined fields are no longer read or written by this view,
         // but "Reset" is an explicit user action and should still clear them.
         StatisticsStorageKey.bestScore,
         StatisticsStorageKey.totalScore,
         StatisticsStorageKey.winningScoreTotal,
         StatisticsStorageKey.losingScoreTotal].forEach { UserDefaults.standard.removeObject(forKey: $0) }
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

    private func bestText(_ score: Int, storageKey: String) -> String {
        UserDefaults.standard.object(forKey: storageKey) == nil ? "-" : "\(score)"
    }

    private func formattedAverage(_ total: Int, count: Int) -> String {
        let average = Double(total) / Double(count)
        // BOD-013: honor the in-app language override (L10n.locale), not just
        // the device locale — otherwise a manually selected language would
        // still show the device's decimal separator.
        return average.formatted(.number.precision(.fractionLength(1)).locale(L10n.locale))
    }

    private func movesText(_ moves: Int) -> String {
        guard moves > 0 else { return "-" }
        return L10n.format(moves == 1 ? "%d move" : "%d moves", moves)
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
