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

    // Celebration state
    @State private var isShowingCelebration = false
    @State private var celebrationOutcome: CelebrationOutcome?

    // Pass & Play state
    @State private var currentPassAndPlayPlayer = 0
    @State private var passAndPlayScores: [Int] = []
    @State private var passAndPlayPlayerCount = 2
    @State private var isShowingPassAndPlayResults = false

    @AppStorage(SettingsStorageKey.gameMode) private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.greenFelt.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    @AppStorage(SettingsStorageKey.showDiceTotal) private var showDiceTotal = false
    @AppStorage(SettingsStorageKey.celebrations) private var celebrationsRaw = CelebrationLevel.on.rawValue
    @AppStorage(SettingsStorageKey.language) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage("hasSelectedInitialGameMode") private var hasSelectedInitialGameMode = false
    @AppStorage("hasSeenScoreOnboardingHint") private var hasSeenScoreOnboardingHint = false

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

    private let horizontalPadding: CGFloat = 12

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let layout = layoutKind(isLandscape: isLandscape)

            ZStack {
                WoodBackground(colors: theme.background)
                    .ignoresSafeArea()

                switch layout {
                case .phonePortrait:
                    iPhonePortraitGameView(proxy: proxy)
                case .phoneLandscape:
                    iPhoneLandscapeGameView(proxy: proxy)
                case .pad:
                    iPadGameView(proxy: proxy, isLandscape: isLandscape)
                }

                if isGameOverVisible, case .gameOver = viewModel.gameState {
                    dimBackground
                        .ignoresSafeArea()
                        .transition(.opacity)

                    if currentGameMode.isMultiplayer {
                        multiplayerOverlay
                    } else {
                        GameOverView(
                            kind: celebrationOutcome?.resultKind ?? .gameOver,
                            tileScore: viewModel.score,
                            elapsedSeconds: viewModel.elapsedSeconds,
                            isTimed: currentGameMode.isTimed,
                            remainingOpenTiles: viewModel.remainingOpenTiles,
                            modeName: currentGameMode.title,
                            isNewBest: celebrationOutcome?.isNewBest ?? false,
                            isFirstScore: celebrationOutcome?.isFirstScore ?? false,
                            previousBest: celebrationOutcome?.previousBest,
                            shareMessage: makeShareMessage(),
                            theme: theme,
                            onNewGame: restartCurrentGame,
                            onSettings: { isShowingSettings = true },
                            onStats: { isShowingStats = true }
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }

                if isShowingCelebration, let outcome = celebrationOutcome {
                    CelebrationView(
                        outcome: outcome,
                        theme: theme,
                        level: celebrationLevel,
                        reduceMotion: reduceMotion,
                        onComplete: celebrationDidComplete
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
        }
        .onAppear {
            guard !didApplyInitialSettings else { return }
            didApplyInitialSettings = true
            configureViewModel()
            viewModel.newGame(settings: currentSettings, isTimed: currentGameMode.isTimed)
            if !hasSelectedInitialGameMode {
                isShowingModeSelection = true
            }
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
                if currentGameMode.isMultiplayer {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isGameOverVisible = true
                    }
                } else {
                    presentEndOfGame(won: won)
                }
            } else {
                isGameOverVisible = false
                isShowingCelebration = false
                celebrationOutcome = nil
            }
        }
        .onChange(of: viewModel.hasRolled) { hasRolled in
            if hasRolled {
                hasSeenScoreOnboardingHint = true
            }
        }
        .onChange(of: diceAnimationSpeedRawValue) { _ in configureViewModel() }
        .onChange(of: hapticsEnabled) { _ in configureViewModel() }
        .onChange(of: soundsEnabled) { _ in configureViewModel() }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.gameState)
        // Reading languageRaw here re-renders the whole UI (and every L10n string)
        // the instant the in-app language changes, and applies the matching locale.
        .environment(\.locale, appLocale)
        .id(languageRaw)
    }

    private var appLocale: Locale {
        let language = AppLanguage(rawValue: languageRaw) ?? .system
        return language == .system ? .current : Locale(identifier: language.rawValue)
    }

    // MARK: - Adaptive layout selection

    private enum LayoutKind { case phonePortrait, phoneLandscape, pad }

    // iPad full-screen is regular width AND regular height. iPhone landscape is always
    // compact height (even on a Max), so it can never be mistaken for an iPad here.
    private func layoutKind(isLandscape: Bool) -> LayoutKind {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .pad
        }
        return isLandscape ? .phoneLandscape : .phonePortrait
    }

    // A single scale knob drives every font, control and spacing so the same themed
    // views render larger on iPad without any per-device colours or duplicated UI.
    private func layoutScale(_ kind: LayoutKind) -> CGFloat {
        switch kind {
        case .phonePortrait: return 1.0
        case .phoneLandscape: return 0.9
        case .pad: return 1.5
        }
    }

    // MARK: - iPhone portrait (unchanged single-column design)

    @ViewBuilder
    private func iPhonePortraitGameView(proxy: GeometryProxy) -> some View {
        let scale = layoutScale(.phonePortrait)
        let columnWidth = min(430, proxy.size.width)

        ScrollView(showsIndicators: false) {
            VStack(spacing: spacing(for: proxy.size.height)) {
                portraitHeader(scale: scale)
                    .padding(.top, max(18, proxy.safeAreaInsets.top + 10))

                boardView(width: columnWidth - horizontalPadding * 2, maxTileWidth: 68, numberFontSize: 27 * scale)

                diceSection()

                VStack(spacing: 6) {
                    actionButton(scale: scale)
                    moveHistorySummary(scale: scale)
                    secondaryToolBar(scale: scale)
                }
                .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
            }
            .frame(maxWidth: 430)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - iPhone landscape (true two-column layout)

    @ViewBuilder
    private func iPhoneLandscapeGameView(proxy: GeometryProxy) -> some View {
        let scale = layoutScale(.phoneLandscape)
        let insets = proxy.safeAreaInsets
        let leading = max(horizontalPadding, insets.leading + 6)
        let trailing = max(horizontalPadding, insets.trailing + 6)
        let topPad = max(8, insets.top)
        let bottomPad = max(8, insets.bottom)

        let usableHeight = proxy.size.height - topPad - bottomPad
        let usableWidth = proxy.size.width - leading - trailing
        let board = boardSizing(forHeight: usableHeight, width: usableWidth * 0.60, maxTile: 66)
        let panelWidth = min(340, usableWidth * 0.40)

        ZStack(alignment: .top) {
            HStack(alignment: .center, spacing: 16) {
                // Left: the tray, centred vertically in the available height.
                boardView(width: board.width, maxTileWidth: board.maxTile, numberFontSize: 27 * scale)
                    .frame(maxWidth: .infinity)

                // Right: compact title/score, dice + target, action, secondary row.
                VStack(spacing: 8) {
                    scoreModeBlock(scale: scale)
                    diceSection(dieSize: fittingDieSize(desired: 88, count: viewModel.dieCount, available: panelWidth - 6), scale: scale)
                    actionButton(scale: scale)
                    secondaryToolBar(scale: scale)
                }
                .frame(width: panelWidth)
            }
            .padding(.leading, leading)
            .padding(.trailing, trailing)
            .padding(.top, topPad)
            .padding(.bottom, bottomPad)

            // Stats / settings stay compact in the safe top corners, clear of content.
            cornerIcons(scale: scale)
                .padding(.leading, max(8, insets.leading + 4))
                .padding(.trailing, max(8, insets.trailing + 4))
                .padding(.top, max(6, insets.top))
        }
    }

    // MARK: - iPad (dedicated large-tabletop layouts)

    @ViewBuilder
    private func iPadGameView(proxy: GeometryProxy, isLandscape: Bool) -> some View {
        if isLandscape {
            iPadLandscapeGameView(proxy: proxy)
        } else {
            iPadPortraitGameView(proxy: proxy)
        }
    }

    @ViewBuilder
    private func iPadPortraitGameView(proxy: GeometryProxy) -> some View {
        let scale = layoutScale(.pad)
        let contentWidth = min(900, proxy.size.width - 64)

        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                portraitHeader(scale: scale)
                    .padding(.top, max(24, proxy.safeAreaInsets.top + 12))

                boardView(width: contentWidth, maxTileWidth: 104, numberFontSize: 27 * scale)

                diceSection(dieSize: 156, scale: scale)

                VStack(spacing: 14) {
                    actionButton(scale: scale)
                    moveHistorySummary(scale: scale)
                    secondaryToolBar(scale: scale)
                }
                .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 16))
            }
            .frame(maxWidth: contentWidth)
            .padding(.horizontal, 24)
            .frame(
                maxWidth: .infinity,
                minHeight: max(0, proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom),
                alignment: .center
            )
        }
    }

    @ViewBuilder
    private func iPadLandscapeGameView(proxy: GeometryProxy) -> some View {
        let scale = layoutScale(.pad)
        let insets = proxy.safeAreaInsets
        let sidePad = max(28, insets.leading)
        let topPad = max(18, insets.top)
        let bottomPad = max(18, insets.bottom)

        let usableWidth = proxy.size.width - sidePad * 2 - 32
        let usableHeight = proxy.size.height - topPad - bottomPad
        let board = boardSizing(forHeight: usableHeight, width: usableWidth * 0.65, maxTile: 116)
        let panelWidth = min(440, usableWidth * 0.35)

        ZStack(alignment: .top) {
            HStack(alignment: .center, spacing: 32) {
                boardView(width: board.width, maxTileWidth: board.maxTile, numberFontSize: 27 * scale)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 18) {
                    scoreModeBlock(scale: scale)
                    diceSection(dieSize: fittingDieSize(desired: 150, count: viewModel.dieCount, available: panelWidth - 8), scale: scale)
                    actionButton(scale: scale)
                    moveHistorySummary(scale: scale)
                    secondaryToolBar(scale: scale)
                }
                .frame(width: panelWidth)
            }
            .padding(.horizontal, sidePad)
            .padding(.top, topPad)
            .padding(.bottom, bottomPad)
            .frame(maxHeight: .infinity, alignment: .center)

            cornerIcons(scale: scale)
                .padding(.horizontal, max(16, insets.leading + 6))
                .padding(.top, max(14, insets.top))
        }
    }

    // MARK: - Board sizing

    private struct BoardSizing {
        let width: CGFloat
        let maxTile: CGFloat
    }

    // Computes a tile size (and the matching tray width) so the board — including the
    // 3-row Big Box variant — fits both the available height and the target width.
    private func boardSizing(forHeight availableHeight: CGFloat, width availableWidth: CGFloat, maxTile: CGFloat) -> BoardSizing {
        let cols = viewModel.tiles.count > 10 ? 6 : 5
        let rows = max(1, Int(ceil(Double(viewModel.tiles.count) / Double(cols))))
        let tileSpacing: CGFloat = 8
        let frameThickness: CGFloat = 16
        let surfaceHorizontalPadding: CGFloat = 10
        let surfaceVerticalPadding: CGFloat = 16
        let gridSpacing: CGFloat = 11
        let fixedHorizontalSpace = frameThickness * 2 + surfaceHorizontalPadding * 2 + tileSpacing * CGFloat(cols - 1)
        let fixedVerticalSpace = frameThickness * 2 + surfaceVerticalPadding * 2 + gridSpacing * CGFloat(rows - 1) + 10
        let tileByHeight = (availableHeight - fixedVerticalSpace) / (CGFloat(rows) * 1.5)
        let tileByWidth = (availableWidth - fixedHorizontalSpace) / CGFloat(cols)
        let tile = max(28, min(maxTile, tileByHeight, tileByWidth))
        return BoardSizing(width: tile * CGFloat(cols) + fixedHorizontalSpace, maxTile: tile)
    }

    // MARK: - Multiplayer overlay

    @ViewBuilder
    private var multiplayerOverlay: some View {
        if isShowingPassAndPlayResults {
            PassAndPlayResultsView(
                scores: passAndPlayScores,
                onNewGame: restartCurrentGame
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

    private var dimBackground: Color {
        theme.name == .minimalLight
            ? Color(red: 20 / 255, green: 16 / 255, blue: 12 / 255).opacity(0.55)
            : Color.black.opacity(0.55)
    }

    private var diceAnimationSpeed: DiceAnimationSpeed {
        DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal
    }

    // MARK: - Header

    // Portrait header: the centred title/score/mode block with the stats & settings
    // buttons pinned in the top corners (same composition the iPhone always had).
    private func portraitHeader(scale: CGFloat) -> some View {
        ZStack(alignment: .top) {
            scoreModeBlock(scale: scale)
            cornerIcons(scale: scale)
        }
    }

    // Title / score / mode pill — reused by every layout (in the corners on phone
    // portrait/iPad, and at the top of the right column in landscape).
    private func scoreModeBlock(scale: CGFloat) -> some View {
        VStack(spacing: 4 * scale) {
            Text("BOX OF DICE")
                .font(GameTypography.section(size: 10 * scale))
                .tracking(3 * scale)
                .foregroundStyle(theme.text.opacity(0.42))
            headerScoreRow(scale: scale)
            modePill(scale: scale)
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func cornerIcons(scale: CGFloat) -> some View {
        HStack {
            headerIconButton(systemName: "chart.bar.fill", label: "Statistics", scale: scale) { isShowingStats = true }
            Spacer()
            headerIconButton(systemName: "gearshape.fill", label: "Settings", scale: scale) { isShowingSettings = true }
        }
    }

    @ViewBuilder
    private func headerScoreRow(scale: CGFloat) -> some View {
        if currentGameMode.isTimed {
            HStack(spacing: 10 * scale) {
                Text("Tiles: \(viewModel.score)")
                    .animation(.spring(), value: viewModel.score)
                if viewModel.hasRolled {
                    Text("·")
                        .opacity(0.35)
                    HStack(spacing: 4 * scale) {
                        Image(systemName: "timer")
                            .font(.system(size: 14 * scale))
                        Text(formattedElapsedTime)
                            .monospacedDigit()
                    }
                }
            }
            .font(GameTypography.value(size: 21 * scale))
            .foregroundStyle(theme.text)
            .animation(.easeInOut(duration: 0.2), value: viewModel.hasRolled)
        } else {
            VStack(spacing: 3 * scale) {
                Text("Score: \(viewModel.score)")
                    .font(GameTypography.value(size: 23 * scale))
                    .foregroundStyle(theme.text)
                    .animation(.spring(), value: viewModel.score)

                if !hasSeenScoreOnboardingHint && !viewModel.hasRolled && gamesPlayed == 0 {
                    Text("Close tiles to lower your score. Lowest score wins.")
                        .font(GameTypography.caption(size: 12 * scale))
                        .foregroundStyle(theme.text.opacity(0.66))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
        }
    }

    private func modePill(scale: CGFloat) -> some View {
        Button { isShowingModeSelection = true } label: {
            HStack(spacing: 5 * scale) {
                Image(systemName: "dice.fill")
                    .font(.system(size: 10 * scale, weight: .semibold))
                Text(currentGameMode.title)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8 * scale, weight: .bold))
                    .opacity(0.7)
            }
            .font(GameTypography.caption(size: 12 * scale))
            .foregroundStyle(theme.text.opacity(0.82))
            .padding(.horizontal, 12 * scale)
            .padding(.vertical, 5 * scale)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.30), Color.black.opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func headerIconButton(systemName: String, label: String, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17 * scale, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.58))
                .frame(width: 40 * scale, height: 40 * scale)
                .background(Color.black.opacity(0.18), in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Board

    private func boardView(width: CGFloat, maxTileWidth: CGFloat = 68, numberFontSize: CGFloat = 27) -> some View {
        let availableWidth = width
        let columnsCount = viewModel.tiles.count > 10 ? 6 : 5
        let tileSpacing: CGFloat = 8
        let frameThickness: CGFloat = 16
        let surfaceHorizontalPadding: CGFloat = 10
        let surfaceVerticalPadding: CGFloat = 16
        let fixedHorizontalSpace = frameThickness * 2 + surfaceHorizontalPadding * 2 + tileSpacing * CGFloat(columnsCount - 1)
        let tileWidth = max(28, min(maxTileWidth, (availableWidth - fixedHorizontalSpace) / CGFloat(columnsCount)))
        let tileHeight = tileWidth * 1.5
        let gridWidth = tileWidth * CGFloat(columnsCount) + tileSpacing * CGFloat(columnsCount - 1)
        let trayWidth = gridWidth + surfaceHorizontalPadding * 2 + frameThickness * 2
        let columns = Array(repeating: GridItem(.fixed(tileWidth), spacing: tileSpacing), count: columnsCount)

        return LazyVGrid(columns: columns, spacing: 11) {
            ForEach(viewModel.tiles) { tile in
                tileButton(for: tile, numberFontSize: numberFontSize)
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

    private func tileButton(for tile: Tile, numberFontSize: CGFloat = 27) -> some View {
        TileView(
            number: tile.id,
            isOpen: tile.isOpen,
            isSelected: viewModel.selectedTiles.contains(tile.id) || viewModel.highlightedHint.contains(tile.id),
            isEnabled: viewModel.canSelectTiles,
            numberFontSize: numberFontSize,
            onTap: { viewModel.toggleTile(tile.id) }
        )
    }

    // MARK: - Dice

    // Gap between dice as a fraction of die size, kept tight so a 3-dice row reads
    // as a compact group rather than a spread-out line.
    private static let diceSpacingFactor: CGFloat = 13.0 / 108.0

    // Largest die that lets `count` dice (plus the gaps between them) fit within
    // `available` width — prevents the Big Box 3-dice row from spilling onto the board.
    private func fittingDieSize(desired: CGFloat, count: Int, available: CGFloat) -> CGFloat {
        guard count > 0 else { return desired }
        let rowFactor = CGFloat(count) + CGFloat(count - 1) * Self.diceSpacingFactor
        return max(40, min(desired, available / rowFactor))
    }

    private func diceSection(dieSize: CGFloat = 108, scale: CGFloat = 1.0) -> some View {
        VStack(spacing: 8 * scale) {
            HStack(alignment: .center, spacing: dieSize * Self.diceSpacingFactor) {
                ForEach(0..<viewModel.dieCount, id: \.self) { index in
                    Dice3DView(
                        value: viewModel.dice[index],
                        isRolling: viewModel.isRolling,
                        dieIndex: index,
                        onSettled: index == 0 ? { viewModel.diceSettledFeedback() } : nil
                    )
                    .frame(width: dieSize, height: dieSize)
                    // Soft contact shadow rendered behind the die — a blurred,
                    // edge-free ellipse that grounds it on the table without
                    // touching any of the SceneKit content.
                    .background(dieContactShadow(dieSize: dieSize))
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Optional pip total, shown once the dice have settled (off by default).
            if showDiceTotal && viewModel.hasRolled && !viewModel.isRolling {
                Text(L10n.format("Dice total %lld", viewModel.diceTotal))
                    .font(GameTypography.value(size: 16 * scale))
                    .foregroundStyle(theme.text.opacity(0.86))
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.78), value: viewModel.dieCount)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRolling)
    }

    // Subtle, edge-free contact shadow that sits under the die's resting base.
    // Pushed low enough that its soft edge feathers out beneath the die instead of
    // hiding behind the die body, and dark enough to read on the green felt.
    private func dieContactShadow(dieSize: CGFloat) -> some View {
        // Scale the shadow with the die so it stays tucked under the base at any size.
        let scale = dieSize / 108
        return Ellipse()
            .fill(
                RadialGradient(
                    colors: [Color.black.opacity(0.42), Color.black.opacity(0.16), Color.clear],
                    center: .center,
                    startRadius: 1,
                    endRadius: 34 * scale
                )
            )
            .frame(width: 86 * scale, height: 22 * scale)
            .blur(radius: 6 * scale)
            .offset(y: 36 * scale)
            .allowsHitTesting(false)
    }

    private var formattedElapsedTime: String {
        let s = viewModel.elapsedSeconds
        let minutes = s / 60
        let seconds = s % 60
        return minutes > 0
            ? "\(minutes):\(String(format: "%02d", seconds))"
            : "\(seconds)s"
    }

    // MARK: - Secondary tool bar (hint)

    private func secondaryToolBar(scale: CGFloat) -> some View {
        // Hint is only meaningful while selecting tiles. The strip collapses to
        // nothing when there's nothing to show.
        let showHintButton = showHints && viewModel.canSelectTiles

        // Quiet, almost text-only secondary action so it never pulls focus from
        // the gold Confirm button.
        let hintTint = theme.text.opacity(0.56)

        return HStack(spacing: 10 * scale) {
            if showHintButton {
                toolPillButton(
                    title: "Hint",
                    systemImage: "lightbulb.fill",
                    tint: hintTint,
                    scale: scale,
                    backgroundOpacity: 0.06,
                    borderOpacity: 0.03,
                    action: viewModel.showHint
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: showHintButton ? 36 * scale : 0)
        .opacity(showHintButton ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: showHintButton)
    }

    private func toolPillButton(
        title: String,
        systemImage: String,
        tint: Color,
        scale: CGFloat = 1.0,
        backgroundOpacity: Double = 0.20,
        borderOpacity: Double = 0.12,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5 * scale) {
                Image(systemName: systemImage)
                    .font(.system(size: 12 * scale, weight: .semibold))
                Text(L10n.string(title))
                    .font(GameTypography.button(size: 14 * scale))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 15 * scale)
            .padding(.vertical, 7 * scale)
            .background(Color.black.opacity(backgroundOpacity), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Move history

    @ViewBuilder
    private func moveHistorySummary(scale: CGFloat) -> some View {
        if let lastMove = viewModel.moveHistory.last {
            Text("Last: closed \(lastMove.closedTiles.map(String.init).joined(separator: ", "))")
                .font(GameTypography.caption(size: 13 * scale))
                .foregroundStyle(theme.text.opacity(0.72))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Action button

    @ViewBuilder
    private func actionButton(scale: CGFloat) -> some View {
        switch viewModel.gameState {
        case .waitingToRoll:
            // The opening throw of a game is manual (the Roll button). Once the
            // dice have been rolled once, every later throw is automatic, so the
            // slot becomes a non-interactive status instead.
            if viewModel.canRoll && !viewModel.hasRolled {
                rollButton(scale: scale)
            } else {
                rollStatus(scale: scale)
            }
        case .selecting:
            selectingActionZone(scale: scale)
        case .gameOver:
            EmptyView()
        }
    }

    private func rollButton(scale: CGFloat) -> some View {
        Button(action: viewModel.rollDice) {
            HStack(spacing: 10 * scale) {
                if !viewModel.isRolling {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 18 * scale, weight: .bold))
                }
                Text(L10n.string(viewModel.isRolling ? "Rolling..." : "Roll Dice"))
                    .font(GameTypography.button(size: 19 * scale))
            }
            .frame(maxWidth: 260 * scale)
            .frame(height: 58 * scale)
        }
        .buttonStyle(BoardGameButtonStyle(isEnabled: viewModel.canRoll, tint: .amber))
        .disabled(!viewModel.canRoll)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRolling)
    }

    // After the opening throw the dice roll automatically (after each confirmed
    // move), so this slot is just a non-interactive "Rolling…" status. The fixed
    // height keeps everything below it from shifting between idle and rolling.
    private func rollStatus(scale: CGFloat) -> some View {
        Group {
            if viewModel.isRolling {
                HStack(spacing: 9 * scale) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 16 * scale, weight: .bold))
                    Text("Rolling...")
                        .font(GameTypography.button(size: 19 * scale))
                }
                .foregroundStyle(theme.text.opacity(0.70))
                .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: 260 * scale)
        .frame(height: 58 * scale)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRolling)
    }

    private func selectingActionZone(scale: CGFloat) -> some View {
        let total = viewModel.selectionTotal
        let isMatch = viewModel.canConfirm
        let isEmpty = viewModel.selectedTiles.isEmpty

        return VStack(spacing: 7 * scale) {
            // Instruction only while nothing is selected — once the player starts
            // tapping, the button itself carries the selected total.
            if isEmpty {
                Text("Select tiles matching the dice")
                    .font(GameTypography.label(size: 15 * scale))
                    .foregroundStyle(theme.text.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            if isMatch {
                Button(action: viewModel.confirmSelection) {
                    HStack(spacing: 8 * scale) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16 * scale, weight: .bold))
                        Text("Confirm")
                            .font(GameTypography.button(size: 20 * scale))
                    }
                    .frame(maxWidth: 280 * scale)
                    .frame(height: 58 * scale)
                }
                .buttonStyle(BoardGameButtonStyle(isEnabled: true, tint: .amber))
                // A warm gold halo radiates around the matched button so it clearly
                // reads as the single most important action on screen.
                .shadow(color: Color(red: 1.0, green: 0.74, blue: 0.24).opacity(0.55), radius: 18, x: 0, y: 0)
                .shadow(color: Color(red: 1.0, green: 0.56, blue: 0.12).opacity(0.40), radius: 7, x: 0, y: 2)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .animation(.spring(response: 0.30, dampingFraction: 0.7), value: isMatch)
            } else {
                // Disabled state is a flat status card — ~15% shorter than the active
                // button, no raised chrome or shadow, so it reads as information
                // rather than something tappable. Held in the same slot so the
                // Hint button and everything below it stay exactly in place.
                Text("Selected \(total)")
                    .font(GameTypography.label(size: 17 * scale))
                    .foregroundStyle(theme.text.opacity(0.72))
                    .frame(maxWidth: 280 * scale)
                    .frame(height: 49 * scale)
                    .background(
                        RoundedRectangle(cornerRadius: 13 * scale)
                            .fill(Color.black.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13 * scale)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .frame(height: 58 * scale)
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isMatch)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isEmpty)
    }

    // MARK: - Game flow

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
        startNewGame(mode: currentGameMode, playerCount: passAndPlayPlayerCount)
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
        // Resolve the celebration BEFORE recording, so we still know the previous
        // best for this mode (recordCompletedGame overwrites it).
        celebrationOutcome = makeCelebrationOutcome(won: won)
        recordCompletedGame(won: won)
    }

    // MARK: - Celebration flow

    private var celebrationLevel: CelebrationLevel {
        CelebrationLevel(rawValue: celebrationsRaw) ?? .on
    }

    private var currentModeBestScore: Int {
        switch currentGameMode {
        case .classic:      return bestScoreClassic
        case .speedRun:     return bestScoreSpeedRun
        case .bigBox:       return bestScoreBigBox
        case .bigBoxSpeed:  return bestScoreBigBoxSpeed
        case .passAndPlay:  return 0
        }
    }

    private func makeCelebrationOutcome(won: Bool) -> CelebrationOutcome {
        let mode = currentGameMode
        let finalScore = mode.finalScore(baseScore: viewModel.score, elapsedSeconds: viewModel.elapsedSeconds)
        return CelebrationOutcome.resolve(
            won: won,
            isClassicMode: mode == .classic,
            tileScore: viewModel.score,
            finalScore: finalScore,
            storedBest: currentModeBestScore,
            tileCount: mode.tileCount,
            modeName: mode.title
        )
    }

    // Reveal the celebration (when enabled) and then the result card, or fall back
    // to the plain delayed result card when celebrations are off / nothing happened.
    private func presentEndOfGame(won: Bool) {
        let outcome = celebrationOutcome
        let shouldCelebrate = celebrationLevel != .off
            && (outcome?.type ?? .none) != .none

        if shouldCelebrate {
            let delay: UInt64 = won ? 450_000_000 : 650_000_000
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: delay)
                guard case .gameOver = viewModel.gameState else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowingCelebration = true
                }
            }
        } else {
            let delay: UInt64 = won ? 700_000_000 : 1_500_000_000
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: delay)
                guard case .gameOver = viewModel.gameState else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isGameOverVisible = true
                }
            }
        }
    }

    private func celebrationDidComplete() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowingCelebration = false
            isGameOverVisible = true
        }
    }

    private func makeShareMessage() -> String {
        let mode = currentGameMode
        let score = currentGameMode.finalScore(baseScore: viewModel.score, elapsedSeconds: viewModel.elapsedSeconds)
        if viewModel.isPerfectClear && mode == .classic {
            return L10n.format("Perfect clear in Box of Dice! 🎲 — %@", mode.title)
        }
        if viewModel.didClearBoard {
            return L10n.format("Cleared the board in Box of Dice 🎲 — %@", mode.title)
        }
        return L10n.format("I scored %lld in Box of Dice 🎲 — %@", score, mode.title)
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
        height < 700 ? 8 : 12
    }
}

