//
//  WatchSupportViews.swift
//  BoxOfDice Watch App
//

import SwiftUI

struct WatchModeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsStorageKey.gameMode) private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.passAndPlayPlayerCount) private var playerCount = 2
    @AppStorage(SettingsStorageKey.watchTheme) private var watchThemeRawValue = GameThemeName.classicWood.rawValue

    let onStart: (GameMode, Int) -> Void

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: watchThemeRawValue) ?? .classicWood)
    }

    private var selectedMode: GameMode {
        GameMode(rawValue: gameModeRaw) ?? .classic
    }

    var body: some View {
        NavigationView {
            ZStack {
                WatchBackground(theme: theme).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(GameMode.allCases.filter { $0 != .bigBox && $0 != .bigBoxSpeed }) { mode in
                            modeButton(mode)
                        }

                        if selectedMode.isMultiplayer {
                            playerCountPicker
                        }

                        Button(action: start) {
                            Label("Start", systemImage: "play.fill")
                                .font(GameTypography.button(size: 16))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Mode")
        }
    }

    private func modeButton(_ mode: GameMode) -> some View {
        Button { gameModeRaw = mode.rawValue } label: {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.title)
                        .font(GameTypography.label(size: 15))
                        .foregroundStyle(theme.text)
                    Text(mode.subtitle)
                        .font(GameTypography.caption(size: 10))
                        .foregroundStyle(theme.text.opacity(0.58))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selectedMode == mode ? theme.accent : theme.text.opacity(0.35))
            }
            .padding(8)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private var playerCountPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Players")
                .font(GameTypography.section(size: 11))
                .foregroundStyle(theme.text.opacity(0.65))
            Picker("Players", selection: $playerCount) {
                ForEach(2...4, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .labelsHidden()
        }
        .padding(8)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 9))
    }

    private func start() {
        onStart(selectedMode, playerCount)
        dismiss()
    }
}

struct WatchSettingsView: View {
    var onModeChanged: ((GameMode) -> Void)? = nil

    @AppStorage(SettingsStorageKey.gameMode) private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.watchTheme) private var watchThemeRawValue = GameThemeName.classicWood.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    @AppStorage(SettingsStorageKey.undoEnabled) private var undoEnabled = true
    @AppStorage(SettingsStorageKey.leftHandedLayout) private var leftHandedLayout = false

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: watchThemeRawValue) ?? .classicWood)
    }

    private var currentMode: GameMode {
        let mode = GameMode(rawValue: gameModeRaw) ?? .classic
        return (mode == .bigBox || mode == .bigBoxSpeed) ? .classic : mode
    }

    var body: some View {
        NavigationView {
            ZStack {
                WatchBackground(theme: theme).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        modePickerRow
                        themePickerRow
                        toggleRow("Haptics & Sound", isOn: $hapticsEnabled)
                        dicePickerRow
                        toggleRow("Hints", isOn: $showHints)
                        toggleRow("Undo", isOn: $undoEnabled)
                        toggleRow("Left hand", isOn: $leftHandedLayout)
                        statsRow
                    }
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Settings")
            .onChange(of: gameModeRaw) { newValue in
                let mode = GameMode(rawValue: newValue) ?? .classic
                onModeChanged?(mode)
            }
        }
    }

    private var statsRow: some View {
        NavigationLink {
            WatchStatsView()
        } label: {
            HStack {
                Text("Statistics")
                    .font(GameTypography.label(size: 14))
                    .foregroundStyle(theme.text)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.text.opacity(0.35))
            }
        }
        .buttonStyle(.plain)
        .watchCard(theme: theme)
    }

    private var modePickerRow: some View {
        return navPickerRow(title: "Mode", valueLabel: currentMode.title) {
            ForEach(GameMode.allCases.filter { $0 != .bigBox && $0 != .bigBoxSpeed }) { mode in
                selectionButton(label: mode.title, isSelected: currentMode == mode) {
                    gameModeRaw = mode.rawValue
                }
            }
        }
    }

    private var themePickerRow: some View {
        let current = GameThemeName(rawValue: watchThemeRawValue) ?? .classicWood
        return navPickerRow(title: "Theme", valueLabel: current.title) {
            ForEach(GameThemeName.allCases) { name in
                selectionButton(label: name.title, isSelected: current == name) {
                    watchThemeRawValue = name.rawValue
                }
            }
        }
    }

    private var dicePickerRow: some View {
        let current = DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal
        return navPickerRow(title: "Dice", valueLabel: current.title) {
            ForEach(DiceAnimationSpeed.allCases) { speed in
                selectionButton(label: speed.title, isSelected: current == speed) {
                    diceAnimationSpeedRawValue = speed.rawValue
                }
            }
        }
    }

    private func navPickerRow<Content: View>(title: String, valueLabel: String, @ViewBuilder options: () -> Content) -> some View {
        NavigationLink {
            List { options() }
                .navigationTitle(title)
        } label: {
            HStack {
                Text(title)
                    .font(GameTypography.label(size: 14))
                    .foregroundStyle(theme.text)
                Spacer()
                Text(valueLabel)
                    .font(GameTypography.label(size: 13))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.text.opacity(0.35))
            }
        }
        .buttonStyle(.plain)
        .watchCard(theme: theme)
    }

    private func selectionButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(GameTypography.label(size: 15))
                    .foregroundStyle(isSelected ? theme.accent : theme.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(GameTypography.label(size: 14))
                .foregroundStyle(theme.text)
        }
        .tint(theme.accent)
        .watchCard(theme: theme)
    }
}

