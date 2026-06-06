//
//  ContentView.swift
//  BoxOfDice
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var isShowingSettings = false
    @State private var isShowingStats = false
    @State private var didApplyInitialSettings = false

    @AppStorage(SettingsStorageKey.tileCount) private var tileCount = GameSettings.default.tileCount
    @AppStorage(SettingsStorageKey.diceMode) private var diceModeRawValue = GameSettings.default.diceMode.rawValue
    @AppStorage(SettingsStorageKey.moveRule) private var moveRuleRawValue = GameSettings.default.moveRule.rawValue
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.classicWood.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.confirmBehavior) private var confirmBehaviorRawValue = ConfirmBehavior.manual.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    @AppStorage(SettingsStorageKey.undoEnabled) private var undoEnabled = true
    @AppStorage(SettingsStorageKey.leftHandedLayout) private var leftHandedLayout = false
    @AppStorage(SettingsStorageKey.challengeMode) private var challengeModeRawValue = ChallengeMode.normal.rawValue
    @AppStorage(SettingsStorageKey.challengeSeed) private var challengeSeed = ""

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

    private let horizontalPadding: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                WoodBackground(colors: theme.background)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: spacing(for: proxy.size.height)) {
                        headerView
                            .padding(.top, max(18, proxy.safeAreaInsets.top + 10))

                        boardView(width: proxy.size.width - horizontalPadding * 2)

                        diceSection

                        gameTools

                        moveHistorySummary

                        actionButton
                            .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
                    }
                    .frame(maxWidth: 430)
                    .padding(.horizontal, horizontalPadding)
                    .frame(maxWidth: .infinity)
                }

                if case .gameOver(let won) = viewModel.gameState {
                    Color.black.opacity(0.56)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    GameOverView(
                        won: won,
                        score: viewModel.score,
                        remainingOpenTiles: viewModel.remainingOpenTiles,
                        onNewGame: startNewGame
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            guard !didApplyInitialSettings else { return }
            didApplyInitialSettings = true
            configureViewModel()
            viewModel.newGame(settings: currentSettings, seed: currentSeed)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingStats) {
            StatsView()
        }
        .onChange(of: viewModel.gameState) { _, newState in
            if case .gameOver(let won) = newState {
                recordCompletedGame(won: won)
            }
        }
        .onChange(of: confirmBehaviorRawValue) { _, _ in configureViewModel() }
        .onChange(of: diceAnimationSpeedRawValue) { _, _ in configureViewModel() }
        .onChange(of: hapticsEnabled) { _, _ in configureViewModel() }
        .onChange(of: soundsEnabled) { _, _ in configureViewModel() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.gameState)
    }

    private var currentSettings: GameSettings {
        GameSettings(
            tileCount: tileCount,
            diceModeRawValue: diceModeRawValue,
            moveRuleRawValue: moveRuleRawValue
        )
    }

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
    }

    private var confirmBehavior: ConfirmBehavior {
        ConfirmBehavior(rawValue: confirmBehaviorRawValue) ?? .manual
    }

    private var diceAnimationSpeed: DiceAnimationSpeed {
        DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal
    }

    private var challengeMode: ChallengeMode {
        ChallengeMode(rawValue: challengeModeRawValue) ?? .normal
    }

    private var currentSeed: UInt64? {
        switch challengeMode {
        case .normal:
            return nil
        case .daily:
            let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
            return UInt64(day)
        case .customSeed:
            return stableSeed(from: challengeSeed)
        }
    }

    private var headerView: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                Text("Box of Dice")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: theme.title,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 2)
                    .minimumScaleFactor(0.8)

                Text("Score: \(viewModel.score)")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(theme.text)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: viewModel.score)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            HStack {
                if leftHandedLayout {
                    headerIconButton(systemName: "gearshape.fill", label: "Settings") {
                        isShowingSettings = true
                    }
                    Spacer()
                    headerIconButton(systemName: "chart.bar.fill", label: "Statistics") {
                        isShowingStats = true
                    }
                } else {
                    headerIconButton(systemName: "chart.bar.fill", label: "Statistics") {
                        isShowingStats = true
                    }
                    Spacer()
                    headerIconButton(systemName: "gearshape.fill", label: "Settings") {
                        isShowingSettings = true
                    }
                }
            }
        }
    }

    private func headerIconButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.58))
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.18), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func boardView(width: CGFloat) -> some View {
        let availableWidth = min(width, 430)
        let columnsCount = viewModel.tiles.count > 10 ? 6 : 5
        let tileSpacing: CGFloat = 8
        let tileWidth = min(56, (availableWidth - 44 - tileSpacing * CGFloat(columnsCount - 1)) / CGFloat(columnsCount))
        let tileHeight = tileWidth * 1.22
        let columns = Array(repeating: GridItem(.fixed(tileWidth), spacing: tileSpacing), count: columnsCount)

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.tiles) { tile in
                tileButton(for: tile)
                    .frame(width: tileWidth, height: tileHeight)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.board[0],
                            theme.board[1],
                            theme.board[2]
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(WoodGrain().clipShape(RoundedRectangle(cornerRadius: 22)).opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color(red: 0.24, green: 0.11, blue: 0.04), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.36), radius: 16, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                .padding(8)
        )
    }

    private func tileButton(for tile: Tile) -> some View {
        TileView(
            number: tile.id,
            isOpen: tile.isOpen,
            isSelected: viewModel.selectedTiles.contains(tile.id) || viewModel.highlightedHint.contains(tile.id),
            isEnabled: viewModel.canSelectTiles,
            onTap: { viewModel.toggleTile(tile.id) }
        )
    }

    private var diceSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 26) {
                DiceView(value: viewModel.dice.0, isRolling: viewModel.isRolling)
                if viewModel.dieCount == 2 {
                    DiceView(value: viewModel.dice.1, isRolling: viewModel.isRolling)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: viewModel.dieCount)

            if viewModel.hasRolled {
                VStack(spacing: 6) {
                    Text("Total: \(viewModel.diceTotal)")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(theme.text)
                        .contentTransition(.numericText())
                        .animation(.spring(), value: viewModel.diceTotal)

                    selectionFeedback
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.25), value: viewModel.hasRolled)
            }
        }
    }

    private var gameTools: some View {
        HStack(spacing: 12) {
            if showHints {
                Button(action: viewModel.showHint) {
                    Label("Hint", systemImage: "lightbulb.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(width: 104, height: 42)
                }
                .buttonStyle(ToolButtonStyle(isEnabled: viewModel.canSelectTiles, accent: theme.accent))
                .disabled(!viewModel.canSelectTiles)
            }

            if undoEnabled {
                Button(action: viewModel.undoLastMove) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(width: 104, height: 42)
                }
                .buttonStyle(ToolButtonStyle(isEnabled: viewModel.canUndo, accent: theme.accent))
                .disabled(!viewModel.canUndo)
            }
        }
        .frame(minHeight: (showHints || undoEnabled) ? 42 : 0)
    }

    @ViewBuilder
    private var moveHistorySummary: some View {
        if let lastMove = viewModel.moveHistory.last {
            Text("Last: rolled \(lastMove.diceTotal), closed \(lastMove.closedTiles.map(String.init).joined(separator: ", "))")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.text.opacity(0.78))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private var selectionFeedback: some View {
        let total = viewModel.selectionTotal
        let target = viewModel.diceTotal
        let isMatch = !viewModel.selectedTiles.isEmpty && total == target

        if case .selecting = viewModel.gameState {
            VStack(spacing: 3) {
                if viewModel.selectedTiles.isEmpty {
                    Text("Select tiles that add up to \(target)")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.58).opacity(0.9))
                } else {
                    Text("Selected: \(total) / \(target)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(isMatch ? Color(red: 0.45, green: 1.0, blue: 0.64) : Color(red: 1.0, green: 0.78, blue: 0.32))
                }

                Text("Possible moves: \(viewModel.possibleMoveCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.text.opacity(0.72))
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.gameState {
        case .waitingToRoll:
            Button(action: viewModel.rollDice) {
                Text(viewModel.isRolling ? "Rolling..." : "Roll Dice")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .frame(maxWidth: 240)
                    .frame(height: 54)
            }
            .buttonStyle(BoardGameButtonStyle(isEnabled: viewModel.canRoll, tint: .amber))
            .disabled(!viewModel.canRoll)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRolling)

        case .selecting:
            Button(action: viewModel.confirmSelection) {
                Text("Confirm")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .frame(maxWidth: 240)
                    .frame(height: 54)
            }
            .buttonStyle(BoardGameButtonStyle(isEnabled: viewModel.canConfirm && !viewModel.isRolling, tint: .green))
            .disabled(!viewModel.canConfirm || viewModel.isRolling)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canConfirm)

        case .gameOver:
            EmptyView()
        }
    }

    private func startNewGame() {
        configureViewModel()
        viewModel.newGame(settings: currentSettings, seed: currentSeed)
    }

    private func configureViewModel() {
        viewModel.configure(
            confirmBehavior: confirmBehavior,
            diceAnimationSpeed: diceAnimationSpeed,
            feedbackOptions: FeedbackOptions(hapticsEnabled: hapticsEnabled, soundsEnabled: soundsEnabled)
        )
    }

    private func stableSeed(from text: String) -> UInt64 {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        if let numericSeed = UInt64(trimmed) { return numericSeed }

        var hash: UInt64 = 1469598103934665603
        for byte in trimmed.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    private func recordCompletedGame(won: Bool) {
        let finalScore = viewModel.score
        let isFirstRecordedGame = gamesPlayed == 0

        gamesPlayed += 1
        totalScore += finalScore
        bestScore = isFirstRecordedGame ? finalScore : min(bestScore, finalScore)

        longestGameTurns = max(longestGameTurns, viewModel.turnCount)
        updateBestScoreByTileCount(finalScore)
        updateRemainingTileCounts(viewModel.remainingOpenTiles)

        if won {
            gamesWon += 1
            winningScoreTotal += finalScore
            perfectClears += finalScore == 0 ? 1 : 0
            currentWinStreak += 1
            bestWinStreak = max(bestWinStreak, currentWinStreak)
            shortestClearTurns = shortestClearTurns == 0 ? viewModel.turnCount : min(shortestClearTurns, viewModel.turnCount)
        } else {
            losses += 1
            losingScoreTotal += finalScore
            currentWinStreak = 0
        }
    }

    private func updateBestScoreByTileCount(_ finalScore: Int) {
        switch tileCount {
        case 9:
            bestScore9 = bestScore9 == 0 ? finalScore : min(bestScore9, finalScore)
        case 10:
            bestScore10 = bestScore10 == 0 ? finalScore : min(bestScore10, finalScore)
        default:
            bestScore12 = bestScore12 == 0 ? finalScore : min(bestScore12, finalScore)
        }
    }

    private func updateRemainingTileCounts(_ tiles: [Int]) {
        var counts = parseRemainingTileCounts()
        for tile in tiles {
            counts[tile, default: 0] += 1
        }
        remainingTileCounts = counts
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")
    }

    private func parseRemainingTileCounts() -> [Int: Int] {
        var counts: [Int: Int] = [:]
        for pair in remainingTileCounts.split(separator: ",") {
            let parts = pair.split(separator: ":")
            guard parts.count == 2, let tile = Int(parts[0]), let count = Int(parts[1]) else { continue }
            counts[tile] = count
        }
        return counts
    }

    private func spacing(for height: CGFloat) -> CGFloat {
        height < 700 ? 18 : 28
    }
}

private struct WoodBackground: View {
    let colors: [Color]

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(WoodGrain().opacity(0.35))
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.16), Color.black.opacity(0.22)],
                center: .top,
                startRadius: 80,
                endRadius: 620
            )
        )
    }
}

