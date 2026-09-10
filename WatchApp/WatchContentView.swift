//
//  WatchContentView.swift
//  BoxOfDice Watch App
//

import SwiftUI

// Internal (not private) so its height-budget math is directly unit-testable
// — see WatchLayoutBudgetTests.swift.
struct WatchGameplayLayoutMetrics {
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

    /// Rows actually on screen right now: the utility (hint/undo) row only
    /// occupies space — and must only be *budgeted* space — when this
    /// session could ever show it (`showsUtilityRow`, from
    /// `reserveUtilitySpace`); the gameplay VStack mirrors this by only
    /// including that row at all when the same condition holds (see `body`).
    /// Reserving space for a row that's never rendered previously forced the
    /// board shorter than it needed to be.
    private var reservedRowCount: CGFloat { showsUtilityRow ? 3 : 2 }

    func boardHeight(columns: Int, rows: Int) -> CGFloat {
        let utility = showsUtilityRow ? (utilityHeight + verticalSpacing) : 0
        let reserved = topPadding + bottomPadding + headerHeight + diceRowHeight
                     + primaryHeight + utility + verticalSpacing * reservedRowCount
        // However small the remaining space is, the board must never claim
        // more than this — doing so pushes the primary action button (and,
        // on the smallest screens, the utility row) outside the visible
        // area instead of just rendering undersized tiles.
        let available = max(1, size.height - reserved)
        let width = boardWidth(columns: columns)
        let tileWidth = (width - (trayInset + tileInset) * 2
                        - CGFloat(columns - 1) * tileSpacing) / CGFloat(columns)
        let widthBasedHeight = tileWidth * CGFloat(rows)
                             + CGFloat(rows - 1) * tileSpacing
                             + (trayInset + tileInset) * 2
        let idealHeight = min(widthBasedHeight, size.height * 0.50)

        return min(idealHeight, available)
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
    // BOD-012: new installs show the dice sum by default; a previous user's
    // explicit `false` still wins (@AppStorage only falls back to this when
    // the key was never written). Same default as iOS.
    @AppStorage(SettingsStorageKey.showDiceTotal)       private var showDiceTotal = true
    @AppStorage("hasSelectedInitialGameMode") private var hasSelectedInitialGameMode = false
    @AppStorage(SettingsStorageKey.onboardingCompletedOrSkipped) private var onboardingCompletedOrSkipped = false

    // BOD-012: `OnboardingContext` is the shared type from
    // OnboardingViewModel.swift (same rule on both platforms) — kept entirely
    // separate from the normal game's state.
    @State private var onboardingContext: OnboardingContext?

    @AppStorage(StatisticsStorageKey.gamesPlayed)       private var gamesPlayed = 0
    @AppStorage(StatisticsStorageKey.gamesWon)          private var gamesWon = 0
    @AppStorage(StatisticsStorageKey.perfectClears)     private var perfectClears = 0
    @AppStorage(StatisticsStorageKey.currentWinStreak)  private var currentWinStreak = 0
    @AppStorage(StatisticsStorageKey.bestWinStreak)     private var bestWinStreak = 0
    @AppStorage(StatisticsStorageKey.losses)            private var losses = 0
    @AppStorage(StatisticsStorageKey.longestGameTurns)  private var longestGameTurns = 0
    @AppStorage(StatisticsStorageKey.shortestClearTurns) private var shortestClearTurns = 0
    @AppStorage(StatisticsStorageKey.remainingTileCounts) private var remainingTileCounts = ""
    @AppStorage(StatisticsStorageKey.bestScoreQuickGame)    private var bestScoreQuickGame = 0
    @AppStorage(StatisticsStorageKey.bestScoreClassic)      private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun)     private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox)       private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed)  private var bestScoreBigBoxSpeed = 0

    // Per-mode score totals/counts (BOD-005) — see GameStatistics.swift/
    // WatchGameCore.swift's StatisticsStorageKey for why these replace the
    // old combined totalScore/bestScore/winningScoreTotal/losingScoreTotal.
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

    // Guards against recording the same finished game's stats twice.
    // Reset whenever a fresh game begins. See GameResultRecordGuard.swift
    // (R3 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
    @State private var resultRecordGuard = GameResultRecordGuard()

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Computed

    private var activeThemeName: GameThemeName {
        GameThemeName(rawValue: watchThemeRaw) ?? .greenFelt
    }
    private var theme: GameTheme            { GameTheme.palette(for: activeThemeName) }
    private var currentGameMode: GameMode {
        GameMode.normalizedForWatch(rawValue: gameModeRaw)
    }
    private var currentSettings: GameSettings {
        GameSettings.from(mode: currentGameMode, diceMode: currentGameMode.diceMode, moveRule: .anyCombination)
    }
    private var diceAnimationSpeed: DiceAnimationSpeed { DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal }

    // 9 tiles (Quick Game) reads as a 3x3 grid; every other Watch-supported
    // mode is 12 tiles as 4x3. (Big Box's 18 tiles never reaches the Watch
    // UI — see GameMode.supportedOnWatch — but the >12 fallback is kept as a
    // defensive floor rather than assuming that invariant here too.)
    private var colCount: Int {
        switch viewModel.tiles.count {
        case ...9:  return 3
        case 10...12: return 4
        default: return 6
        }
    }
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

                    // Reserved (and given a fixed slot) only when this session
                    // could ever show it (`reserveUtilitySpace`); within that,
                    // moment-to-moment presence just fades — keeping the
                    // primary button's position stable — rather than
                    // reflowing the layout. Not reserving the row at all when
                    // it can never appear matches `boardHeight`'s own budget
                    // (`showsUtilityRow`), so the board can use that space.
                    if reserveUtilitySpace {
                        utilityControls(metrics: metrics)
                            .frame(height: metrics.utilityHeight)
                            .opacity(showUtility ? 1 : 0)
                            .allowsHitTesting(showUtility)
                    }
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

                if let context = onboardingContext {
                    WatchOnboardingView(
                        theme: theme,
                        isReplay: context == .replay,
                        onFinish: { finishOnboarding(context: context) }
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
        }
        .onAppear {
            guard !didApplyInitialSettings else { return }
            didApplyInitialSettings = true
            configureViewModel()
            beginAppLaunchFlow()
        }
        .onChange(of: viewModel.gameState) { _, newState in handleGameStateChange(newState) }
        .onChange(of: viewModel.revision) { persistCurrentGame() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.handleScenePhaseBackground()
                persistCurrentGame()
            }
        }
        .onChange(of: diceAnimationSpeedRawValue) { configureViewModel() }
        .onChange(of: hapticsEnabled)  { configureViewModel() }
        .onChange(of: soundsEnabled)   { configureViewModel() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .mode:
                WatchModeSelectionView { mode, playerCount in
                    startNewGame(mode: mode, playerCount: playerCount)
                    activeSheet = nil
                }
            case .settings:
                WatchSettingsView(
                    onModeChanged: { mode in
                        configureViewModel()
                        beginNewViewModelGame(settings: currentSettings, isTimed: mode.isTimed)
                    },
                    onShowHowToPlay: {
                        activeSheet = nil
                        onboardingContext = .replay
                    }
                )
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
                // The Watch app's own name/icon is already shown at launch
                // (and again if the user swipes back to the app list), so
                // repeating "Box of Dice" here on every gameplay frame is
                // pure noise — the mode name is what's actually useful to
                // see at a glance while playing.
                Text(currentGameMode.title)
                    .font(.system(size: metrics.titleFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.title.first ?? theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7) // longer localized mode names (e.g. German "Reihum spielen") must shrink, not clip

                HStack(spacing: 5) {
                    // "Remaining" for untimed modes (BOD-012 — an unqualified
                    // "Score" reads as something to grow in a lowest-wins
                    // game); timed modes keep "Score" since the appended
                    // timer text already separates tile score from time.
                    // Timed modes say "Tile score", not "Score": the number is
                    // the open tiles' sum, and the final score is this plus
                    // the elapsed time shown right below it
                    // (docs/KIELITARKISTUS_2026-09-10.md).
                    Text(currentGameMode.isTimed ? L10n.format("Tile score %lld", viewModel.score) : L10n.format("Remaining %lld", viewModel.score))
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
                // Flat tray frame — a single matte fill, no gloss/edge
                // highlight, so it reads as a calm board rather than a
                // glossy widget.
                RoundedRectangle(cornerRadius: metrics.trayCornerRadius)
                    .fill(theme.tray.first ?? Color.black)

                // Inner playing surface — likewise a single flat fill.
                RoundedRectangle(cornerRadius: metrics.surfaceCornerRadius)
                    .fill(theme.surface.first ?? Color.black)
                    .padding(frameInset)

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

            // BOD-012 follow-up (docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §2):
            // the Watch had no dice-total display at all, so the new
            // `showDiceTotal = true` default did nothing here. Shown beside
            // the dice rather than below them — vertical space is the scarce
            // one on this screen. Only once the dice have settled, so it
            // can't flicker through the roll animation.
            if showDiceTotal && viewModel.hasRolled && !viewModel.isRolling {
                Text("\(viewModel.diceTotal)")
                    .font(.system(size: metrics.diceSize * 0.52, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            viewModel.hasRolled
                ? L10n.format("Dice total %lld", viewModel.diceTotal)
                : L10n.string("Dice, not rolled yet")
        )
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
                // Inactive: show selection progress toward the roll's target
                // instead of a disabled button — and say clearly whether
                // that's "not enough yet" or "too much", rather than a bare
                // total that reads the same either way.
                Text(selectionProgressText)
                    .font(.system(size: max(9, metrics.buttonFontSize - 1.5), weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelectionOverTarget ? Color(red: 1.0, green: 0.46, blue: 0.36) : theme.text.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

    private var isSelectionOverTarget: Bool {
        viewModel.selectionTotal > viewModel.diceTotal
    }

    private var selectionProgressText: String {
        if isSelectionOverTarget {
            return L10n.format("Over by %lld", viewModel.selectionTotal - viewModel.diceTotal)
        }
        return L10n.format("%lld of %lld", viewModel.selectionTotal, viewModel.diceTotal)
    }

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
        beginNewViewModelGame(settings: currentSettings, isTimed: mode.isTimed)
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
        beginNewViewModelGame(settings: currentSettings, isTimed: false)
    }

    // MARK: - Launch routing (BOD-012)

    /// Same priority order as ContentView.beginAppLaunchFlow() on iOS —
    /// see that comment for the full rationale.
    private func beginAppLaunchFlow() {
        if restoreSavedGameIfAny() {
            return
        }
        let isReturningUser = hasSelectedInitialGameMode || gamesPlayed > 0
        if isReturningUser || onboardingCompletedOrSkipped {
            onboardingCompletedOrSkipped = true
            beginNewViewModelGame(settings: currentSettings, isTimed: currentGameMode.isTimed)
        } else {
            onboardingContext = .firstLaunch
        }
    }

    private func finishOnboarding(context: OnboardingContext) {
        onboardingContext = nil
        guard context == .firstLaunch else { return }
        onboardingCompletedOrSkipped = true
        hasSelectedInitialGameMode = true
        gameModeRaw = GameMode.quickGame.rawValue
        configureViewModel()
        beginNewViewModelGame(
            settings: GameSettings.from(mode: .quickGame, diceMode: GameMode.quickGame.diceMode, moveRule: .anyCombination),
            isTimed: false
        )
    }

    /// Starts a fresh game on the view model and clears the "already
    /// recorded this game's result" guard. All `viewModel.newGame(...)`
    /// calls should go through here.
    private func beginNewViewModelGame(settings: GameSettings, isTimed: Bool) {
        resultRecordGuard.reset()
        viewModel.newGame(settings: settings, isTimed: isTimed)
        persistCurrentGame()
    }

    // MARK: - Save/restore (BOD-006)

    /// Attempts to resume a previously saved in-progress game. Returns
    /// `true` if a game was restored — the caller must not also start a
    /// fresh one. `GameSaveStore.load()` already turns any failure (no
    /// save, unreadable file, corrupt/unrecognized JSON) into `nil`.
    private func restoreSavedGameIfAny() -> Bool {
        guard let saved = GameSaveStore.load() else { return false }

        // The save could in principle carry a mode this Watch build doesn't
        // present (e.g. Big Box, or phone-synced data) — normalize it the
        // same way every other Watch mode read does. But normalizing the
        // *mode* alone isn't enough: if the saved *engine* doesn't actually
        // match what the normalized mode implies (its tile count above all),
        // labeling it with the normalized mode would misrepresent the game
        // — an 18-tile Big Box engine must never be shown or scored as a
        // 12-tile Classic game. Such a save can't be resumed correctly on
        // this build, so it's discarded (controlled fallback) rather than
        // restored with a mismatched label.
        let normalizedMode = GameMode.normalizedForWatch(saved.gameMode)
        guard saved.engine.settings.tileCount == normalizedMode.tileCount else {
            GameSaveStore.clear()
            return false
        }

        gameModeRaw = normalizedMode.rawValue
        passAndPlayPlayerCount = saved.passAndPlayPlayerCount
        currentPassAndPlayPlayer = saved.currentPassAndPlayPlayer
        passAndPlayScores = saved.passAndPlayScores
        hasSelectedInitialGameMode = true
        resultRecordGuard.reset()

        viewModel.restore(
            engine: saved.engine,
            pendingRollDice: saved.pendingRollDice,
            gameStartTime: saved.gameStartTime,
            isTimed: normalizedMode.isTimed
        )
        return true
    }

    /// Persists the current in-progress game — see the identical iOS
    /// counterpart in `ContentView.swift` for the full rationale. A
    /// finished game has nothing to resume and its stats are already
    /// recorded, so its save is cleared instead.
    private func persistCurrentGame() {
        // BOD-012 follow-up (docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §1):
        // never write the untouched Classic game sitting underneath the
        // first-launch tutorial — see `OnboardingContext`.
        if let onboardingContext, !onboardingContext.allowsPersistingUnderlyingGame { return }

        if case .gameOver = viewModel.gameState {
            GameSaveStore.clear()
            return
        }
        GameSaveStore.save(SavedGame(
            gameMode: currentGameMode,
            engine: viewModel.engineSnapshot,
            pendingRollDice: viewModel.pendingRollDiceForSaving,
            gameStartTime: viewModel.gameStartTimeForSaving,
            passAndPlayPlayerCount: passAndPlayPlayerCount,
            currentPassAndPlayPlayer: currentPassAndPlayPlayer,
            passAndPlayScores: passAndPlayScores
        ))
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
            // Never record the same finished game's stats twice.
            if resultRecordGuard.recordIfNeeded() {
                recordCompletedGame(won: won)
            }
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

        gamesPlayed    += 1
        longestGameTurns = max(longestGameTurns, viewModel.turnCount)
        updateBestScoreByMode(finalScore)
        updateModeScoreAverage(finalScore)
        updateRemainingTileCounts(viewModel.remainingOpenTiles)

        if won {
            gamesWon         += 1
            perfectClears    += baseScore == 0 ? 1 : 0
            currentWinStreak += 1
            bestWinStreak     = max(bestWinStreak, currentWinStreak)
            shortestClearTurns = shortestClearTurns == 0
                ? viewModel.turnCount
                : min(shortestClearTurns, viewModel.turnCount)
        } else {
            losses           += 1
            currentWinStreak  = 0
        }
    }

    private func updateBestScoreByMode(_ score: Int) {
        switch currentGameMode {
        case .quickGame:   bestScoreQuickGame   = updatedBestScore(bestScoreQuickGame, key: StatisticsStorageKey.bestScoreQuickGame, candidate: score)
        case .classic:     bestScoreClassic     = updatedBestScore(bestScoreClassic, key: StatisticsStorageKey.bestScoreClassic, candidate: score)
        case .speedRun:    bestScoreSpeedRun    = updatedBestScore(bestScoreSpeedRun, key: StatisticsStorageKey.bestScoreSpeedRun, candidate: score)
        case .bigBox:      bestScoreBigBox      = updatedBestScore(bestScoreBigBox, key: StatisticsStorageKey.bestScoreBigBox, candidate: score)
        case .bigBoxSpeed: bestScoreBigBoxSpeed = updatedBestScore(bestScoreBigBoxSpeed, key: StatisticsStorageKey.bestScoreBigBoxSpeed, candidate: score)
        case .passAndPlay: break
        }
    }

    /// Per-mode running total/count for "average score by mode" (BOD-005).
    private func updateModeScoreAverage(_ finalScore: Int) {
        switch currentGameMode {
        case .quickGame:   modeScoreTotalQuickGame   += finalScore; modeScoreCountQuickGame   += 1
        case .classic:     modeScoreTotalClassic     += finalScore; modeScoreCountClassic     += 1
        case .speedRun:    modeScoreTotalSpeedRun    += finalScore; modeScoreCountSpeedRun    += 1
        case .bigBox:      modeScoreTotalBigBox      += finalScore; modeScoreCountBigBox      += 1
        case .bigBoxSpeed: modeScoreTotalBigBoxSpeed += finalScore; modeScoreCountBigBoxSpeed += 1
        case .passAndPlay: break
        }
    }

    private func updatedBestScore(_ current: Int, key: String, candidate: Int) -> Int {
        UserDefaults.standard.object(forKey: key) == nil ? candidate : min(current, candidate)
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

    // Only ever drives the cosmetic random-face cycling *during* an active
    // roll. The resting face is never cached into state — it reads `value`
    // directly every render (see `displayedValue` below) — so there is no
    // "copy value into @State, keep it in sync via onAppear/onChange"
    // machinery that could fall out of sync. That machinery previously ran
    // the die's resting face this way, and a missed/late sync left it
    // showing a stale face (reported: pips frozen at "1, 1" while the real
    // roll — and everything derived from it, score included — was correct).
    @State private var cyclingValue: Int = 1
    @State private var shakeLeft = false
    @State private var animTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The face actually shown: the live cycling value while genuinely
    /// mid-roll, otherwise always the model's real `value` — never a cached
    /// copy, so it can't go stale.
    private var displayedValue: Int {
        (isRolling && !reduceMotion) ? cyclingValue : max(1, value)
    }

    var body: some View {
        ZStack {
            // Flat matte cream die — no bevel/specular layers.
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(Color(red: 0.97, green: 0.95, blue: 0.88))
            RoundedRectangle(cornerRadius: size * 0.18)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.7)
            // Pips
            PipLayout(value: displayedValue, size: size)
                .animation(.easeInOut(duration: 0.04), value: displayedValue)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(isRolling && !reduceMotion ? (shakeLeft ? -7 : 7) : restingAngle))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.09), value: shakeLeft)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isRolling)
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                animTask?.cancel()
                // Reduce Motion: skip the cosmetic pip-cycling/shake loop
                // entirely — the die just holds its resting face (already
                // live via `displayedValue`) until the real result lands.
                guard !reduceMotion else { return }
                animTask = Task { @MainActor in
                    while !Task.isCancelled {
                        cyclingValue = Int.random(in: 1...6)
                        shakeLeft.toggle()
                        try? await Task.sleep(nanoseconds: 80_000_000)
                    }
                }
            } else {
                animTask?.cancel(); animTask = nil
                shakeLeft = false
            }
        }
        .onDisappear { animTask?.cancel(); animTask = nil }
    }
}