struct WatchStatsView: View {
    @AppStorage(StatisticsStorageKey.gamesPlayed) private var gamesPlayed = 0
    @AppStorage(StatisticsStorageKey.gamesWon) private var gamesWon = 0
    @AppStorage(StatisticsStorageKey.bestScore) private var bestScore = 0
    @AppStorage(StatisticsStorageKey.totalScore) private var totalScore = 0
    @AppStorage(StatisticsStorageKey.perfectClears) private var perfectClears = 0
    @AppStorage(StatisticsStorageKey.currentWinStreak) private var currentWinStreak = 0
    @AppStorage(StatisticsStorageKey.bestWinStreak) private var bestWinStreak = 0
    @AppStorage(StatisticsStorageKey.longestGameTurns) private var longestGameTurns = 0
    @AppStorage(StatisticsStorageKey.shortestClearTurns) private var shortestClearTurns = 0
    @AppStorage(StatisticsStorageKey.bestScoreClassic) private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun) private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox) private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed) private var bestScoreBigBoxSpeed = 0
    @AppStorage(StatisticsStorageKey.winningScoreTotal) private var winningScoreTotal = 0
    @AppStorage(StatisticsStorageKey.losingScoreTotal) private var losingScoreTotal = 0
    @AppStorage(StatisticsStorageKey.losses) private var losses = 0
    @AppStorage(StatisticsStorageKey.remainingTileCounts) private var remainingTileCounts = ""
    @AppStorage(SettingsStorageKey.watchTheme) private var watchThemeRawValue = GameThemeName.classicWood.rawValue

    @State private var showResetConfirm = false

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: watchThemeRawValue) ?? .classicWood)
    }

    var body: some View {
        NavigationView {
            ZStack {
                WatchBackground(theme: theme).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        statRow("Played", "\(gamesPlayed)")
                        statRow("Won", "\(gamesWon)")
                        statRow("Best", bestText(bestScore, requiresGames: true))
                        statRow("Average", averageScoreText)
                        statRow("Perfect", "\(perfectClears)")
                        statRow("Streak", "\(currentWinStreak) / \(bestWinStreak)")
                        statRow("Longest", turnsText(longestGameTurns))
                        statRow("Shortest", turnsText(shortestClearTurns))
                        statRow(GameMode.classic.title, bestText(bestScoreClassic))
                        statRow(GameMode.speedRun.title, bestText(bestScoreSpeedRun))

                        Button("Reset Stats") { showResetConfirm = true }
                            .buttonStyle(WatchDestructiveButtonStyle())
                    }
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Stats")
            .confirmationDialog("Reset all statistics?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { resetStats() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func resetStats() {
        gamesPlayed = 0; gamesWon = 0; bestScore = 0; totalScore = 0
        perfectClears = 0; currentWinStreak = 0; bestWinStreak = 0
        winningScoreTotal = 0; losingScoreTotal = 0; losses = 0
        longestGameTurns = 0; shortestClearTurns = 0; remainingTileCounts = ""
        bestScoreClassic = 0; bestScoreSpeedRun = 0; bestScoreBigBox = 0; bestScoreBigBoxSpeed = 0
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(GameTypography.label(size: 13))
                .foregroundStyle(theme.text.opacity(0.76))
            Spacer(minLength: 4)
            Text(value)
                .font(GameTypography.value(size: 14))
                .foregroundStyle(theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .watchCard(theme: theme)
    }

    private var averageScoreText: String {
        guard gamesPlayed > 0 else { return "-" }
        let average = Double(totalScore) / Double(gamesPlayed)
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    private func bestText(_ value: Int, requiresGames: Bool = false) -> String {
        if requiresGames && gamesPlayed == 0 { return "-" }
        return value == 0 ? "-" : "\(value)"
    }

    private func turnsText(_ value: Int) -> String {
        value == 0 ? "-" : "\(value)"
    }
}

struct WatchGameOverView: View {
    let won: Bool
    let tileScore: Int
    let elapsedSeconds: Int
    let isTimed: Bool
    let remainingOpenTiles: [Int]
    let theme: GameTheme
    let onNewGame: () -> Void
    let onStats: () -> Void

    private var finalScore: Int {
        tileScore + (isTimed ? elapsedSeconds : 0)
    }

    private var openTilesText: String {
        remainingOpenTiles.map(String.init).joined(separator: "  ")
    }

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                let scale = min(max(proxy.size.height / 198, 0.82), 1.12)
                let pad = max(6, 8 * scale)
                let spacing = max(7, 9 * scale)
                let iconSize = min(max(26, proxy.size.height * 0.15), 36)
                let scoreSize = min(max(42, proxy.size.height * 0.24), 56)
                let captionSize = min(max(10, proxy.size.height * 0.052), 12)
                let primaryHeight = min(max(32, proxy.size.height * 0.17), 40)

                ZStack {
                    WatchBackground(theme: theme).ignoresSafeArea()

                    VStack(spacing: spacing) {
                        Image(systemName: won ? "checkmark.seal.fill" : "xmark.octagon.fill")
                            .font(.system(size: iconSize, weight: .bold))
                            .foregroundStyle(won ? Color.green : Color(red: 1.0, green: 0.42, blue: 0.18))

                        VStack(spacing: 2) {
                            Text("\(finalScore)")
                                .font(GameTypography.display(size: scoreSize))
                                .foregroundStyle(theme.accent)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            if remainingOpenTiles.isEmpty {
                                Text(won ? "Perfect clear!" : "All tiles closed")
                                    .font(.system(size: captionSize, weight: .medium))
                                    .foregroundStyle(Color.green.opacity(0.85))
                            } else {
                                Text("Open: \(openTilesText)")
                                    .font(.system(size: captionSize, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.text.opacity(0.65))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, max(6, 7 * scale))
                        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(theme.accent.opacity(0.30), lineWidth: 0.8))

                        Button(action: onNewGame) {
                            Label("New Game", systemImage: "arrow.clockwise")
                                .font(.system(size: min(captionSize + 2, 14), weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: primaryHeight)
                        }
                        .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))

                        NavigationLink {
                            WatchStatsView()
                        } label: {
                            Text("Stats")
                                .font(.system(size: captionSize, weight: .medium))
                                .foregroundStyle(theme.text.opacity(0.58))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, pad)
                    .padding(.vertical, pad)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}

struct WatchPassAndPlayRoundEndView: View {
    let playerNumber: Int
    let tileScore: Int
    let isLastPlayer: Bool
    let theme: GameTheme
    let onNext: () -> Void
    let onResults: () -> Void

    var body: some View {
        ZStack {
            WatchBackground(theme: theme).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("Player \(playerNumber)")
                    .font(GameTypography.title(size: 22))
                    .foregroundStyle(theme.text)
                Text("\(tileScore)")
                    .font(GameTypography.display(size: 40))
                    .foregroundStyle(theme.accent)
                Text(isLastPlayer ? "All players done" : "Pass to next player")
                    .font(GameTypography.caption(size: 12))
                    .foregroundStyle(theme.text.opacity(0.65))
                    .multilineTextAlignment(.center)
                Button(isLastPlayer ? "Results" : "Next", action: isLastPlayer ? onResults : onNext)
                    .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))
            }
            .padding(.horizontal, 4)
        }
    }
}

struct WatchPassAndPlayResultsView: View {
    let scores: [Int]
    let theme: GameTheme
    let onNewGame: () -> Void

    private var sortedResults: [(player: Int, score: Int)] {
        scores.enumerated()
            .map { (player: $0.offset + 1, score: $0.element) }
            .sorted { $0.score < $1.score }
    }

    var body: some View {
        ZStack {
            WatchBackground(theme: theme).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    Text("Results")
                        .font(GameTypography.title(size: 22))
                        .foregroundStyle(theme.text)
                    ForEach(Array(sortedResults.enumerated()), id: \.element.player) { index, result in
                        HStack {
                            Text("\(index + 1). P\(result.player)")
                            Spacer()
                            Text("\(result.score)")
                        }
                        .font(GameTypography.value(size: 14))
                        .foregroundStyle(index == 0 ? theme.accent : theme.text)
                        .watchCard(theme: theme)
                    }
                    Button("New Game", action: onNewGame)
                        .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))
                }
                .padding(.bottom, 10)
            }
        }
    }
}

struct WatchBackground: View {
    let theme: GameTheme

    var body: some View {
        LinearGradient(colors: theme.surface, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(Color.black.opacity(0.16))
    }
}

struct WatchDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GameTypography.button(size: 14))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundStyle(Color.white.opacity(0.90))
            .background(Color.red.opacity(configuration.isPressed ? 0.50 : 0.32), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.red.opacity(0.45), lineWidth: 0.7))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct WatchSheetPrimaryButtonStyle: ButtonStyle {
    let theme: GameTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GameTypography.button(size: 15))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(Color.black.opacity(0.82))
            .background(LinearGradient(colors: theme.button, startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension View {
    func watchCard(theme: GameTheme) -> some View {
        self
            .padding(8)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }
}
