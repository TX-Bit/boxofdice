//
//  WatchContentView.swift
//  BoxOfDice Watch App
//

import SwiftUI

private struct WatchGameplayLayoutMetrics {
    let size: CGSize
    let showsUtilityRow: Bool

    private var scale: CGFloat {
        min(max(size.height / 198, 0.82), 1.08)
    }

    var outerPadding: CGFloat { size.width < 180 ? 5 : 7 }
    var topPadding: CGFloat { 2 }
    var bottomPadding: CGFloat { 2 }
    var contentWidth: CGFloat { max(1, size.width - outerPadding * 2) }
    var headerContentWidth: CGFloat { contentWidth * 0.70 }
    var verticalSpacing: CGFloat { min(max(3.5, size.height * 0.018), 5.5) }

    var headerHeight: CGFloat   { min(max(20, size.height * 0.12), 28) }
    var diceSize: CGFloat       { min(max(21, size.height * 0.108), 26) }
    var diceRowHeight: CGFloat  { diceSize + 1 }
    var primaryHeight: CGFloat  { min(max(26, size.height * 0.138), 34) }
    var utilityHeight: CGFloat  { min(max(18, size.height * 0.092), 24) }

    var titleFontSize: CGFloat  { min(max(10, size.height * 0.058), 12) }
    var scoreFontSize: CGFloat  { min(max(9,  size.height * 0.052), 11) }
    var captionFontSize: CGFloat { min(max(8, size.height * 0.046), 9.5) }
    var buttonFontSize: CGFloat { min(max(11, size.height * 0.060), 13) }
    var utilityFontSize: CGFloat { min(max(9, size.height * 0.048), 10.5) }

    var primaryButtonWidth: CGFloat    { min(contentWidth * 0.62, 104) }
    var diceSpacing: CGFloat            { max(5, 7 * scale) }
    var utilitySpacing: CGFloat         { max(3, 5 * scale) }

    var trayInset: CGFloat        { max(2, 3 * scale) }
    var tileInset: CGFloat        { max(2, 3 * scale) }
    var tileSpacing: CGFloat      { max(2, 3 * scale) }
    var trayCornerRadius: CGFloat { max(8, 10 * scale) }
    var surfaceCornerRadius: CGFloat { max(6, 8 * scale) }

    func boardWidth(columns: Int) -> CGFloat {
        let maxWidth = contentWidth
        let compactWidth = columns > 4 ? maxWidth : min(maxWidth, size.width * 0.92)
        return max(1, compactWidth)
    }

    func boardHeight(columns: Int, rows: Int) -> CGFloat {
        let utility = utilityHeight + verticalSpacing
        let reserved = topPadding + bottomPadding + headerHeight + diceRowHeight
                     + primaryHeight + utility + verticalSpacing * 3
        let available = max(1, size.height - reserved)
        let width = boardWidth(columns: columns)
        let tileWidth = (width - (trayInset + tileInset) * 2
                        - CGFloat(columns - 1) * tileSpacing) / CGFloat(columns)
        let widthBasedHeight = tileWidth * CGFloat(rows)
                             + CGFloat(rows - 1) * tileSpacing
                             + (trayInset + tileInset) * 2
        let minimumTileHeight = min(max(19, size.height * 0.102), 27)
        let minimumBoardHeight = minimumTileHeight * CGFloat(rows)
                               + CGFloat(rows - 1) * tileSpacing
                               + (trayInset + tileInset) * 2
        let idealHeight = min(widthBasedHeight, size.height * 0.50)

        if available >= minimumBoardHeight {
            return min(idealHeight, available)
        }

        return min(idealHeight, minimumBoardHeight)
    }
}

struct WatchContentView: View {
    @StateObject private var viewModel = GameViewModel()