private struct PipLayout: View {
    let value: Int
    let size: CGFloat

    var body: some View {
        let pip = size * 0.118
        ZStack {
            ForEach(Array(DicePipLayout.positions(for: value).enumerated()), id: \.offset) { _, pos in
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
                    // Flat matte fill — cream for an open tile, the theme's
                    // own (already dark) surface color for a closed one.
                    // Selection is shown only by the accent ring below, not
                    // by swapping the fill to a second bright color — one
                    // restrained accent color, not two competing ones.
                    RoundedRectangle(cornerRadius: cr)
                        .fill(baseFill)

                    RoundedRectangle(cornerRadius: cr)
                        .strokeBorder(isSelected ? theme.accent : theme.text.opacity(tile.isOpen ? 0.16 : 0.10),
                                      lineWidth: isSelected ? 2 : 0.75)

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
                // A soft glow (not a hard shadow) marks the current
                // selection without adding a frame.
                .shadow(color: isSelected ? theme.accent.opacity(0.55) : .clear, radius: 3)
            }
        }
        .buttonStyle(.plain)
        .disabled(!tile.isOpen || !isEnabled)
        .accessibilityLabel(tile.isOpen ? L10n.format("Tile %d, open", tile.id) : L10n.format("Tile %d, closed", tile.id))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var baseFill: Color {
        guard tile.isOpen else { return theme.surface.last ?? Color.black }
        return Color(red: 0.97, green: 0.95, blue: 0.88) // matte cream, every theme
    }

    private var numberColor: Color {
        tile.isOpen
            ? Color(red: 0.16, green: 0.12, blue: 0.06)
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

// MARK: - Deterministic Previews (fixtures, not live gameplay)

/// A static tile grid at a given tile count — the same shape `gameTray(...)`
/// renders, but with fixture tile/selection state instead of a live
/// `GameViewModel`, so every state below is reproducible in the canvas.
private struct WatchTileGridFixture: View {
    let tileCount: Int
    let closedTileIds: Set<Int>
    let selectedTileIds: Set<Int>
    let theme: GameTheme

    private var colCount: Int { tileCount <= 9 ? 3 : 4 }
    private var rowCount: Int { Int(ceil(Double(tileCount) / Double(colCount))) }

    var body: some View {
        let tiles = (1...tileCount).map { Tile(id: $0, isOpen: !closedTileIds.contains($0)) }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: colCount), spacing: 3) {
            ForEach(tiles) { tile in
                WatchTileButton(
                    tile: tile,
                    isSelected: selectedTileIds.contains(tile.id),
                    isEnabled: true,
                    theme: theme,
                    action: {}
                )
                .frame(height: 30)
            }
        }
        .padding(10)
        .background(theme.surface.first ?? .black)
    }
}

#Preview("Tiles — 3x3 Quick Game, waiting") {
    WatchTileGridFixture(tileCount: 9, closedTileIds: [], selectedTileIds: [],
                          theme: .palette(for: .greenFelt))
}