// MARK: - Background views

private struct WoodBackground: View {
    let colors: [Color]

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(WoodGrain().opacity(0.30))
            .overlay(
                // Soft warm pool of light up top where the tray sits, falling off to
                // deep shadow at the edges — a vignette that keeps the screen from
                // reading as one flat monochrome wash.
                RadialGradient(
                    colors: [Color.white.opacity(0.12), Color.clear, Color.black.opacity(0.48)],
                    center: UnitPoint(x: 0.5, y: 0.32),
                    startRadius: 40,
                    endRadius: 660
                )
            )
            .overlay(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.30)],
                    startPoint: .center,
                    endPoint: .bottom
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

private struct BoardGameButtonStyle: ButtonStyle {
    enum Tint { case amber, green }

    let isEnabled: Bool
    let tint: Tint

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Color(red: 0.16, green: 0.08, blue: 0.03) : Color(red: 0.92, green: 0.86, blue: 0.74).opacity(0.78))
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.34 : 0.10), lineWidth: 1)
            )
            // Active button casts a strong, lifted shadow so it clearly reads as the
            // primary action; the muted disabled state sits nearly flat.
            .shadow(color: .black.opacity(isEnabled ? 0.34 : 0.12), radius: isEnabled ? 11 : 4, x: 0, y: configuration.isPressed ? 2 : (isEnabled ? 6 : 2))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }

    private var backgroundGradient: LinearGradient {
        guard isEnabled else {
            // Muted dark walnut — readable but plainly inactive, never green/"go".
            return LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.23, blue: 0.16),
                    Color(red: 0.19, green: 0.14, blue: 0.09)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