    @State private var activeSheet: WatchSheet?
    @State private var didApplyInitialSettings = false
    @State private var magnifiedTileId: Int?
    @State private var magnifyTask: Task<Void, Never>?
    @State private var currentPassAndPlayPlayer = 0
    @State private var passAndPlayScores: [Int] = []
    @State private var passAndPlayPlayerCount = 2
    @State private var isShowingPassAndPlayResults = false

    @AppStorage(SettingsStorageKey.watchTheme) private var watchThemeRaw = GameThemeName.greenFelt.rawValue

    @AppStorage(SettingsStorageKey.gameMode)            private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled)      private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled)       private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed)  private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.showHints)           private var showHints = true
    @AppStorage("hasSelectedInitialGameMode") private var hasSelectedInitialGameMode = false

    @AppStorage(StatisticsStorageKey.gamesPlayed)       private var gamesPlayed = 0
    @AppStorage(StatisticsStorageKey.gamesWon)          private var gamesWon = 0
    @AppStorage(StatisticsStorageKey.bestScore)         private var bestScore = 0
    @AppStorage(StatisticsStorageKey.totalScore)        private var totalScore = 0
    @AppStorage(StatisticsStorageKey.perfectClears)     private var perfectClears = 0
    @AppStorage(StatisticsStorageKey.currentWinStreak)  private var currentWinStreak = 0
    @AppStorage(StatisticsStorageKey.bestWinStreak)     private var bestWinStreak = 0
    @AppStorage(StatisticsStorageKey.winningScoreTotal) private var winningScoreTotal = 0
    @AppStorage(StatisticsStorageKey.losingScoreTotal)  private var losingScoreTotal = 0
    @AppStorage(StatisticsStorageKey.losses)            private var losses = 0
    @AppStorage(StatisticsStorageKey.longestGameTurns)  private var longestGameTurns = 0
    @AppStorage(StatisticsStorageKey.shortestClearTurns) private var shortestClearTurns = 0
    @AppStorage(StatisticsStorageKey.remainingTileCounts) private var remainingTileCounts = ""
    @AppStorage(StatisticsStorageKey.bestScoreClassic)      private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun)     private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox)       private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed)  private var bestScoreBigBoxSpeed = 0

    // MARK: - Computed

    private var activeThemeName: GameThemeName {
        GameThemeName(rawValue: watchThemeRaw) ?? .classicWood
    }
    private var theme: GameTheme            { GameTheme.palette(for: activeThemeName) }
    private var currentGameMode: GameMode {
        let mode = GameMode(rawValue: gameModeRaw) ?? .classic
        return (mode == .bigBox || mode == .bigBoxSpeed) ? .classic : mode
    }
    private var currentSettings: GameSettings { GameSettings.from(mode: currentGameMode) }
    private var diceAnimationSpeed: DiceAnimationSpeed { DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal }

    private var colCount: Int { viewModel.tiles.count > 12 ? 6 : 4 }
    private var rowCount: Int { max(1, Int(ceil(Double(viewModel.tiles.count) / Double(colCount)))) }

    private var showUtility: Bool {
        (viewModel.canSelectTiles && showHints) || viewModel.canUndo
    }

    private var reserveUtilitySpace: Bool {
        showHints || viewModel.canUndo
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let metrics = WatchGameplayLayoutMetrics(size: geometry.size, showsUtilityRow: reserveUtilitySpace)

            ZStack {
                LinearGradient(
                    colors: theme.background,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: metrics.verticalSpacing) {
                    compactHeader(metrics: metrics)
                        .frame(height: metrics.headerHeight, alignment: .leading)

                    gameTray(metrics: metrics)
                        .frame(width: metrics.boardWidth(columns: colCount),
                               height: metrics.boardHeight(columns: colCount, rows: rowCount))

                    diceAndBadgeRow(metrics: metrics)
                        .frame(height: metrics.diceRowHeight)

                    primaryActionButton(metrics: metrics)
                        .frame(height: metrics.primaryHeight)

                    utilityControls(metrics: metrics)
                        .frame(height: metrics.utilityHeight)
                        .opacity(showUtility ? 1 : 0)
                        .allowsHitTesting(showUtility)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, metrics.outerPadding)
                .padding(.top, metrics.topPadding)
                .padding(.bottom, metrics.bottomPadding)

                if let id = magnifiedTileId {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        Text("\(id)")
                            .font(.system(size: 58, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.14, green: 0.08, blue: 0.02))
                            .frame(width: 84, height: 84)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.00, green: 0.97, blue: 0.88),
                                             Color(red: 0.90, green: 0.76, blue: 0.52)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color(red: 1.0, green: 0.86, blue: 0.58).opacity(0.9), lineWidth: 2))
                            .shadow(color: .black.opacity(0.55), radius: 12, x: 0, y: 6)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.12), value: magnifiedTileId)
                }
            }
        }
        .onAppear {
            guard !didApplyInitialSettings else { return }
            didApplyInitialSettings = true
            configureViewModel()
            viewModel.newGame(settings: currentSettings, isTimed: currentGameMode.isTimed)
            if !hasSelectedInitialGameMode {
                activeSheet = .mode
            }
        }
        .onChange(of: viewModel.gameState, perform: handleGameStateChange)
        .onChange(of: diceAnimationSpeedRawValue) { _ in configureViewModel() }
        .onChange(of: hapticsEnabled)  { _ in configureViewModel() }
        .onChange(of: soundsEnabled)   { _ in configureViewModel() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .mode:
                WatchModeSelectionView { mode, playerCount in
                    startNewGame(mode: mode, playerCount: playerCount)
                    activeSheet = nil
                }
            case .settings:
                WatchSettingsView(onModeChanged: { mode in
                    configureViewModel()
                    viewModel.newGame(settings: currentSettings, isTimed: mode.isTimed)
                })
            case .stats:
                WatchStatsView()
            case .gameOver(let won):
                WatchGameOverView(
                    won: won,
                    tileScore: viewModel.score,
                    elapsedSeconds: viewModel.elapsedSeconds,
                    isTimed: currentGameMode.isTimed,
                    remainingOpenTiles: viewModel.remainingOpenTiles,
                    theme: theme,
                    onNewGame: restartCurrentGame,
                    onStats: { activeSheet = .stats }
                )
            case .roundEnd:
                WatchPassAndPlayRoundEndView(
                    playerNumber: currentPassAndPlayPlayer + 1,
                    tileScore: viewModel.score,
                    isLastPlayer: currentPassAndPlayPlayer == passAndPlayPlayerCount - 1,
                    theme: theme,
                    onNext: advanceToNextPlayer,
                    onResults: showPassAndPlayResults
                )
            case .results:
                WatchPassAndPlayResultsView(scores: passAndPlayScores, theme: theme) {
                    restartCurrentGame()
                }
            }
        }
    }

    // MARK: - Header

    private func compactHeader(metrics: WatchGameplayLayoutMetrics) -> some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.string("Box of Dice"))
                    .font(.custom("AmericanTypewriter-Bold", size: metrics.titleFontSize))
                    .foregroundStyle(
                        LinearGradient(colors: theme.title, startPoint: .leading, endPoint: .trailing)
                    )
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text("Score \(viewModel.score)")
                        .font(.system(size: metrics.scoreFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.score)

                    if currentGameMode.isTimed && viewModel.hasRolled {
                        Text(formattedElapsedTime)
                            .font(.system(size: metrics.captionFontSize, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.accent.opacity(0.80))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 5) {
                Button(action: restartCurrentGame) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: metrics.titleFontSize + 2, weight: .semibold))
                        .foregroundStyle(theme.text.opacity(0.80))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New Game")

                Button { activeSheet = .settings } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: metrics.titleFontSize + 2, weight: .semibold))
                        .foregroundStyle(theme.text.opacity(0.80))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
    }

    // MARK: - Game Tray

    private func gameTray(metrics: WatchGameplayLayoutMetrics) -> some View {
        GeometryReader { trayGeo in
            let traySize = trayGeo.size
            let frameInset = metrics.trayInset
            let gridSpacing = metrics.tileSpacing
            let gridInset = frameInset + metrics.tileInset
            let tileW = max(1, (traySize.width - gridInset * 2 - CGFloat(colCount - 1) * gridSpacing) / CGFloat(colCount))
            let tileH = max(1, (traySize.height - gridInset * 2 - CGFloat(rowCount - 1) * gridSpacing) / CGFloat(rowCount))

            ZStack {
                // Outer tray frame
                RoundedRectangle(cornerRadius: metrics.trayCornerRadius)
                    .fill(LinearGradient(
                        colors: theme.tray,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                // Tray edge highlight
                RoundedRectangle(cornerRadius: metrics.trayCornerRadius)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.7)

                // Inner playing surface
                RoundedRectangle(cornerRadius: metrics.surfaceCornerRadius)
                    .fill(LinearGradient(
                        colors: theme.surface,
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .padding(frameInset)
                    .overlay(
                        // Subtle top shadow inside the recess
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [Color.black.opacity(0.22), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 6)
                            Spacer(minLength: 0)
                        }
                        .padding(frameInset)
                        .clipShape(RoundedRectangle(cornerRadius: metrics.surfaceCornerRadius))
                    )

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(tileW), spacing: gridSpacing), count: colCount),
                    spacing: gridSpacing
                ) {
                    ForEach(viewModel.tiles) { tile in
                        WatchTileButton(
                            tile: tile,
                            isSelected: viewModel.selectedTiles.contains(tile.id)
                                || viewModel.highlightedHint.contains(tile.id),
                            isEnabled: viewModel.canSelectTiles,
                            theme: theme
                        ) {
                            viewModel.toggleTile(tile.id)
                        }
                        .frame(width: tileW, height: tileH)
                    }
                }
                .frame(width: traySize.width - gridInset * 2, height: traySize.height - gridInset * 2)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            let tile = tileAtLocation(
                                value.location,
                                tileW: tileW, tileH: tileH,
                                spacing: gridSpacing, colCount: colCount
                            )
                            let tileId = (tile?.isOpen == true) ? tile?.id : nil
                            if magnifiedTileId != nil {
                                // Already visible — update position immediately for smooth sliding
                                magnifiedTileId = tileId
                            } else {
                                // Not yet visible — start delay so quick taps skip it
                                magnifyTask?.cancel()
                                if let tileId {
                                    magnifyTask = Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 180_000_000)
                                        guard !Task.isCancelled else { return }
                                        magnifiedTileId = tileId
                                    }
                                }
                            }
                        }
                        .onEnded { value in
                            magnifyTask?.cancel()
                            magnifyTask = nil
                            defer { magnifiedTileId = nil }
                            guard viewModel.canSelectTiles else { return }
                            guard let tile = tileAtLocation(
                                value.location,
                                tileW: tileW, tileH: tileH,
                                spacing: gridSpacing, colCount: colCount
                            ), tile.isOpen else { return }
                            viewModel.toggleTile(tile.id)
                        }
                )
            }
        }
    }

    // MARK: - Dice Panel

    private func diceAndBadgeRow(metrics: WatchGameplayLayoutMetrics) -> some View {
        HStack(spacing: metrics.diceSpacing) {
            ForEach(0..<viewModel.dieCount, id: \.self) { i in
                WatchPipDieView(
                    value: viewModel.dice[i],
                    isRolling: viewModel.isRolling,
                    size: metrics.diceSize,
                    restingAngle: dieRestingAngle(i)
                )
                .shadow(color: .black.opacity(0.32), radius: 2, x: 0.5, y: 1.5)
                .opacity((viewModel.isRolling || viewModel.hasRolled) ? 1.0 : 0.34)
            }


        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.hasRolled ? L10n.string("Dice rolled") : L10n.string("Dice, not rolled yet"))
    }

    private func dieRestingAngle(_ index: Int) -> CGFloat {
        [2.5, -2.0, 1.0][min(index, 2)]
    }

    private func tileAtLocation(_ location: CGPoint, tileW: CGFloat, tileH: CGFloat, spacing: CGFloat, colCount: Int) -> Tile? {
        let col = Int(location.x / (tileW + spacing))
        let row = Int(location.y / (tileH + spacing))
        let index = row * colCount + col
        guard col >= 0, col < colCount, row >= 0, index >= 0, index < viewModel.tiles.count else { return nil }
        let tileX = CGFloat(col) * (tileW + spacing)
        let tileY = CGFloat(row) * (tileH + spacing)
        guard location.x >= tileX, location.x <= tileX + tileW,
              location.y >= tileY, location.y <= tileY + tileH else { return nil }
        return viewModel.tiles[index]
    }

    // MARK: - Primary Action Button

    @ViewBuilder
    private func primaryActionButton(metrics: WatchGameplayLayoutMetrics) -> some View {
        switch viewModel.gameState {
        case .waitingToRoll:
            Button(action: viewModel.rollDice) {
                Label(L10n.string(viewModel.isRolling ? "Rolling" : "Roll"), systemImage: "dice.fill")
                    .font(.system(size: metrics.buttonFontSize, weight: .bold))
                    .lineLimit(1)
                    .frame(width: metrics.primaryButtonWidth, height: metrics.primaryHeight)
            }
            .buttonStyle(WatchPrimaryButtonStyle(theme: theme, enabled: viewModel.canRoll))
            .disabled(!viewModel.canRoll)

        case .selecting:
            if viewModel.canConfirm {
                // Active: tiles sum to the target — show prominent confirm button
                Button(action: viewModel.confirmSelection) {
                    Text("✓ Confirm")
                        .font(.system(size: metrics.buttonFontSize, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(width: metrics.primaryButtonWidth, height: metrics.primaryHeight)
                }
                .buttonStyle(WatchPrimaryButtonStyle(theme: theme, enabled: true))
            } else {
                // Inactive: show selection progress instead of a disabled button
                Text("Selected \(viewModel.selectionTotal)")
                    .font(.system(size: max(9, metrics.buttonFontSize - 1.5), weight: .medium, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.60))
                    .lineLimit(1)
                    .frame(width: metrics.primaryButtonWidth, height: metrics.primaryHeight)
            }

        case .gameOver:
            Button(action: presentGameOver) {
                Label("Results", systemImage: "trophy.fill")
                    .font(.system(size: metrics.buttonFontSize, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: metrics.primaryButtonWidth, height: metrics.primaryHeight)
            }
            .buttonStyle(WatchPrimaryButtonStyle(theme: theme, enabled: true))
        }
    }

    // MARK: - Utility Controls (Hint / Undo)

    private func utilityControls(metrics: WatchGameplayLayoutMetrics) -> some View {
        HStack(spacing: metrics.utilitySpacing) {
            Spacer(minLength: 0)
            if viewModel.canSelectTiles && showHints {
                Button(action: viewModel.showHint) {
                    Label("Hint", systemImage: "lightbulb.fill")
                        .font(.system(size: metrics.utilityFontSize, weight: .semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(minHeight: metrics.utilityHeight)
                }
                .buttonStyle(WatchUtilityButtonStyle(theme: theme))
                .accessibilityLabel("Show hint")
            }
            if viewModel.canUndo {
                Button(action: viewModel.undoLastMove) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.system(size: metrics.utilityFontSize, weight: .semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(minHeight: metrics.utilityHeight)
                }
                .buttonStyle(WatchUtilityButtonStyle(theme: theme))
                .accessibilityLabel("Undo last move")
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Helpers

    private var formattedElapsedTime: String {
        let s = viewModel.elapsedSeconds
        let m = s / 60
        return m > 0 ? "\(m):\(String(format: "%02d", s % 60))" : "\(s)s"
    }

    private func configureViewModel() {
        viewModel.configure(
            diceAnimationSpeed: diceAnimationSpeed,
            feedbackOptions: FeedbackOptions(hapticsEnabled: hapticsEnabled, soundsEnabled: soundsEnabled),
            isTimed: currentGameMode.isTimed
        )
    }

    private func startNewGame(mode: GameMode, playerCount: Int = 2) {
        hasSelectedInitialGameMode = true
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

    private func restartCurrentGame() {
        activeSheet = nil
        startNewGame(mode: currentGameMode, playerCount: passAndPlayPlayerCount)
    }

    private func advanceToNextPlayer() {
        passAndPlayScores.append(viewModel.score)
        currentPassAndPlayPlayer += 1
        activeSheet = nil
        configureViewModel()
        viewModel.newGame(settings: currentSettings, isTimed: false)
    }

    private func showPassAndPlayResults() {
        passAndPlayScores.append(viewModel.score)
        isShowingPassAndPlayResults = true
        activeSheet = .results
    }

    private func handleGameStateChange(_ newState: GameState) {
        guard case .gameOver(let won) = newState else { return }
        if currentGameMode.isMultiplayer {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                activeSheet = isShowingPassAndPlayResults ? .results : .roundEnd
            }
        } else {
            recordCompletedGame(won: won)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: won ? 500_000_000 : 900_000_000)
                presentGameOver()
            }
        }
    }

    private func presentGameOver() {
        guard case .gameOver(let won) = viewModel.gameState else { return }
        activeSheet = .gameOver(won: won)
    }

    private func recordCompletedGame(won: Bool) {
        let baseScore  = viewModel.score
        let finalScore = currentGameMode.finalScore(baseScore: baseScore, elapsedSeconds: viewModel.elapsedSeconds)
        let isFirst    = gamesPlayed == 0

        gamesPlayed    += 1
        totalScore     += finalScore
        bestScore       = isFirst ? finalScore : min(bestScore, finalScore)
        longestGameTurns = max(longestGameTurns, viewModel.turnCount)
        updateBestScoreByMode(finalScore)
        updateRemainingTileCounts(viewModel.remainingOpenTiles)

        if won {
            gamesWon         += 1
            winningScoreTotal += finalScore
            perfectClears    += baseScore == 0 ? 1 : 0
            currentWinStreak += 1
            bestWinStreak     = max(bestWinStreak, currentWinStreak)
            shortestClearTurns = shortestClearTurns == 0
                ? viewModel.turnCount
                : min(shortestClearTurns, viewModel.turnCount)
        } else {
            losses           += 1
            losingScoreTotal += finalScore
            currentWinStreak  = 0
        }
    }

    private func updateBestScoreByMode(_ score: Int) {
        switch currentGameMode {
        case .classic:     bestScoreClassic     = bestScoreClassic     == 0 ? score : min(bestScoreClassic, score)
        case .speedRun:    bestScoreSpeedRun    = bestScoreSpeedRun    == 0 ? score : min(bestScoreSpeedRun, score)
        case .bigBox:      bestScoreBigBox      = bestScoreBigBox      == 0 ? score : min(bestScoreBigBox, score)
        case .bigBoxSpeed: bestScoreBigBoxSpeed = bestScoreBigBoxSpeed == 0 ? score : min(bestScoreBigBoxSpeed, score)
        case .passAndPlay: break
        }
    }

    private func updateRemainingTileCounts(_ tiles: [Int]) {
        var counts = Dictionary(uniqueKeysWithValues: remainingTileCounts
            .split(separator: ",")
            .compactMap { pair -> (Int, Int)? in
                let p = pair.split(separator: ":")
                guard p.count == 2, let t = Int(p[0]), let c = Int(p[1]) else { return nil }
                return (t, c)
            })
        for tile in tiles { counts[tile, default: 0] += 1 }
        remainingTileCounts = counts.sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }.joined(separator: ",")
    }
}

// MARK: - WatchSheet

enum WatchSheet: Identifiable, Equatable {
    case mode, settings, stats
    case gameOver(won: Bool)
    case roundEnd, results

    var id: String {
        switch self {
        case .mode:             return "mode"
        case .settings:         return "settings"
        case .stats:            return "stats"
        case .gameOver(let w):  return "gameOver-\(w)"
        case .roundEnd:         return "roundEnd"
        case .results:          return "results"
        }
    }
}

// MARK: - WatchPipDieView

private struct WatchPipDieView: View {
    let value: Int
    let isRolling: Bool
    let size: CGFloat
    var restingAngle: CGFloat = 0

    @State private var displayValue: Int = 1
    @State private var shakeLeft = false
    @State private var animTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Die body — warm ivory fill
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(LinearGradient(
                    colors: [Color(white: 0.97), Color(red: 0.92, green: 0.87, blue: 0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            // Top-left specular highlight (bevel)
            LinearGradient(
                colors: [Color.white.opacity(0.72), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.50)
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
            // Subtle bottom darkening for physical depth
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.12)],
                startPoint: UnitPoint(x: 0.5, y: 0.55),
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
            // Border — lighter top, darker bottom for bevel effect
            RoundedRectangle(cornerRadius: size * 0.18)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(white: 0.72), Color(white: 0.44)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.7
                )
            // Pips
            PipLayout(value: displayValue, size: size)
                .animation(.easeInOut(duration: 0.04), value: displayValue)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(isRolling ? (shakeLeft ? -7 : 7) : restingAngle))
        .animation(.easeInOut(duration: 0.09), value: shakeLeft)
        .animation(.easeInOut(duration: 0.15), value: isRolling)
        .onAppear { displayValue = max(1, value) }
        .onChange(of: value) { v in if !isRolling { displayValue = max(1, v) } }
        .onChange(of: isRolling) { rolling in
            if rolling {
                animTask?.cancel()
                animTask = Task { @MainActor in
                    while !Task.isCancelled {
                        displayValue = Int.random(in: 1...6)
                        shakeLeft.toggle()
                        try? await Task.sleep(nanoseconds: 80_000_000)
                    }
                }
            } else {
                animTask?.cancel(); animTask = nil
                displayValue = max(1, value)
                shakeLeft = false
            }
        }
        .onDisappear { animTask?.cancel() }
    }
}

private struct PipLayout: View {
    let value: Int
    let size: CGFloat

    private var positions: [CGPoint] {
        let d: CGFloat = 0.28
        let tl = CGPoint(x: -d, y: -d), tr = CGPoint(x:  d, y: -d)
        let ml = CGPoint(x: -d, y:  0), mr = CGPoint(x:  d, y:  0)
        let bl = CGPoint(x: -d, y:  d), br = CGPoint(x:  d, y:  d)
        let c  = CGPoint.zero
        switch value {
        case 1: return [c]
        case 2: return [tr, bl]
        case 3: return [tr, c, bl]
        case 4: return [tl, tr, bl, br]
        case 5: return [tl, tr, c, bl, br]
        case 6: return [tl, ml, bl, tr, mr, br]
        default: return []
        }
    }

    var body: some View {
        let pip = size * 0.118
        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.06), Color(white: 0.18)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: pip, height: pip)
                    .offset(x: pos.x * size * 0.62, y: pos.y * size * 0.62)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - WatchTileButton

private struct WatchTileButton: View {
    let tile: Tile
    let isSelected: Bool
    let isEnabled: Bool
    let theme: GameTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                let h = geo.size.height
                // Proportional corner radius — more physical tile shape, less pill
                let cr = max(4.5, h * 0.22)

                ZStack {
                    // Base fill — ivory for open, recessed dark for closed
                    RoundedRectangle(cornerRadius: cr)
                        .fill(baseFill)

                    // Top bevel highlight — strong on open tiles, ghost on closed
                    LinearGradient(
                        colors: [Color.white.opacity(tile.isOpen ? 0.70 : 0.07), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.44)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cr))

                    // Bottom depth edge — gives physical thickness
                    VStack(spacing: 0) {
                        Spacer()
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(tile.isOpen ? 0.22 : 0.40)],
                            startPoint: UnitPoint(x: 0.5, y: 0.0),
                            endPoint: .bottom
                        )
                        .frame(height: max(5, h * 0.34))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cr))

                    // Border: thick accent ring when selected, bevel stroke otherwise
                    if isSelected {
                        RoundedRectangle(cornerRadius: cr)
                            .strokeBorder(Color(red: 1.0, green: 0.72, blue: 0.0), lineWidth: 2.5)
                    } else {
                        RoundedRectangle(cornerRadius: cr)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(tile.isOpen ? 0.58 : 0.12),
                                        Color.black.opacity(tile.isOpen ? 0.20 : 0.34)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }

                    // Number — scales with tile height, always readable
                    Text("\(tile.id)")
                        .font(.system(
                            size: tile.id >= 10
                                ? max(9.5, h * 0.42)
                                : max(11, h * 0.48),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(numberColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                // Strong glow on selected tiles
                .shadow(color: isSelected ? Color(red: 1.0, green: 0.72, blue: 0.0).opacity(0.75) : .clear, radius: 4)
            }
        }
        .buttonStyle(.plain)
        .disabled(!tile.isOpen || !isEnabled)
        .accessibilityLabel(tile.isOpen ? L10n.format("Tile %d, open", tile.id) : L10n.format("Tile %d, closed", tile.id))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // Open: warm ivory (selected = bright amber); Closed: dark recessed surface
    private var baseFill: LinearGradient {
        if tile.isOpen {
            return isSelected
                ? LinearGradient(
                    colors: [Color(red: 1.00, green: 0.88, blue: 0.20),
                             Color(red: 0.96, green: 0.58, blue: 0.02)],
                    startPoint: .top, endPoint: .bottom)
                : LinearGradient(
                    colors: [Color(red: 1.00, green: 0.97, blue: 0.88),
                             Color(red: 0.90, green: 0.76, blue: 0.52)],
                    startPoint: .top, endPoint: .bottom)
        }
        // Closed: use theme surface (darker top = recessed look)
        return LinearGradient(colors: theme.surface, startPoint: .bottom, endPoint: .top)
    }

    private var numberColor: Color {
        tile.isOpen
            ? Color(red: 0.14, green: 0.08, blue: 0.02)
            : theme.text.opacity(0.45)
    }
}

// MARK: - Button Styles

private struct WatchPrimaryButtonStyle: ButtonStyle {
    let theme: GameTheme
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(enabled ? Color.black.opacity(0.85) : theme.text.opacity(0.62))
            .background(
                LinearGradient(
                    colors: enabled
                        ? theme.button
                        : [Color.white.opacity(0.06), Color.white.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                // Top sheen on enabled button
                LinearGradient(
                    colors: enabled
                        ? [Color.white.opacity(0.22), Color.clear]
                        : [Color.white.opacity(0.04), Color.clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            )
            .scaleEffect(configuration.isPressed && enabled ? 0.97 : 1.0)
    }
}

private struct WatchUtilityButtonStyle: ButtonStyle {
    let theme: GameTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(theme.accent.opacity(0.82))
            .background(theme.accent.opacity(0.10), in: Capsule())
            .overlay(Capsule().strokeBorder(theme.accent.opacity(0.20), lineWidth: 0.5))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}
