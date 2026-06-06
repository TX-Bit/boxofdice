//
//  ContentView.swift
//  BoxOfDice
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var isShowingSettings = false
    @State private var isShowingStats = false
    @State private var isShowingModeSelection = false
    @State private var didApplyInitialSettings = false
    @State private var isGameOverVisible = false

    // Pass & Play state
    @State private var currentPassAndPlayPlayer = 0
    @State private var passAndPlayScores: [Int] = []
    @State private var passAndPlayPlayerCount = 2
    @State private var isShowingPassAndPlayResults = false

    @AppStorage(SettingsStorageKey.gameMode) private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.classicWood.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    @AppStorage(SettingsStorageKey.undoEnabled) private var undoEnabled = true
    @AppStorage(SettingsStorageKey.leftHandedLayout) private var leftHandedLayout = false

    // Global stats
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

    // Per-mode best scores
    @AppStorage(StatisticsStorageKey.bestScoreClassic) private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun) private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox) private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed) private var bestScoreBigBoxSpeed = 0

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

                        VStack(spacing: 10) {
                            actionButton
                            secondaryToolBar
                            moveHistorySummary
                        }
                        .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
                    }
                    .frame(maxWidth: 430)
                    .padding(.horizontal, horizontalPadding)
                    .frame(maxWidth: .infinity)
                }

                if isGameOverVisible, case .gameOver(let won) = viewModel.gameState {
                    Color.black.opacity(0.56)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    if currentGameMode.isMultiplayer {
                        multiplayerOverlay
                    } else {
                        GameOverView(
                            won: won,
                            tileScore: viewModel.score,
                            elapsedSeconds: viewModel.elapsedSeconds,
                            isTimed: currentGameMode.isTimed,
                            remainingOpenTiles: viewModel.remainingOpenTiles,
                            theme: theme,
                            onNewGame: { isShowingModeSelection = true },
                            onSettings: { isShowingSettings = true },
                            onStats: { isShowingStats = true }
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            guard !didApplyInitialSettings else { return }
            didApplyInitialSettings = true
            configureViewModel()
            viewModel.newGame(settings: currentSettings, isTimed: currentGameMode.isTimed)
        }
        .sheet(isPresented: $isShowingModeSelection) {
            GameModeSelectionView { mode, playerCount in
                startNewGame(mode: mode, playerCount: playerCount)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingStats) {
            StatsView()
        }
        .onChange(of: viewModel.gameState) { newState in
            if case .gameOver(let won) = newState {
                handleGameOver(won: won)
                let delay: UInt64 = won ? 700_000_000 : 1_500_000_000
                if currentGameMode.isMultiplayer {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isGameOverVisible = true
                    }
                } else {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: delay)
                        guard case .gameOver = viewModel.gameState else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isGameOverVisible = true
                        }
                    }
                }
            } else {
                isGameOverVisible = false
            }
        }
        .onChange(of: diceAnimationSpeedRawValue) { _ in configureViewModel() }
        .onChange(of: hapticsEnabled) { _ in configureViewModel() }
        .onChange(of: soundsEnabled) { _ in configureViewModel() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.gameState)
    }

    // MARK: - Multiplayer overlay

    @ViewBuilder
    private var multiplayerOverlay: some View {
        if isShowingPassAndPlayResults {
            PassAndPlayResultsView(
                scores: passAndPlayScores,
                onNewGame: { isShowingModeSelection = true }
            )
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        } else {
            PassAndPlayRoundEndView(
                playerNumber: currentPassAndPlayPlayer + 1,
                tileScore: viewModel.score,
                isLastPlayer: currentPassAndPlayPlayer == passAndPlayPlayerCount - 1,
                onNext: advanceToNextPlayer,
                onResults: showPassAndPlayResults
            )
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }

    // MARK: - Computed

    private var currentGameMode: GameMode {
        GameMode(rawValue: gameModeRaw) ?? .classic
    }

    private var currentSettings: GameSettings {
        GameSettings.from(
            mode: currentGameMode,
            diceMode: .alwaysTwoDice,
            moveRule: .anyCombination
        )
    }

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
    }

    private var diceAnimationSpeed: DiceAnimationSpeed {
        DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 5) {
                Text("Box of Dice")
                    .font(GameTypography.title(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: theme.title, startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 2)
                    .minimumScaleFactor(0.8)

                headerScoreRow
                modePill
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            HStack {
                if leftHandedLayout {
                    headerIconButton(systemName: "gearshape.fill", label: "Settings") { isShowingSettings = true }
                    soundToggleButton
                    Spacer()
                    headerIconButton(systemName: "chart.bar.fill", label: "Statistics") { isShowingStats = true }
                } else {
                    headerIconButton(systemName: "chart.bar.fill", label: "Statistics") { isShowingStats = true }
                    Spacer()
                    soundToggleButton
                    headerIconButton(systemName: "gearshape.fill", label: "Settings") { isShowingSettings = true }
                }
            }
        }
    }

    @ViewBuilder
    private var headerScoreRow: some View {
        if currentGameMode.isTimed {
            HStack(spacing: 10) {
                Text("Tiles: \(viewModel.score)")
                    .animation(.spring(), value: viewModel.score)
                if viewModel.hasRolled {
                    Text("·")
                        .opacity(0.35)
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                        Text(formattedElapsedTime)
                            .monospacedDigit()
                    }
                }
            }
            .font(GameTypography.value(size: 21))
            .foregroundStyle(theme.text)
            .animation(.easeInOut(duration: 0.2), value: viewModel.hasRolled)
        } else {
            Text("Score: \(viewModel.score)")
                .font(GameTypography.value(size: 23))
                .foregroundStyle(theme.text)
                .animation(.spring(), value: viewModel.score)
        }
    }

    private var modePill: some View {
        Button { isShowingModeSelection = true } label: {
            HStack(spacing: 4) {
                Text(currentGameMode.title)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .font(GameTypography.caption(size: 12))
            .foregroundStyle(theme.text.opacity(0.68))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.22), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
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

    private var soundToggleButton: some View {
        Button {
            soundsEnabled.toggle()
            configureViewModel()
        } label: {
            Image(systemName: soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(soundsEnabled
                    ? Color(red: 1.0, green: 0.86, blue: 0.58)
                    : Color(red: 1.0, green: 0.86, blue: 0.58).opacity(0.38))
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.18), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(soundsEnabled ? "Mute sounds" : "Unmute sounds")
    }

    // MARK: - Board

    private func boardView(width: CGFloat) -> some View {
        let availableWidth = min(width, 430)
        let columnsCount = viewModel.tiles.count > 10 ? 6 : 5
        let tileSpacing: CGFloat = 8
        let frameThickness: CGFloat = 22
        let surfaceHorizontalPadding: CGFloat = 14
        let surfaceVerticalPadding: CGFloat = 16
        let fixedHorizontalSpace = frameThickness * 2 + surfaceHorizontalPadding * 2 + tileSpacing * CGFloat(columnsCount - 1)
        let tileWidth = min(54, (availableWidth - fixedHorizontalSpace) / CGFloat(columnsCount))
        let tileHeight = tileWidth * 1.22
        let gridWidth = tileWidth * CGFloat(columnsCount) + tileSpacing * CGFloat(columnsCount - 1)
        let trayWidth = gridWidth + surfaceHorizontalPadding * 2 + frameThickness * 2
        let columns = Array(repeating: GridItem(.fixed(tileWidth), spacing: tileSpacing), count: columnsCount)

        return LazyVGrid(columns: columns, spacing: 11) {
            ForEach(viewModel.tiles) { tile in
                tileButton(for: tile)
                    .frame(width: tileWidth, height: tileHeight)
            }
        }
        .frame(width: gridWidth)
        .padding(.horizontal, surfaceHorizontalPadding)
        .padding(.vertical, surfaceVerticalPadding)
        .background(WoodenTrayRecess())
        .padding(frameThickness)
        .frame(width: trayWidth)
        .background(WoodenTrayFrame(boardColors: theme.board))
        .rotation3DEffect(.degrees(7), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0.48)
        .scaleEffect(x: 1.0, y: 0.96, anchor: .center)
        .padding(.vertical, 5)
        .shadow(color: .black.opacity(0.60), radius: 22, x: 9, y: 18)
        .shadow(color: .black.opacity(0.24), radius: 5, x: 2, y: 4)
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

    // MARK: - Dice

    private var diceSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 26) {
                ForEach(0..<viewModel.dieCount, id: \.self) { index in
                    DiceView(value: viewModel.dice[index], isRolling: viewModel.isRolling)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: viewModel.dieCount)

            if viewModel.hasRolled {
                Text("Total: \(viewModel.diceTotal)")
                    .font(GameTypography.value(size: 25))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.hasRolled)
            }
        }
    }

    private var formattedElapsedTime: String {
        let s = viewModel.elapsedSeconds
        let minutes = s / 60
        let seconds = s % 60
        return minutes > 0
            ? "\(minutes):\(String(format: "%02d", seconds))"
            : "\(seconds)s"
    }

    // MARK: - Secondary tool bar (hint + undo)

    private var secondaryToolBar: some View {
        HStack {
            // Hint: only meaningful while selecting tiles
            if showHints {
                Button(action: viewModel.showHint) {
                    Label("Hint", systemImage: "lightbulb.fill")
                        .font(GameTypography.button(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                }
                .buttonStyle(ToolButtonStyle(isEnabled: viewModel.canSelectTiles, accent: theme.accent))
                .disabled(!viewModel.canSelectTiles)
                .opacity(viewModel.canSelectTiles ? 1 : 0)
            }

            Spacer()

            // Undo: plain text, low visual weight
            if undoEnabled {
                Button(action: viewModel.undoLastMove) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Undo")
                            .font(GameTypography.caption(size: 13))
                    }
                    .foregroundStyle(viewModel.canUndo
                        ? theme.text.opacity(0.50)
                        : theme.text.opacity(0.18))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canUndo)
            }
        }
        .frame(height: (showHints || undoEnabled) ? 30 : 0)
    }

    // MARK: - Move history

    @ViewBuilder
    private var moveHistorySummary: some View {
        if let lastMove = viewModel.moveHistory.last {
            Text("rolled \(lastMove.diceTotal)  ·  closed \(lastMove.closedTiles.map(String.init).joined(separator: ", "))")
                .font(GameTypography.caption(size: 11))
                .foregroundStyle(theme.text.opacity(0.30))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.gameState {
        case .waitingToRoll:
            rollButton
        case .selecting:
            selectingActionZone
        case .gameOver:
            EmptyView()
        }
    }

    private var rollButton: some View {
        Button(action: viewModel.rollDice) {
            HStack(spacing: 10) {
                if !viewModel.isRolling {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                Text(viewModel.isRolling ? "Rolling..." : "Roll Dice")
                    .font(GameTypography.button(size: 19))
            }
            .frame(maxWidth: 260)
            .frame(height: 58)
        }
        .buttonStyle(BoardGameButtonStyle(isEnabled: viewModel.canRoll, tint: .amber))
        .disabled(!viewModel.canRoll)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRolling)
    }

    private var selectingActionZone: some View {
        let total = viewModel.selectionTotal
        let target = viewModel.diceTotal
        let isMatch = viewModel.canConfirm
        let isEmpty = viewModel.selectedTiles.isEmpty

        return VStack(spacing: 8) {
            selectionStatusLabel(total: total, target: target, isMatch: isMatch, isEmpty: isEmpty)

            Button(action: viewModel.confirmSelection) {
                HStack(spacing: 8) {
                    if isMatch {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                    }
                    Text("Confirm")
                        .font(GameTypography.button(size: 19))
                }
                .frame(maxWidth: 260)
                .frame(height: 58)
            }
            .buttonStyle(BoardGameButtonStyle(isEnabled: isMatch, tint: .green))
            .disabled(!isMatch)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isMatch)
        }
    }

    private func selectionStatusLabel(total: Int, target: Int, isMatch: Bool, isEmpty: Bool) -> some View {
        Group {
            if isEmpty {
                Text("Select tiles that sum to \(target)")
                    .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.58).opacity(0.92))
            } else if isMatch {
                Label("\(total) of \(target) — Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.40, green: 0.96, blue: 0.60))
            } else {
                let diff = target - total
                Text(diff > 0 ? "Need \(diff) more  ·  \(total) / \(target)" : "Over by \(-diff)  ·  \(total) / \(target)")
                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.32))
            }
        }
        .font(GameTypography.label(size: 16))
        .multilineTextAlignment(.center)
        .animation(.easeInOut(duration: 0.15), value: isMatch)
        .animation(.easeInOut(duration: 0.15), value: isEmpty)
    }

    // MARK: - Game flow

    private func startNewGame(mode: GameMode, playerCount: Int = 2) {
        gameModeRaw = mode.rawValue

        if mode.isMultiplayer {
            passAndPlayPlayerCount = playerCount
            currentPassAndPlayPlayer = 0
            passAndPlayScores = []
            isShowingPassAndPlayResults = false
        }

        configureViewModel()
        viewModel.newGame(settings: currentSettings, isTimed: mode.isTimed)
    }

    private func advanceToNextPlayer() {
        passAndPlayScores.append(viewModel.score)
        currentPassAndPlayPlayer += 1
        configureViewModel()
        viewModel.newGame(settings: currentSettings, isTimed: false)
    }

    private func showPassAndPlayResults() {
        passAndPlayScores.append(viewModel.score)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowingPassAndPlayResults = true
        }
    }

    private func configureViewModel() {
        viewModel.configure(
            diceAnimationSpeed: diceAnimationSpeed,
            feedbackOptions: FeedbackOptions(hapticsEnabled: hapticsEnabled, soundsEnabled: soundsEnabled),
            isTimed: currentGameMode.isTimed
        )
    }

    private func handleGameOver(won: Bool) {
        // Don't record stats for multiplayer — results screen handles that
        guard !currentGameMode.isMultiplayer else { return }
        recordCompletedGame(won: won)
    }

    // MARK: - Statistics

    private func recordCompletedGame(won: Bool) {
        let baseScore = viewModel.score
        let finalScore = currentGameMode.finalScore(baseScore: baseScore, elapsedSeconds: viewModel.elapsedSeconds)
        let isFirstGame = gamesPlayed == 0

        gamesPlayed += 1
        totalScore += finalScore
        bestScore = isFirstGame ? finalScore : min(bestScore, finalScore)

        longestGameTurns = max(longestGameTurns, viewModel.turnCount)
        updateBestScoreByMode(finalScore)
        updateRemainingTileCounts(viewModel.remainingOpenTiles)

        if won {
            gamesWon += 1
            winningScoreTotal += finalScore
            perfectClears += baseScore == 0 ? 1 : 0
            currentWinStreak += 1
            bestWinStreak = max(bestWinStreak, currentWinStreak)
            shortestClearTurns = shortestClearTurns == 0
                ? viewModel.turnCount
                : min(shortestClearTurns, viewModel.turnCount)
        } else {
            losses += 1
            losingScoreTotal += finalScore
            currentWinStreak = 0
        }
    }

    private func updateBestScoreByMode(_ finalScore: Int) {
        switch currentGameMode {
        case .classic:
            bestScoreClassic = bestScoreClassic == 0 ? finalScore : min(bestScoreClassic, finalScore)
        case .speedRun:
            bestScoreSpeedRun = bestScoreSpeedRun == 0 ? finalScore : min(bestScoreSpeedRun, finalScore)
        case .bigBox:
            bestScoreBigBox = bestScoreBigBox == 0 ? finalScore : min(bestScoreBigBox, finalScore)
        case .bigBoxSpeed:
            bestScoreBigBoxSpeed = bestScoreBigBoxSpeed == 0 ? finalScore : min(bestScoreBigBoxSpeed, finalScore)
        case .passAndPlay:
            break
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
        height < 700 ? 16 : 24
    }
}