#Preview("Tiles — 4x3 Classic, partial selection") {
    WatchTileGridFixture(tileCount: 12, closedTileIds: [11, 12], selectedTileIds: [3, 4],
                          theme: .palette(for: .greenFelt))
}

#Preview("Tiles — 4x3 Classic, near win") {
    WatchTileGridFixture(tileCount: 12, closedTileIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                          selectedTileIds: [11, 12], theme: .palette(for: .greenFelt))
}

#Preview("Tiles — every theme") {
    VStack(spacing: 8) {
        ForEach(GameThemeName.allCases) { name in
            WatchTileGridFixture(tileCount: 9, closedTileIds: [3, 7], selectedTileIds: [2],
                                  theme: .palette(for: name))
        }
    }
}

#Preview("Dice — resting faces 1-6") {
    HStack(spacing: 6) {
        ForEach(1...6, id: \.self) { face in
            WatchPipDieView(value: face, isRolling: false, size: 26)
        }
    }
    .padding()
    .background(GameTheme.palette(for: .greenFelt).surface.first ?? .black)
}

#Preview("Dice — rolling") {
    HStack(spacing: 6) {
        WatchPipDieView(value: 3, isRolling: true, size: 26)
        WatchPipDieView(value: 5, isRolling: true, size: 26)
    }
    .padding()
    .background(GameTheme.palette(for: .greenFelt).surface.first ?? .black)
}
