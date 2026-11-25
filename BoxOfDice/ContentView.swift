//
//  ContentView.swift
//  BoxOfDice
//

import StoreKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @ObservedObject private var fullGameStore = FullGameStore.shared
    @State private var isShowingRoundLimit = false
    @State private var isShowingSettings = false
    @State private var isShowingStats = false
    @State private var isShowingModeSelection = false
    @State private var didApplyInitialSettings = false
    @State private var isGameOverVisible = false
    @State private var duoDisplay: DuoDisplay?

    // Celebration state
    @State private var isShowingCelebration = false
    @State private var celebrationOutcome: CelebrationOutcome?

    // Pass & Play state
    @State private var currentPassAndPlayPlayer = 0
    @State private var passAndPlayScores: [Int] = []
    @State private var passAndPlayPlayerCount = 2
    @State private var isShowingPassAndPlayResults = false

    @AppStorage(SettingsStorageKey.gameMode) private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.defaultTheme.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.diceStyle) private var diceStyleRawValue = DiceStyleName.ivory.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    // BOD-012: new installs show the dice sum by default (helps new players
    // connect the roll to the target number); a previous user's explicit
    // `false` still wins, since @AppStorage only falls back to this default
    // when the key has never been written — this is not a forced migration.
    @AppStorage(SettingsStorageKey.showDiceTotal) private var showDiceTotal = true
    @AppStorage(SettingsStorageKey.celebrations) private var celebrationsRaw = CelebrationLevel.on.rawValue
    @AppStorage(SettingsStorageKey.language) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage("hasSelectedInitialGameMode") private var hasSelectedInitialGameMode = false
    @AppStorage("hasSeenScoreOnboardingHint") private var hasSeenScoreOnboardingHint = false
    @AppStorage(SettingsStorageKey.onboardingCompletedOrSkipped) private var onboardingCompletedOrSkipped = false

    // BOD-012: which context the tutorial is showing for, if any — kept
    // entirely separate from the normal game's state. `nil` means the
    // tutorial isn't showing.
    // `OnboardingContext` is shared with the Watch target — it carries the
    // rule for whether the game underneath may be saved (see
    // OnboardingViewModel.swift).
    @State private var onboardingContext: OnboardingContext?

    // Read here only for what ContentView itself needs directly: the
    // onboarding hint check and the celebration's "previous best" lookup.
    // Every other statistics field is written by GameStatisticsRecorder
    // (BOD-005) against the same UserDefaults keys, and read for display
    // only by StatsView.
    @AppStorage(StatisticsStorageKey.gamesPlayed) private var gamesPlayed = 0

    // Per-mode best scores (existing, preserved as-is)
    @AppStorage(StatisticsStorageKey.bestScoreQuickGame) private var bestScoreQuickGame = 0
    @AppStorage(StatisticsStorageKey.bestScoreClassic) private var bestScoreClassic = 0
    @AppStorage(StatisticsStorageKey.bestScoreSpeedRun) private var bestScoreSpeedRun = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBox) private var bestScoreBigBox = 0
    @AppStorage(StatisticsStorageKey.bestScoreBigBoxSpeed) private var bestScoreBigBoxSpeed = 0

    // Guards against recording the same finished game's stats twice (e.g. if
    // the game-over transition were ever observed more than once before a
    // new game starts). Reset whenever a fresh game begins. See
    // GameResultRecordGuard.swift (R3 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
    @State private var resultRecordGuard = GameResultRecordGuard()

    private let horizontalPadding: CGFloat = 12
    private let roundAllowance = DailyRoundAllowance()

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let layout = layoutKind(isLandscape: isLandscape)

            ZStack {
                WoodBackground(colors: theme.background)
                    .ignoresSafeArea()

                if #available(iOS 27.1, *), let panes = duoInnerGamePanes(in: proxy) {
                    if panes.board.midX < panes.controls.midX {
                        twoPaneGameView(
                            boardPane: panes.board,
                            controlsPane: panes.controls,
                            columns: duoBoardColumns,
                            controlScale: 1.4,
                            desiredDieSize: 158,
                            boardFraction: viewModel.tiles.count == 18 ? 0.98 : 0.86,
                            tileHeightRatio: viewModel.tiles.count == 18 ? 1.8 : 1.5,
                            controlSpacing: viewModel.tiles.count == 18 ? 25 : 20,
                            diceSpacing: 0.065,
                            actionTopPadding: 24,
                            showsTitle: true
                        )
                    } else {
                        duoInnerPortraitGameView(boardPane: panes.board, controlsPane: panes.controls,
                                                 isPartiallyOpen: duoDisplay != .fullyOpen)
                    }
                } else if #available(iOS 27.1, *), duoDisplay == .outer {
                    GeometryReader { outer in
                        duoOuterGameView(size: outer.size, isLandscape: outer.size.width > outer.size.height)
                    }
                    // The status bar reserves an entire side on the outer display.
                    // The game sits below it and can use the full width.
                    .ignoresSafeArea(.container, edges: .horizontal)
                } else {
                    switch layout {
                    case .phonePortrait:
                        iPhonePortraitGameView(proxy: proxy)
                    case .phoneLandscape:
                        iPhoneLandscapeGameView(proxy: proxy)
                    case .pad:
                        iPadGameView(proxy: proxy, isLandscape: isLandscape)
                    }
                }

                if isGameOverVisible, case .gameOver = viewModel.gameState {
                    dimBackground
                        .ignoresSafeArea()
                        .transition(.opacity)

                    if #available(iOS 27.1, *), duoDisplay != .fullyOpen,
                       let panes = duoInnerGamePanes(in: proxy) {
                        gameResultCard
                            .frame(width: panes.controls.width, height: panes.controls.height)
                            .position(x: panes.controls.midX, y: panes.controls.midY)
                    } else if #available(iOS 27.1, *), duoDisplay == .outer, isLandscape {
                        gameResultCard
                            .padding(.horizontal, max(proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing))
                            .ignoresSafeArea(.container, edges: .horizontal)
                    } else {
                        gameResultCard
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

                // BOD-012: the tutorial fully covers the normal game — its own
                // board, not a sheet — so it can be a new install's very first
                // screen with no mode menu underneath it.
                if let context = onboardingContext {
                    OnboardingView(
                        theme: theme,
                        diceStyle: diceStyle,
                        isReplay: context == .replay,
                        onFinish: { finishOnboarding(context: context) }
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
            .background {
                if #available(iOS 27.1, *) {
                    Color.clear.onHingeChange { _, context in
                        if context.hinge?.status == .closed {
                            duoDisplay = .outer
                        } else if context.hinge?.status == .fullyOpen {
                            duoDisplay = .fullyOpen
                        } else {
                            duoDisplay = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !didApplyInitialSettings else { return }
            didApplyInitialSettings = true
            configureViewModel()
            beginAppLaunchFlow()
        }
        .task { await fullGameStore.prepare() }
        .task(id: isGameOverVisible) {
            guard isGameOverVisible else { return }
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            requestRoundReviewIfDue()
        }
        .onChange(of: viewModel.revision) { _ in persistCurrentGame() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                viewModel.handleScenePhaseBackground()
                persistCurrentGame()
            }
        }
        .sheet(isPresented: $isShowingModeSelection) {
            GameModeSelectionView(requiresReplacementConfirmation: { hasGameToReplace }) { mode, playerCount in
                startNewGame(mode: mode, playerCount: playerCount)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(onShowHowToPlay: { onboardingContext = .replay })
        }
        .sheet(isPresented: $isShowingStats) {
            StatsView()
        }
        .sheet(isPresented: $isShowingRoundLimit) {
            FullGamePurchaseView(store: fullGameStore, theme: theme, reachedDailyLimit: true)
                .environment(\.locale, appLocale)
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
        .onChange(of: reduceMotion) { _ in configureViewModel() }
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
    private enum DuoDisplay { case outer, fullyOpen }

    private var duoBoardColumns: Int? {
        switch viewModel.tiles.count {
        case 9: return 3
        case 12: return 4
        default: return nil
        }
    }

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

    // MARK: - Duo inner display

    @available(iOS 27.1, *)
    private func duoInnerGamePanes(in proxy: GeometryProxy) -> (board: CGRect, controls: CGRect)? {
        let bounds = CGRect(origin: .zero, size: proxy.size)
        for region in proxy.reservedRegions(kind: .division) {
            let fold = region.frame
            if fold.height > fold.width, fold.minX > 0, fold.maxX < bounds.width {
                return sideBySidePanes(in: bounds, centeredAt: fold.midX, gap: max(20, fold.width))
            }
            if fold.width > fold.height, fold.minY > 0, fold.maxY < bounds.height {
                // In tabletop posture, keep the interactive controls on the lower half.
                return stackedPanes(in: bounds, centeredAt: fold.midY, gap: max(20, fold.height))
            }
        }
        guard duoDisplay == .fullyOpen else { return nil }
        let hinges = proxy.reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
        if bounds.width > bounds.height {
            let hinge = hinges.first { $0.height > $0.width && bounds.minX < $0.midX && $0.midX < bounds.maxX }
            return sideBySidePanes(in: bounds, centeredAt: hinge?.midX ?? bounds.midX, gap: 20)
        }
        let hinge = hinges.first { $0.width > $0.height && $0.minY > 0 && $0.maxY < bounds.height }
        return stackedPanes(in: bounds, centeredAt: hinge?.midY ?? bounds.midY, gap: max(20, hinge?.height ?? 0))
    }

    private func stackedPanes(in bounds: CGRect, centeredAt center: CGFloat, gap: CGFloat)
        -> (board: CGRect, controls: CGRect) {
        let topEdge = max(1, center - gap / 2)
        let bottomEdge = min(bounds.height - 1, center + gap / 2)
        return (
            CGRect(x: 0, y: 0, width: bounds.width, height: topEdge),
            CGRect(x: 0, y: bottomEdge, width: bounds.width, height: bounds.height - bottomEdge)
        )
    }

    private func sideBySidePanes(in bounds: CGRect, centeredAt center: CGFloat, gap: CGFloat)
        -> (board: CGRect, controls: CGRect) {
        let leftEdge = center - gap / 2
        let rightEdge = center + gap / 2
        return (
            CGRect(x: 0, y: 0, width: leftEdge, height: bounds.height),
            CGRect(x: rightEdge, y: 0, width: bounds.width - rightEdge, height: bounds.height)
        )
    }

    private func twoPaneGameView(
        boardPane: CGRect,
        controlsPane: CGRect,
        columns: Int?,
        controlScale: CGFloat,
        desiredDieSize: CGFloat,
        boardFraction: CGFloat,
        tileHeightRatio: CGFloat = 1.5,
        controlSpacing: CGFloat = 12,
        diceSpacing: CGFloat = ContentView.diceSpacingFactor,
        actionTopPadding: CGFloat = 0,
        showsTitle: Bool = false,
        reservesToolbarSpace: Bool = true
    ) -> some View {
        let padding: CGFloat = 12
        let board = boardSizing(
            forHeight: (boardPane.height - padding * 2) * boardFraction,
            width: (boardPane.width - padding * 2) * boardFraction,
            maxTile: 120,
            columns: columns,
            tileHeightRatio: tileHeightRatio
        )
        let controlsWidth = max(1, controlsPane.width - padding * 2)
        let dieSize = fittingDieSize(desired: desiredDieSize, count: viewModel.dieCount,
                                     available: controlsWidth, spacing: diceSpacing)

        return ZStack(alignment: .topLeading) {
            ScrollView(showsIndicators: false) {
                boardView(width: board.width, maxTileWidth: board.maxTile,
                          numberFontSize: min(40, board.maxTile * 0.55),
                          columns: columns, tileHeightRatio: tileHeightRatio)
                    .padding(.vertical, padding)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: boardPane.height)
            }
            .frame(width: boardPane.width, height: boardPane.height)
            .clipped()
            .position(x: boardPane.midX, y: boardPane.midY)

            ScrollView(showsIndicators: false) {
                VStack(spacing: controlSpacing * controlScale) {
                    phoneLandscapeHeader(scale: controlScale, showsTitle: showsTitle)
                    diceSection(dieSize: dieSize, scale: controlScale, spacing: diceSpacing)
                    actionButton(scale: controlScale)
                        .padding(.top, actionTopPadding)
                    secondaryToolBar(scale: controlScale, reservesSpace: reservesToolbarSpace)
                }
                .frame(width: controlsWidth)
                .padding(.vertical, padding)
                .frame(maxWidth: .infinity)
                .frame(minHeight: controlsPane.height)
            }
            .frame(width: controlsPane.width, height: controlsPane.height)
            .clipped()
            .position(x: controlsPane.midX, y: controlsPane.midY)
        }
    }

    @available(iOS 27.1, *)
    @ViewBuilder
    private func duoOuterGameView(size: CGSize, isLandscape: Bool) -> some View {
        if isLandscape {
            let sideMargin: CGFloat = 24
            let availableWidth = size.width - sideMargin * 2
            let boardWidth = availableWidth * 0.56
            let topMargin: CGFloat = 24
            let paneHeight = max(1, size.height - topMargin)
            twoPaneGameView(
                boardPane: CGRect(x: sideMargin, y: topMargin, width: boardWidth, height: paneHeight),
                controlsPane: CGRect(x: sideMargin + boardWidth, y: topMargin,
                                     width: availableWidth - boardWidth, height: paneHeight),
                columns: currentGameMode == .quickGame ? 3 : nil,
                controlScale: 1.1,
                desiredDieSize: 100,
                boardFraction: 0.92,
                reservesToolbarSpace: false
            )
        } else {
            duoOuterPortraitGameView(size: size)
        }
    }

    @available(iOS 16.0, *)
    private func duoOuterPortraitGameView(size: CGSize) -> some View {
        let width = max(1, min(370, size.width - 36))
        let isQuickGame = currentGameMode == .quickGame
        let columns = isQuickGame ? 3 : 6
        let tileHeightRatio: CGFloat = isQuickGame ? 1.27 : (viewModel.tiles.count == 18 ? 1.32 : 1.6)
        let boardHeight: CGFloat = 282
        let board = boardSizing(forHeight: boardHeight, width: width, maxTile: isQuickGame ? 46 : 68,
                                columns: columns, tileHeightRatio: tileHeightRatio)
        let dieSize = fittingDieSize(desired: 96, count: 3, available: width)

        // Give shared controls the same position across modes and turn phases.
        let content = VStack(spacing: 0) {
            portraitHeader(scale: 1, scoreHeight: 47)
                .frame(maxWidth: 290)
                .frame(height: 88, alignment: .top)
            boardView(width: board.width, maxTileWidth: board.maxTile, columns: columns,
                      tileHeightRatio: tileHeightRatio)
                .frame(height: boardHeight)
            diceSection(dieSize: dieSize)
                .frame(height: 120, alignment: .top)
                .padding(.top, 5)
            actionButton(scale: 1, closeButtonMinHeight: 58)
                .frame(height: 90, alignment: .bottom)
            secondaryToolBar(scale: 1, reservesSpace: true)
                .padding(.top, 4)
        }
        .frame(width: width)
        .padding(.top, 42)
        .fixedSize(horizontal: false, vertical: true)

        return ViewThatFits(in: .vertical) {
            content
            ScrollView(showsIndicators: false) {
                content.frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @available(iOS 16.0, *)
    private func duoInnerPortraitGameView(boardPane: CGRect, controlsPane: CGRect,
                                          isPartiallyOpen: Bool) -> some View {
        let width = max(1, min(480, boardPane.width - 36))
        let hasTwelveTiles = viewModel.tiles.count == 12
        let columns = hasTwelveTiles ? 6 : duoBoardColumns
        let tileHeightRatio: CGFloat = hasTwelveTiles ? 1.5 : (columns == 3 ? 1.35 : 1.25)
        let headerHeight: CGFloat = 88
        let upperSpacing: CGFloat = 8
        let boardHeight = max(210, min(325, boardPane.height - headerHeight - upperSpacing * 3))
        let boardInset: CGFloat = hasTwelveTiles && isPartiallyOpen ? 12 : 0
        let board = boardSizing(forHeight: boardHeight - boardInset, width: width, maxTile: 68,
                                columns: columns, tileHeightRatio: tileHeightRatio)
        let dieSize = fittingDieSize(desired: 116, count: 3, available: width)

        let upperContent = VStack(spacing: upperSpacing) {
            portraitHeader(scale: 1, scoreHeight: 47)
                .frame(maxWidth: 290)
                .frame(height: headerHeight, alignment: .top)
            boardView(width: board.width, maxTileWidth: board.maxTile, columns: columns,
                      tileHeightRatio: tileHeightRatio)
                .frame(height: boardHeight)
        }
        .padding(.bottom, upperSpacing)
        .frame(maxWidth: .infinity)
        let lowerContent = VStack(spacing: 0) {
            diceSection(dieSize: dieSize)
                .frame(height: 140, alignment: .top)
            actionButton(scale: 1, closeButtonMinHeight: 58)
                .frame(height: 90, alignment: .bottom)
            secondaryToolBar(scale: 1, reservesSpace: true)
                .padding(.top, 4)
        }
        .frame(width: width)
        .padding(.top, 44)

        return ZStack(alignment: .topLeading) {
            ViewThatFits(in: .vertical) {
                upperContent.fixedSize(horizontal: false, vertical: true)
                ScrollView(showsIndicators: false) { upperContent }
            }
            .frame(width: boardPane.width, height: boardPane.height)
            .position(x: boardPane.midX, y: boardPane.midY)

            ViewThatFits(in: .vertical) {
                lowerContent.fixedSize(horizontal: false, vertical: true)
                ScrollView(showsIndicators: false) { lowerContent.frame(maxWidth: .infinity) }
            }
            .frame(width: controlsPane.width, height: controlsPane.height, alignment: .top)
            .position(x: controlsPane.midX, y: controlsPane.midY)
        }
    }

    // MARK: - iPhone portrait

    @ViewBuilder
    private func iPhonePortraitGameView(proxy: GeometryProxy) -> some View {
        let scale = layoutScale(.phonePortrait)
        let columnWidth = min(430, proxy.size.width)

        ScrollView(showsIndicators: false) {
            VStack(spacing: spacing(for: proxy.size.height)) {
                portraitHeader(scale: scale)
                    .padding(.top, 12)

                boardView(width: columnWidth - horizontalPadding * 2, maxTileWidth: 68, numberFontSize: 27 * scale)

                diceSection()

                VStack(spacing: 6) {
                    actionButton(scale: scale)
                        .frame(minHeight: 92)
                    secondaryToolBar(scale: scale, reservesSpace: true)
                }
                .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 12))
            }
            .frame(maxWidth: 430)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
            // Match the onboarding screen's vertical centering when the game
            // fits. Taller content still scrolls normally on smaller phones.
            .frame(minHeight: proxy.size.height, alignment: .center)
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
        let heightConstrainedDie = max(40, min(76, (usableHeight - 195) / 1.35))
        let dieSize = min(heightConstrainedDie, fittingDieSize(desired: 76, count: viewModel.dieCount, available: panelWidth - 6))

        HStack(alignment: .center, spacing: 16) {
            // Left: the tray, centred vertically in the available height.
            boardView(width: board.width, maxTileWidth: board.maxTile, numberFontSize: 27 * scale)
                .frame(maxWidth: .infinity)

            // Right: compact header with stats/settings, dice, action, secondary row.
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    phoneLandscapeHeader(scale: scale)
                    diceSection(dieSize: dieSize, scale: scale)
                    actionButton(scale: scale)
                    secondaryToolBar(scale: scale)
                }
                .frame(width: panelWidth)
                .frame(minHeight: usableHeight, alignment: .center)
            }
            .frame(width: panelWidth)
            .frame(maxHeight: usableHeight)
        }
        .padding(.leading, leading)
        .padding(.trailing, trailing)
        .padding(.top, topPad)
        .padding(.bottom, bottomPad)
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
        let dieDesired = min(150, (usableHeight - 260) / 1.4)

        ZStack(alignment: .top) {
            HStack(alignment: .center, spacing: 32) {
                boardView(width: board.width, maxTileWidth: board.maxTile, numberFontSize: 27 * scale)
                    .frame(maxWidth: .infinity)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        scoreModeBlock(scale: scale)
                        diceSection(dieSize: fittingDieSize(desired: dieDesired, count: viewModel.dieCount, available: panelWidth - 8), scale: scale)
                        actionButton(scale: scale)
                        secondaryToolBar(scale: scale)
                    }
                    .frame(width: panelWidth)
                    .frame(minHeight: usableHeight, alignment: .center)
                }
                .frame(width: panelWidth)
                .frame(maxHeight: usableHeight)
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
    private func boardSizing(forHeight availableHeight: CGFloat, width availableWidth: CGFloat,
                             maxTile: CGFloat, columns: Int? = nil, tileHeightRatio: CGFloat = 1.5) -> BoardSizing {
        let cols = columns ?? (viewModel.tiles.count > 10 ? 6 : 5)
        let rows = max(1, Int(ceil(Double(viewModel.tiles.count) / Double(cols))))
        let tileSpacing: CGFloat = 8
        let frameThickness: CGFloat = 16
        let surfaceHorizontalPadding: CGFloat = 10
        let surfaceVerticalPadding: CGFloat = 16
        let gridSpacing: CGFloat = 11
        let fixedHorizontalSpace = frameThickness * 2 + surfaceHorizontalPadding * 2 + tileSpacing * CGFloat(cols - 1)
        let fixedVerticalSpace = frameThickness * 2 + surfaceVerticalPadding * 2 + gridSpacing * CGFloat(rows - 1) + 10
        let tileByHeight = (availableHeight - fixedVerticalSpace) / (CGFloat(rows) * tileHeightRatio)
        let tileByWidth = (availableWidth - fixedHorizontalSpace) / CGFloat(cols)
        let tile = max(28, min(maxTile, tileByHeight, tileByWidth))
        return BoardSizing(width: tile * CGFloat(cols) + fixedHorizontalSpace, maxTile: tile)
    }

    // MARK: - Result overlays

    @ViewBuilder
    private var gameResultCard: some View {
        if currentGameMode.isMultiplayer {
            multiplayerOverlay
        } else {
            GameOverView(
                kind: celebrationOutcome?.resultKind ?? .gameOver,
                tileScore: viewModel.score,
                elapsedSeconds: viewModel.elapsedSeconds,
                isTimed: currentGameMode.isTimed,
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
            diceMode: currentGameMode.diceMode,
            moveRule: .anyCombination
        )
    }

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .defaultTheme)
    }

    // Dice style is chosen independently of the board theme (see
    // DiceStyle.swift) — its own AppStorage key, read the same way as theme.
    private var diceStyle: DiceStyle {
        DiceStyle.palette(for: DiceStyleName(rawValue: diceStyleRawValue) ?? .ivory)
    }

    private var dimBackground: Color {
        theme.name == .minimalLight
            ? Color(red: 20 / 255, green: 16 / 255, blue: 12 / 255).opacity(0.68)
            : Color.black.opacity(0.68)
    }

    private var diceAnimationSpeed: DiceAnimationSpeed {
        DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal
    }

    // MARK: - Header

    // Portrait header: the centred title/score/mode block with the stats & settings
    // buttons pinned in the top corners (same composition the iPhone always had).
    private func portraitHeader(scale: CGFloat, scoreHeight: CGFloat? = nil) -> some View {
        ZStack(alignment: .top) {
            scoreModeBlock(scale: scale, scoreHeight: scoreHeight)
            cornerIcons(scale: scale)
        }
    }

    // Title / score / mode pill — reused by every layout (in the corners on phone
    // portrait/iPad, and at the top of the right column in landscape).
    private func scoreModeBlock(scale: CGFloat, scoreHeight: CGFloat? = nil) -> some View {
        VStack(spacing: 4 * scale) {
            gameTitle(scale: scale)
            headerScoreRow(scale: scale)
                .frame(height: scoreHeight, alignment: .top)
            modePill(scale: scale)
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func gameTitle(scale: CGFloat) -> some View {
        Text("BOX OF DICE")
            .font(GameTypography.section(size: 10 * scale))
            .tracking(3 * scale)
            .foregroundStyle(theme.text.opacity(0.42))
    }

    private func phoneLandscapeHeader(scale: CGFloat, showsTitle: Bool = false) -> some View {
        VStack(spacing: 4 * scale) {
            if showsTitle {
                gameTitle(scale: scale)
            }
            HStack(alignment: .center) {
                headerIconButton(systemName: "chart.bar.fill", label: "Statistics", scale: scale) { isShowingStats = true }
                Spacer()
                modePill(scale: scale)
                Spacer()
                headerIconButton(systemName: "gearshape.fill", label: "Settings", scale: scale) { isShowingSettings = true }
            }
            headerScoreRow(scale: scale)
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
        // Without an explicit width, this HStack (and its Spacer) collapses to
        // its two buttons' intrinsic width whenever nothing else in the same
        // ZStack forces a wider layout — which is exactly the case in the
        // landscape layouts (unlike portrait/iPad, where `scoreModeBlock`
        // sharing the ZStack already stretches it). The buttons then end up
        // centered together instead of pinned to opposite corners.
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func headerScoreRow(scale: CGFloat) -> some View {
        if currentGameMode.isTimed {
            HStack(spacing: 10 * scale) {
                // "Tile score", not "Tiles": the number is the SUM of the open
                // tiles, not how many are open (docs/KIELITARKISTUS_2026-09-10.md).
                // In a timed mode it also must not read as the final score,
                // which is this plus the elapsed seconds shown next to it.
                Text("Tile score: \(viewModel.score)")
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
                // "Remaining" instead of "Score": in a lowest-wins game, an
                // unqualified "Score" reads as something you want to grow.
                // BOD-012 acceptance test expects this exact wording.
                Text(L10n.format("Remaining: %lld", viewModel.score))
                    .font(GameTypography.value(size: 23 * scale))
                    .foregroundStyle(theme.text)
                    .animation(.spring(), value: viewModel.score)
                    .accessibilityLabel(L10n.format("Remaining: %lld", viewModel.score))

                if !hasSeenScoreOnboardingHint && !viewModel.hasRolled && gamesPlayed == 0 {
                    Text("Lower is better")
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

    private func boardView(width: CGFloat, maxTileWidth: CGFloat = 68, numberFontSize: CGFloat = 27,
                           columns columnOverride: Int? = nil, tileHeightRatio: CGFloat = 1.5) -> some View {
        let availableWidth = width
        let columnsCount = columnOverride ?? (viewModel.tiles.count > 10 ? 6 : 5)
        let tileSpacing: CGFloat = 8
        let frameThickness: CGFloat = 16
        let surfaceHorizontalPadding: CGFloat = 10
        let surfaceVerticalPadding: CGFloat = 16
        let fixedHorizontalSpace = frameThickness * 2 + surfaceHorizontalPadding * 2 + tileSpacing * CGFloat(columnsCount - 1)
        let tileWidth = max(28, min(maxTileWidth, (availableWidth - fixedHorizontalSpace) / CGFloat(columnsCount)))
        let tileHeight = tileWidth * tileHeightRatio
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
        let isSelected = viewModel.selectedTiles.contains(tile.id) || viewModel.highlightedHint.contains(tile.id)
        return TileView(
            number: tile.id,
            isOpen: tile.isOpen,
            isSelected: isSelected,
            isEnabled: viewModel.canSelectTiles,
            isMatched: viewModel.selectedTiles.contains(tile.id) && viewModel.canConfirm,
            numberFontSize: numberFontSize,
            closeDelay: closeStaggerDelay(for: tile.id),
            onTap: { viewModel.toggleTile(tile.id) }
        )
    }

    /// A small, capped per-tile delay so several tiles closing from the same
    /// confirmed move flap down as a light stagger rather than all at once —
    /// capped at 6 tiles' worth so a large close (Big Box can close many
    /// tiles in one move) never drags the flap out. Purely cosmetic: the
    /// engine already closed every one of these tiles synchronously at
    /// confirm time, independent of this delay or whether the animation
    /// ever finishes (e.g. the view disappearing mid-flip).
    private func closeStaggerDelay(for tileId: Int) -> TimeInterval {
        guard let lastMove = viewModel.moveHistory.last,
              let index = lastMove.closedTiles.firstIndex(of: tileId) else { return 0 }
        return Double(min(index, 6)) * 0.045
    }

    // MARK: - Dice

    // Gap between dice as a fraction of die size, kept tight so a 3-dice row reads
    // as a compact group rather than a spread-out line.
    private static let diceSpacingFactor: CGFloat = 13.0 / 108.0

    // Largest die that lets `count` dice (plus the gaps between them) fit within
    // `available` width — prevents the Big Box 3-dice row from spilling onto the board.
    private func fittingDieSize(desired: CGFloat, count: Int, available: CGFloat,
                                spacing: CGFloat = ContentView.diceSpacingFactor) -> CGFloat {
        guard count > 0 else { return desired }
        let rowFactor = CGFloat(count) + CGFloat(count - 1) * spacing
        return max(40, min(desired, available / rowFactor))
    }

    private func diceSection(dieSize: CGFloat = 108, scale: CGFloat = 1.0,
                             spacing: CGFloat = ContentView.diceSpacingFactor) -> some View {
        VStack(spacing: 8 * scale) {
            HStack(alignment: .center, spacing: dieSize * spacing) {
                ForEach(0..<viewModel.dieCount, id: \.self) { index in
                    Dice3DView(
                        value: viewModel.dice[index],
                        isRolling: viewModel.isRolling,
                        dieIndex: index,
                        rollDuration: viewModel.effectiveDiceAnimationSpeed.tumbleDuration,
                        style: diceStyle,
                        reduceMotion: reduceMotion,
                        onSettled: index == 0 ? { viewModel.diceSettledFeedback() } : nil
                    )
                    .frame(width: dieSize, height: dieSize)
                    .accessibilityLabel(
                        viewModel.dice[index] > 0
                            ? L10n.format("Die showing %lld", viewModel.dice[index])
                            : L10n.string("Die not rolled")
                    )
                    // Soft contact shadow rendered behind the die — a blurred,
                    // edge-free ellipse that grounds it on the table without
                    // touching any of the SceneKit content.
                    .background(dieContactShadow(dieSize: dieSize))
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Optional pip total, shown once the dice have settled (off by default).
            if showDiceTotal && viewModel.hasRolled && !viewModel.isRolling && viewModel.gameState != .selecting {
                Text(L10n.format("Dice total %lld", viewModel.diceTotal))
                    .font(GameTypography.value(size: 16 * scale))
                    .foregroundStyle(theme.text.opacity(0.86))
                    .transition(.opacity)
            }

            // Quick Game only: explain the drop to a single die, so it doesn't
            // read as a bug. `viewModel.dieCount` already stays fixed at the
            // roll's own die count for its whole duration (roll + selection),
            // so this can only ever change between turns, never mid-roll.
            if currentGameMode == .quickGame && viewModel.dieCount == 1 {
                Text(L10n.string("One die now — only low tiles remain"))
                    .font(.system(size: 12 * scale, weight: .medium))
                    .foregroundStyle(theme.text.opacity(0.62))
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

    private func secondaryToolBar(scale: CGFloat, reservesSpace: Bool = false) -> some View {
        // Hint is only meaningful while selecting tiles. The strip collapses to
        // nothing when there's nothing to show.
        let showHintButton = showHints && viewModel.canSelectTiles

        // Quiet, almost text-only secondary action so it never pulls focus from
        // the gold Confirm button.
        let hintTint = theme.text.opacity(0.80)

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
        .frame(height: showHintButton || reservesSpace ? max(44, 36 * scale) : 0)
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
                    .font(.system(size: 14 * scale, weight: .medium))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 15 * scale)
            .padding(.vertical, 7 * scale)
            .frame(minHeight: 44)
            .background(Color.black.opacity(backgroundOpacity), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action button

    @ViewBuilder
    private func actionButton(scale: CGFloat, closeButtonMinHeight: CGFloat = 54) -> some View {
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
            selectingActionZone(scale: scale, buttonMinHeight: closeButtonMinHeight)
        case .gameOver:
            EmptyView()
        }
    }

    private func rollButton(scale: CGFloat) -> some View {
        let canRoll = viewModel.canRoll && fullGameStore.hasCheckedEntitlements
        return Button(action: beginRound) {
            HStack(spacing: 10 * scale) {
                if !viewModel.isRolling {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 18 * scale, weight: .bold))
                }
                Text(L10n.string(viewModel.isRolling ? "Rolling..." : "Roll Dice"))
                    .font(.system(size: 19 * scale, weight: .semibold))
            }
            .frame(maxWidth: 260 * scale)
            .frame(height: 58 * scale)
        }
        .buttonStyle(BoardGameButtonStyle(isEnabled: canRoll, tint: .amber))
        .disabled(!canRoll)
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

    private func selectingActionZone(scale: CGFloat, buttonMinHeight: CGFloat) -> some View {
        let isMatch = viewModel.canConfirm
        // The target appears only here; preserve the preference to hide totals.
        let selection = showDiceTotal
            ? L10n.format("Selected %lld / %lld", viewModel.selectionTotal, viewModel.diceTotal)
            : L10n.format("Selected %lld", viewModel.selectionTotal)

        return VStack(spacing: 12 * scale) {
            Text(selection)
                .font(.system(size: 17 * scale, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
                .accessibilityValue(isMatch ? L10n.string("Ready to close") : "")

            Button(action: viewModel.confirmSelection) {
                HStack(spacing: 8 * scale) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16 * scale, weight: .bold))
                    Text(L10n.string("Close tiles"))
                        .font(.system(size: 18 * scale, weight: .semibold))
                }
                .frame(maxWidth: 280 * scale)
                .frame(minHeight: buttonMinHeight * scale)
            }
            .buttonStyle(BoardGameButtonStyle(isEnabled: isMatch, tint: .amber))
            .disabled(!isMatch)
            .shadow(color: theme.accent.opacity(isMatch ? 0.18 : 0), radius: 8, y: 2)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isMatch)
    }

    // MARK: - Game flow

    private var hasGameToReplace: Bool {
        if currentGameMode.isMultiplayer && !isShowingPassAndPlayResults {
            if currentPassAndPlayPlayer > 0 || !passAndPlayScores.isEmpty { return true }
            if case .gameOver = viewModel.gameState { return true }
        }
        if case .gameOver = viewModel.gameState { return false }
        return viewModel.hasRolled || viewModel.isRolling
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
        guard canStartAnotherRound() else { return }
        startNewGame(mode: currentGameMode, playerCount: passAndPlayPlayerCount)
    }

    private func advanceToNextPlayer() {
        passAndPlayScores.append(viewModel.score)
        currentPassAndPlayPlayer += 1
        configureViewModel()
        beginNewViewModelGame(settings: currentSettings, isTimed: false)
    }

    private func canStartAnotherRound() -> Bool {
        guard fullGameStore.hasCheckedEntitlements else { return false }
        guard roundAllowance.canStartRound(isUnlocked: fullGameStore.isUnlocked) else {
            isShowingRoundLimit = true
            return false
        }
        return true
    }

    private func beginRound() {
        // Initial roll only. Automatic rolls and restored rounds already in play
        // continue through the view model without consuming another round.
        guard viewModel.canRoll, !viewModel.hasRolled, fullGameStore.hasCheckedEntitlements else { return }
        guard roundAllowance.startRound(isUnlocked: fullGameStore.isUnlocked) else {
            isShowingRoundLimit = true
            return
        }
        viewModel.rollDice()
        persistCurrentGame()
    }

    private func requestRoundReviewIfDue() {
        guard scenePhase == .active, isGameOverVisible,
              !isShowingRoundLimit, !isShowingSettings, !isShowingStats,
              fullGameStore.hasCheckedEntitlements, !fullGameStore.isProcessing,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive && $0.windows.contains(where: \.isKeyWindow) }),
              roundAllowance.takeReviewRequest(isUnlocked: fullGameStore.isUnlocked) else { return }

        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - Launch routing (BOD-012)

    /// Decides what a fresh launch shows, in priority order: (1) a
    /// restorable in-progress game always wins — BOD-006 says so
    /// explicitly; (2) any existing signal of prior use (a previously
    /// chosen mode, or any recorded game) means this is a returning user,
    /// who is never forced into the tutorial, even if the dedicated
    /// onboarding-completed flag happens to be unset for some reason (e.g.
    /// it didn't exist in their installed version yet); (3) only a
    /// genuinely fresh install — no save, no prior-use signal, tutorial not
    /// yet completed/skipped — sees the tutorial. The old "always open the
    /// mode-selection sheet on first launch" behaviour is gone; the
    /// tutorial (for new users) or the last-used mode (for returning users)
    /// replaces it.
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

    /// Called when the tutorial finishes, however it finished (the closing
    /// prompt's button, or Skip — both do the same thing at this point).
    private func finishOnboarding(context: OnboardingContext) {
        onboardingContext = nil
        guard context == .firstLaunch else { return } // .replay: the game underneath is untouched
        onboardingCompletedOrSkipped = true
        hasSelectedInitialGameMode = true
        gameModeRaw = GameMode.classic.rawValue
        configureViewModel()
        beginNewViewModelGame(
            settings: GameSettings.from(mode: .classic, diceMode: GameMode.classic.diceMode, moveRule: .anyCombination),
            isTimed: false
        )
    }

    /// Starts a fresh game on the view model and clears the "already recorded
    /// this game's result" guard, so the next completed game can be recorded
    /// exactly once. All `viewModel.newGame(...)` calls should go through here.
    private func beginNewViewModelGame(settings: GameSettings, isTimed: Bool) {
        resultRecordGuard.reset()
        viewModel.newGame(settings: settings, isTimed: isTimed)
        // The new game replaces whatever was saved for the previous one —
        // `viewModel.newGame` already bumped `revision`, so `persistCurrentGame()`
        // will run from the `.onChange(of: viewModel.revision)` handler, but
        // save right away too so a save never lags behind a fast double-tap
        // (e.g. New Game tapped twice) into a new game's own next action.
        persistCurrentGame()
    }

    // MARK: - Save/restore (BOD-006)

    /// Attempts to resume a previously saved in-progress game. Returns
    /// `true` if a game was restored — the caller must not also start a
    /// fresh one in that case. Any failure (no save, unreadable file,
    /// corrupt/unrecognized JSON) is already handled inside
    /// `GameSaveStore.load()`, which returns `nil`; this simply falls
    /// through to the caller starting a fresh game.
    private func restoreSavedGameIfAny() -> Bool {
        guard let saved = GameSaveStore.load() else { return false }

        gameModeRaw = saved.gameMode.rawValue
        passAndPlayPlayerCount = saved.passAndPlayPlayerCount
        currentPassAndPlayPlayer = saved.currentPassAndPlayPlayer
        passAndPlayScores = saved.passAndPlayScores
        hasSelectedInitialGameMode = true
        resultRecordGuard.reset()

        viewModel.restore(
            engine: saved.engine,
            pendingRollDice: saved.pendingRollDice,
            gameStartTime: saved.gameStartTime,
            isTimed: saved.gameMode.isTimed
        )
        return true
    }

    /// Persists the current in-progress game: mode/rules, full engine state
    /// (tiles, dice, selection, phase, move history, and the random
    /// generator's exact progress so future rolls don't change because of
    /// the save), any roll already drawn but not yet committed (the app was
    /// backgrounded mid-animation), the timed clock's real start time (so
    /// backgrounded/quit time still counts toward the result), and local
    /// Pass & Play progress. A finished game has nothing left to resume —
    /// and its stats are already recorded — so its save is cleared instead,
    /// which also guarantees a finished game's stats can never be recorded
    /// a second time by restoring it.
    private func persistCurrentGame() {
        // BOD-012 follow-up (docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §1):
        // never write the untouched Classic game sitting underneath the
        // first-launch tutorial — see `OnboardingContext`.
        if let onboardingContext, !onboardingContext.allowsPersistingUnderlyingGame { return }
        let isReturningUser = hasSelectedInitialGameMode || gamesPlayed > 0
        if !onboardingCompletedOrSkipped && !isReturningUser { return }

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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowingPassAndPlayResults = true
        }
    }

    private func configureViewModel() {
        viewModel.configure(
            diceAnimationSpeed: diceAnimationSpeed,
            feedbackOptions: FeedbackOptions(hapticsEnabled: hapticsEnabled, soundsEnabled: soundsEnabled),
            isTimed: currentGameMode.isTimed,
            reduceMotion: reduceMotion
        )
    }

    private func handleGameOver(won: Bool) {
        guard resultRecordGuard.recordIfNeeded() else { return }
        if fullGameStore.hasCheckedEntitlements {
            roundAllowance.recordCompletedRound(isUnlocked: fullGameStore.isUnlocked)
        } else {
            // A saved roll can finish as soon as the app opens, while StoreKit
            // is still resolving whether the player owns the full version.
            Task {
                await fullGameStore.prepare()
                if fullGameStore.hasCheckedEntitlements {
                    roundAllowance.recordCompletedRound(isUnlocked: fullGameStore.isUnlocked)
                }
            }
        }
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

    private var currentModeBestScore: Int? {
        switch currentGameMode {
        case .quickGame:    return storedBestScore(bestScoreQuickGame, key: StatisticsStorageKey.bestScoreQuickGame)
        case .classic:      return storedBestScore(bestScoreClassic, key: StatisticsStorageKey.bestScoreClassic)
        case .speedRun:     return storedBestScore(bestScoreSpeedRun, key: StatisticsStorageKey.bestScoreSpeedRun)
        case .bigBox:       return storedBestScore(bestScoreBigBox, key: StatisticsStorageKey.bestScoreBigBox)
        case .bigBoxSpeed:  return storedBestScore(bestScoreBigBoxSpeed, key: StatisticsStorageKey.bestScoreBigBoxSpeed)
        case .passAndPlay:  return nil
        }
    }

    private func storedBestScore(_ score: Int, key: String) -> Int? {
        UserDefaults.standard.object(forKey: key) == nil ? nil : score
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
    /// Approximate time for the winning move's closing tile flap(s) —
    /// including the stagger from `closeStaggerDelay` — to finish, so the
    /// celebration never starts on top of a tile still visibly closing.
    /// Reduce Motion's tile transition is much shorter, so this shrinks to
    /// match rather than adding a needless extra wait.
    private var lastMoveCloseAnimationTailNanoseconds: UInt64 {
        guard let lastMove = viewModel.moveHistory.last else { return 0 }
        if reduceMotion { return 120_000_000 }
        let lastIndex = max(0, min(lastMove.closedTiles.count, 7) - 1)
        let staggerSeconds = Double(min(lastIndex, 6)) * 0.045
        let flapSeconds = 0.07 + 0.05 + 0.22 // fade + gap + spring settle, see TileView.animateOpenState
        return UInt64((staggerSeconds + flapSeconds) * 1_000_000_000)
    }

    private func presentEndOfGame(won: Bool) {
        let outcome = celebrationOutcome
        let shouldCelebrate = celebrationLevel != .off
            && (outcome?.type ?? .none) != .none

        if shouldCelebrate {
            // A win's celebration must never start before the winning move's
            // own closing tiles finish flapping down — losses don't close
            // any tile (the game ends on an unplayable roll), so their delay
            // is unaffected.
            let delay: UInt64 = won ? max(450_000_000, lastMoveCloseAnimationTailNanoseconds + 80_000_000) : 650_000_000
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
        GameStatisticsRecorder.recordCompletedGame(
            mode: currentGameMode,
            won: won,
            baseScore: viewModel.score,
            elapsedSeconds: viewModel.elapsedSeconds,
            turnCount: viewModel.turnCount,
            remainingOpenTiles: viewModel.remainingOpenTiles
        )
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