// MARK: - Background views

private struct WoodBackground: View {
    let colors: [Color]

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
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

private struct WoodenTrayFrame: View {
    let boardColors: [Color]

    private let cornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(walnutGradient)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            boardColors.first?.opacity(0.18) ?? .clear,
                            Color.clear,
                            Color.black.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            TrayWoodGrain(cornerRadius: cornerRadius)
                .opacity(0.62)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color(red: 0.13, green: 0.06, blue: 0.02).opacity(0.92), lineWidth: 7)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.78, blue: 0.45).opacity(0.52),
                            Color(red: 0.62, green: 0.30, blue: 0.12).opacity(0.20),
                            Color.black.opacity(0.42),
                            Color.black.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )

            RoundedRectangle(cornerRadius: cornerRadius - 4)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.26), Color.clear, Color.black.opacity(0.54)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .padding(8)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.clear],
                        startPoint: .topLeading,
                        endPoint: UnitPoint(x: 0.42, y: 0.34)
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.34)],
                        startPoint: UnitPoint(x: 0.58, y: 0.58),
                        endPoint: .bottomTrailing
                    )
                )

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: cornerRadius - 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.34, green: 0.14, blue: 0.045).opacity(0.40),
                                Color.black.opacity(0.58)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 18)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 7)
            }
        }
    }

    private var walnutGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.24, green: 0.10, blue: 0.035),
                Color(red: 0.48, green: 0.25, blue: 0.10),
                Color(red: 0.34, green: 0.15, blue: 0.055),
                Color(red: 0.16, green: 0.065, blue: 0.022)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct TrayWoodGrain: View {
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let rows = Int(size.height / 7)
                for index in 0...rows {
                    let y = CGFloat(index) * 7 + CGFloat((index % 3) - 1)
                    var path = Path()
                    path.move(to: CGPoint(x: -18, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width + 18, y: y + CGFloat((index % 5) - 2) * 2.5),
                        control1: CGPoint(x: size.width * 0.28, y: y - 4),
                        control2: CGPoint(x: size.width * 0.68, y: y + 5)
                    )
                    let darkOpacity = 0.12 + Double(index % 4) * 0.025
                    context.stroke(path, with: .color(Color.black.opacity(darkOpacity)), lineWidth: index % 5 == 0 ? 1.4 : 0.8)
                }

                for index in stride(from: 1, through: rows, by: 5) {
                    let y = CGFloat(index) * 7
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width, y: y + 7),
                        control: CGPoint(x: size.width * 0.45, y: y - 6)
                    )
                    context.stroke(path, with: .color(Color(red: 0.92, green: 0.56, blue: 0.28).opacity(0.09)), lineWidth: 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

private struct WoodenTrayRecess: View {
    private let cornerRadius: CGFloat = 15

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.035, green: 0.030, blue: 0.026),
                            Color(red: 0.080, green: 0.055, blue: 0.035),
                            Color(red: 0.040, green: 0.032, blue: 0.028)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RecessSurfaceGrain(cornerRadius: cornerRadius)
                .opacity(0.36)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.black.opacity(0.88), lineWidth: 5)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.black.opacity(0.20),
                            Color.black.opacity(0.64),
                            Color.black.opacity(0.86)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.58), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.30)
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.42)],
                        startPoint: UnitPoint(x: 0.55, y: 0.52),
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

private struct RecessSurfaceGrain: View {
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let rows = Int(size.height / 9)
                for index in 0...rows {
                    let y = CGFloat(index) * 9
                    var path = Path()
                    path.move(to: CGPoint(x: -12, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width + 12, y: y + CGFloat((index % 4) - 2) * 2),
                        control1: CGPoint(x: size.width * 0.24, y: y + 3),
                        control2: CGPoint(x: size.width * 0.72, y: y - 4)
                    )
                    context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 0.8)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - Button styles

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
    enum Tint { case amber, green }

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
            .shadow(color: .black.opacity(isEnabled ? 0.28 : 0.10), radius: 8, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.78)
    }

    private var backgroundGradient: LinearGradient {
        guard isEnabled else {
            return LinearGradient(colors: [Color.gray.opacity(0.58), Color.gray.opacity(0.40)], startPoint: .top, endPoint: .bottom)
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