private struct WoodGrain: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let lineCount = Int(max(size.width, size.height) / 10)
                for index in 0...lineCount {
                    var path = Path()
                    let y = CGFloat(index) * 10
                    path.move(to: CGPoint(x: -20, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width + 20, y: y + CGFloat((index % 5) - 2) * 5),
                        control1: CGPoint(x: size.width * 0.28, y: y - 7),
                        control2: CGPoint(x: size.width * 0.68, y: y + 9)
                    )
                    context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct ToolButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? accent : Color.gray.opacity(0.8))
            .background(Color.black.opacity(isEnabled ? 0.18 : 0.10), in: RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.18 : 0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

private struct BoardGameButtonStyle: ButtonStyle {
    enum Tint {
        case amber
        case green
    }

    let isEnabled: Bool
    let tint: Tint

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.32 : 0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isEnabled ? 0.28 : 0.08), radius: 8, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.58)
    }

    private var backgroundGradient: LinearGradient {
        guard isEnabled else {
            return LinearGradient(colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.28)], startPoint: .top, endPoint: .bottom)
        }

        switch tint {
        case .amber:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.37), Color(red: 0.88, green: 0.50, blue: 0.12)], startPoint: .top, endPoint: .bottom)
        case .green:
            return LinearGradient(colors: [Color(red: 0.60, green: 0.90, blue: 0.45), Color(red: 0.25, green: 0.58, blue: 0.26)], startPoint: .top, endPoint: .bottom)
        }
    }
}

#Preview {
    ContentView()
}
