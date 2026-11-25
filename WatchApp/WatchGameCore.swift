//
//  WatchGameCore.swift
//  BoxOfDice Watch App
//

import Combine
import Foundation
import SwiftUI
import WatchKit

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }
}

enum GameTypography {
    static func title(size: CGFloat) -> Font {
        .custom("AmericanTypewriter-Bold", size: size, relativeTo: .largeTitle)
    }
    static func display(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .largeTitle)
    }
    static func tileNumber(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .title)
    }
    static func button(size: CGFloat = 18) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: .headline)
    }
    static func label(size: CGFloat = 16) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: .subheadline)
    }
    static func value(size: CGFloat = 16) -> Font {
        .custom("AvenirNextCondensed-Heavy", size: size, relativeTo: .subheadline)
    }
    static func caption(size: CGFloat = 12) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: .caption)
    }
    static func section(size: CGFloat = 12) -> Font {
        .custom("AvenirNextCondensed-Heavy", size: size, relativeTo: .caption)
    }
}

// Tile, MoveRecord, GameState, DiceMode, MoveRule, GameSettings, and GameEngine
// live in BoxOfDice/GameEngine.swift, which this target also compiles (see its
// explicit membership in project.pbxproj) — the pure game model and rules are
// shared verbatim with the iOS target rather than duplicated here.

enum GameMode: String, CaseIterable, Identifiable, Codable {
    // quickGame first so CaseIterable.allCases (the Watch mode picker
    // iterates this directly) lists it first — BOD-011 requires Quick Game
    // to appear first in mode selection.
    case quickGame
    case classic
    case speedRun
    case bigBox
    case bigBoxSpeed
    case passAndPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickGame:    return L10n.string("Quick Game")
        case .classic:      return L10n.string("Classic")
        case .speedRun:     return L10n.string("Speed Run")
        case .bigBox:       return L10n.string("Big Box")
        case .bigBoxSpeed:  return L10n.string("Big Box Speed")
        case .passAndPlay:  return L10n.string("Pass & Play")
        }
    }

    var subtitle: String {
        switch self {
        case .quickGame:    return L10n.string("9 tiles")
        case .classic:      return L10n.string("12 tiles, 2 dice")
        case .speedRun:     return L10n.string("Score plus time")
        case .bigBox:       return L10n.string("18 tiles, 3 dice")
        case .bigBoxSpeed:  return L10n.string("Big box plus time")
        case .passAndPlay:  return L10n.string("2-4 players")
        }
    }

    var tileCount: Int {
        switch self {
        case .quickGame:                        return 9
        case .classic, .speedRun, .passAndPlay: return 12
        case .bigBox, .bigBoxSpeed:              return 18
        }
    }

    var baseDiceCount: Int {
        switch self {
        case .quickGame, .classic, .speedRun, .passAndPlay: return 2
        case .bigBox, .bigBoxSpeed:                          return 3
        }
    }

    /// Quick Game is the only mode that switches down to a single die once
    /// only the low tiles remain (BOD-011).
    var diceMode: DiceMode {
        self == .quickGame ? .oneDieWhenLowTilesRemain : .alwaysTwoDice
    }

    var isTimed: Bool      { self == .speedRun || self == .bigBoxSpeed }
    var isMultiplayer: Bool { self == .passAndPlay }

    func finalScore(baseScore: Int, elapsedSeconds: Int) -> Int {
        baseScore + (isTimed ? elapsedSeconds : 0)
    }

    // MARK: - Watch mode support (single source of truth)

    /// The confirmed Watch-supported mode roster, in the order they should
    /// appear in a picker: Quick Game, Classic, Speed Run, Pass & Play. Big
    /// Box and Big Box Speed are iOS-only (3 dice / 18 tiles doesn't fit the
    /// Watch's screen and controls) and are deliberately excluded here.
    /// Every Watch call site that needs "the modes we offer" — first launch,
    /// both mode pickers, settings, restore, and any mode value that could
    /// arrive from the phone via a shared save — must go through this (and
    /// `normalizedForWatch`) instead of re-deriving its own filter, so the
    /// roster only ever needs to change in one place.
    static let supportedOnWatch: [GameMode] = allCases.filter { $0 != .bigBox && $0 != .bigBoxSpeed }

    /// True for exactly the modes in `supportedOnWatch`.
    var isSupportedOnWatch: Bool { GameMode.supportedOnWatch.contains(self) }

    /// Maps any mode value — including one read back from `@AppStorage`, an
    /// old saved game, or (potentially) phone-synced data — onto a mode this
    /// Watch build can actually present. An unsupported Big Box family value
    /// becomes Classic, mirroring the Watch's existing behavior of playing
    /// Big Box games as Classic (same 12 tiles / 2 dice); every already
    /// Watch-supported mode passes through unchanged, so a user's existing
    /// valid selection is never disturbed.
    static func normalizedForWatch(_ mode: GameMode) -> GameMode {
        mode.isSupportedOnWatch ? mode : .classic
    }

    /// Convenience for the common case of decoding straight from a stored
    /// raw value (`@AppStorage`, a saved game, phone-synced settings). An
    /// unrecognized raw value is treated the same as an unsupported one.
    static func normalizedForWatch(rawValue: String) -> GameMode {
        normalizedForWatch(GameMode(rawValue: rawValue) ?? .classic)
    }
}

/// Pure pip-position map for a die face, extracted out of `PipLayout`
/// (WatchContentView.swift) so the point maps for every face value are
/// unit-testable without a view-inspection library. Coordinates are unit
/// offsets from the die's center; the view scales them to its own size.
enum DicePipLayout {
    static func positions(for value: Int) -> [CGPoint] {
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
}

enum DiceAnimationSpeed: String, CaseIterable, Identifiable {
    case short, normal, long

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short:  return L10n.string("Short")
        case .normal: return L10n.string("Normal")
        case .long:   return L10n.string("Long")
        }
    }

    var rollDurationNanoseconds: UInt64 {
        switch self {
        case .short:  return 250_000_000
        case .normal: return 450_000_000
        case .long:   return 800_000_000
        }
    }
}

enum GameThemeName: String, CaseIterable, Identifiable {
    case classicWood
    case greenFelt
    case midnight
    case highContrast
    case minimalLight
    case darkWalnut

    static let defaultTheme: Self = .midnight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicWood:  return L10n.string("Classic Wood")
        case .greenFelt:    return L10n.string("Green Felt")
        case .midnight:     return L10n.string("Midnight")
        case .highContrast: return L10n.string("High Contrast")
        case .minimalLight: return L10n.string("Minimal Light")
        case .darkWalnut:   return L10n.string("Dark Walnut")
        }
    }
}

enum SettingsStorageKey {
    static let theme                = "settings.theme"          // iPhone theme (synced via WatchConnectivity)
    static let watchTheme           = "watch.theme"             // watch-specific theme override
    static let followiPhoneTheme    = "watch.followiPhoneTheme"
    static let hapticsEnabled       = "settings.hapticsEnabled"
    static let soundsEnabled        = "settings.soundsEnabled"
    static let diceAnimationSpeed   = "settings.diceAnimationSpeed"
    static let showHints            = "settings.showHints"
    /// BOD-012 follow-up: same key name as iOS, but device-local like every
    /// other Watch setting — there is no WatchConnectivity sync for it.
    static let showDiceTotal        = "settings.showDiceTotal"
    static let gameMode             = "settings.gameMode"
    static let passAndPlayPlayerCount = "settings.passAndPlayPlayerCount"

    /// BOD-012: device-local only, like the iOS key of the same name — no
    /// WatchConnectivity sync between the two completion markers.
    static let onboardingCompletedOrSkipped = "settings.onboardingCompletedOrSkipped"
}

enum StatisticsStorageKey {
    static let gamesPlayed          = "statistics.gamesPlayed"
    static let gamesWon             = "statistics.gamesWon"
    static let bestScore            = "statistics.bestScore"
    static let totalScore           = "statistics.totalScore"
    static let perfectClears        = "statistics.perfectClears"
    static let currentWinStreak     = "statistics.currentWinStreak"
    static let bestWinStreak        = "statistics.bestWinStreak"
    static let winningScoreTotal    = "statistics.winningScoreTotal"
    static let losingScoreTotal     = "statistics.losingScoreTotal"
    static let losses               = "statistics.losses"
    static let longestGameTurns     = "statistics.longestGameTurns"
    static let shortestClearTurns   = "statistics.shortestClearTurns"
    static let remainingTileCounts  = "statistics.remainingTileCounts"
    static let bestScoreQuickGame   = "statistics.bestScore.quickGame"
    static let bestScoreClassic     = "statistics.bestScore.classic"
    static let bestScoreSpeedRun    = "statistics.bestScore.speedRun"
    static let bestScoreBigBox      = "statistics.bestScore.bigBox"
    static let bestScoreBigBoxSpeed = "statistics.bestScore.bigBoxSpeed"

    // Per-mode score totals/counts for a post-update average — see the same
    // keys' comment in the iOS target's GameStatistics.swift. Shared literal
    // key strings, so scores recorded on either device read back the same way.
    static let modeScoreTotalQuickGame   = "statistics.modeScoreTotal.quickGame"
    static let modeScoreTotalClassic     = "statistics.modeScoreTotal.classic"
    static let modeScoreTotalSpeedRun    = "statistics.modeScoreTotal.speedRun"
    static let modeScoreTotalBigBox      = "statistics.modeScoreTotal.bigBox"
    static let modeScoreTotalBigBoxSpeed = "statistics.modeScoreTotal.bigBoxSpeed"
    static let modeScoreCountQuickGame   = "statistics.modeScoreCount.quickGame"
    static let modeScoreCountClassic     = "statistics.modeScoreCount.classic"
    static let modeScoreCountSpeedRun    = "statistics.modeScoreCount.speedRun"
    static let modeScoreCountBigBox      = "statistics.modeScoreCount.bigBox"
    static let modeScoreCountBigBoxSpeed = "statistics.modeScoreCount.bigBoxSpeed"
}

// MARK: - GameTheme

struct GameTheme {
    let name: GameThemeName
    let background: [Color]  // full-screen gradient
    let tray: [Color]        // outer tray/frame
    let surface: [Color]     // inner playing surface (slightly recessed)
    let title: [Color]       // title text gradient
    let text: Color
    let accent: Color
    let button: [Color]

    static func palette(for name: GameThemeName) -> GameTheme {
        switch name {
        case .classicWood:
            return GameTheme(
                name: name,
                background: [Color(red: 0.28, green: 0.12, blue: 0.05),
                             Color(red: 0.50, green: 0.26, blue: 0.10)],
                tray:       [Color(red: 0.48, green: 0.24, blue: 0.10),
                             Color(red: 0.68, green: 0.40, blue: 0.18),
                             Color(red: 0.40, green: 0.18, blue: 0.07)],
                surface:    [Color(red: 0.30, green: 0.13, blue: 0.05),
                             Color(red: 0.38, green: 0.17, blue: 0.07)],
                title:      [Color(red: 1.0, green: 0.91, blue: 0.68),
                             Color(red: 0.86, green: 0.56, blue: 0.24)],
                text:        Color(red: 1.0, green: 0.88, blue: 0.62),
                accent:      Color(red: 1.0, green: 0.82, blue: 0.37),
                button:     [Color(red: 1.0, green: 0.82, blue: 0.37),
                             Color(red: 0.88, green: 0.50, blue: 0.12)]
            )
        case .greenFelt:
            return GameTheme(
                name: name,
                background: [Color(red: 0.02, green: 0.16, blue: 0.09),
                             Color(red: 0.06, green: 0.28, blue: 0.16)],
                tray:       [Color(red: 0.22, green: 0.11, blue: 0.04),
                             Color(red: 0.38, green: 0.20, blue: 0.08),
                             Color(red: 0.16, green: 0.08, blue: 0.03)],
                surface:    [Color(red: 0.04, green: 0.22, blue: 0.12),
                             Color(red: 0.06, green: 0.30, blue: 0.16)],
                title:      [Color(red: 0.90, green: 1.0, blue: 0.72),
                             Color(red: 0.46, green: 0.86, blue: 0.40)],
                text:        Color(red: 0.88, green: 1.0, blue: 0.76),
                accent:      Color(red: 0.86, green: 0.74, blue: 0.34),
                button:     [Color(red: 0.94, green: 0.82, blue: 0.40),
                             Color(red: 0.64, green: 0.46, blue: 0.14)]
            )
        case .midnight:
            return GameTheme(
                name: name,
                background: [Color(red: 0.03, green: 0.05, blue: 0.11),
                             Color(red: 0.08, green: 0.10, blue: 0.22)],
                tray:       [Color(red: 0.10, green: 0.13, blue: 0.28),
                             Color(red: 0.18, green: 0.22, blue: 0.42),
                             Color(red: 0.06, green: 0.08, blue: 0.18)],
                surface:    [Color(red: 0.04, green: 0.06, blue: 0.16),
                             Color(red: 0.07, green: 0.10, blue: 0.22)],
                title:      [Color(red: 0.78, green: 0.88, blue: 1.0),
                             Color(red: 0.48, green: 0.62, blue: 0.95)],
                text:        Color(red: 0.82, green: 0.88, blue: 1.0),
                accent:      Color(red: 0.55, green: 0.70, blue: 1.0),
                button:     [Color(red: 0.60, green: 0.74, blue: 1.0),
                             Color(red: 0.32, green: 0.42, blue: 0.84)]
            )
        case .highContrast:
            return GameTheme(
                name: name,
                background: [.black, Color(red: 0.06, green: 0.06, blue: 0.06)],
                tray:       [Color(red: 0.20, green: 0.20, blue: 0.20),
                             Color(red: 0.30, green: 0.30, blue: 0.30),
                             Color(red: 0.14, green: 0.14, blue: 0.14)],
                surface:    [Color(red: 0.07, green: 0.07, blue: 0.07),
                             Color(red: 0.12, green: 0.12, blue: 0.12)],
                title:      [.white, Color(red: 1.0, green: 0.86, blue: 0.20)],
                text:        .white,
                accent:      .yellow,
                button:     [.yellow, Color(red: 0.85, green: 0.62, blue: 0.0)]
            )
        case .minimalLight:
            return GameTheme(
                name: name,
                background: [Color(red: 0.90, green: 0.87, blue: 0.82),
                             Color(red: 0.96, green: 0.94, blue: 0.90)],
                tray:       [Color(red: 0.70, green: 0.56, blue: 0.38),
                             Color(red: 0.84, green: 0.70, blue: 0.50),
                             Color(red: 0.60, green: 0.46, blue: 0.30)],
                surface:    [Color(red: 0.86, green: 0.82, blue: 0.74),
                             Color(red: 0.92, green: 0.88, blue: 0.80)],
                title:      [Color(red: 0.16, green: 0.12, blue: 0.08),
                             Color(red: 0.46, green: 0.32, blue: 0.14)],
                text:        Color(red: 0.20, green: 0.14, blue: 0.08),
                accent:      Color(red: 0.68, green: 0.42, blue: 0.14),
                button:     [Color(red: 0.95, green: 0.70, blue: 0.32),
                             Color(red: 0.72, green: 0.42, blue: 0.12)]
            )
        case .darkWalnut:
            return GameTheme(
                name: name,
                background: [Color(red: 0.05, green: 0.04, blue: 0.03),
                             Color(red: 0.12, green: 0.08, blue: 0.05)],
                tray:       [Color(red: 0.28, green: 0.14, blue: 0.06),
                             Color(red: 0.44, green: 0.24, blue: 0.10),
                             Color(red: 0.20, green: 0.10, blue: 0.04)],
                surface:    [Color(red: 0.10, green: 0.05, blue: 0.02),
                             Color(red: 0.16, green: 0.08, blue: 0.03)],
                title:      [Color(red: 0.96, green: 0.92, blue: 0.84),
                             Color(red: 0.90, green: 0.70, blue: 0.38)],
                text:        Color(red: 0.92, green: 0.88, blue: 0.80),
                accent:      Color(red: 0.94, green: 0.68, blue: 0.22),
                button:     [Color(red: 0.94, green: 0.68, blue: 0.22),
                             Color(red: 0.76, green: 0.40, blue: 0.10)]
            )
        }
    }
}

// MARK: - GameViewModel

@MainActor
final class GameViewModel: ObservableObject {
    @Published private var engine = GameEngine()
    @Published private(set) var isRolling = false
    @Published private(set) var highlightedHint: Set<Int> = []
    @Published private(set) var elapsedSeconds = 0

    /// Bumped after every meaningful action. BOD-006: the view observes this
    /// to know when to persist the current game.
    @Published private(set) var revision: Int = 0

    private var timerTask: Task<Void, Never>?
    private var rollTask: Task<Void, Never>?
    private var gameGeneration: UInt64 = 0
    private var gameStartTime: Date?
    private var isTimed = false
    private var hapticsEnabled = true
    private var diceAnimationSpeed: DiceAnimationSpeed = .normal
    private var rollingDieCount = 2

    /// Test seam (R4 in docs/KORJAUSTEN_TARKISTUS_2026-09-09.md): every
    /// "current time" read in the timer path goes through this instead of
    /// calling `Date()` directly, so a test can freeze/advance time
    /// deterministically instead of racing the real periodic tick's ~250ms
    /// cadence against a real-time sleep. Production code never sets this —
    /// it defaults to the real clock and behaves exactly like `Date()`.
    var now: () -> Date = Date.init

    /// Dice already drawn for a roll not yet committed to the engine (the
    /// animation is still in flight). A save triggered while backgrounding
    /// mid-roll captures this; restore commits it directly.
    private(set) var pendingRollDiceForSaving: [Int]?

    var tiles: [Tile]              { engine.tiles }
    var selectedTiles: Set<Int>    { engine.selectedTiles }
    var gameState: GameState       { engine.gameState }
    var dice: [Int]                { engine.dice }
    var moveHistory: [MoveRecord]  { engine.moveHistory }
    var score: Int                 { engine.score }
    var remainingOpenTiles: [Int]  { engine.openTiles }
    var selectionTotal: Int        { engine.selectionTotal }
    /// Number of dice pips to display at rest. While rolling, this is the
    /// animation's own die count (`rollingDieCount`, fixed at roll start).
    /// Once a roll has landed, it must reflect how many dice were actually
    /// rolled last (`dice`'s active slots) — NOT `engine.currentDieCount`,
    /// which can already describe the *next* roll (e.g. Quick Game dropping
    /// from two dice to one once only low tiles remain). Using the next
    /// roll's count here would silently drop a die from the just-completed
    /// roll's display while the dice-total badge still showed the old sum —
    /// a visible mismatch. Before any roll, there is no "last roll" to
    /// reflect, so this shows the upcoming roll's count as a neutral,
    /// dimmed placeholder instead.
    var dieCount: Int {
        if isRolling { return rollingDieCount }
        if hasRolled { return dice.filter { $0 > 0 }.count }
        return engine.currentDieCount
    }
    var diceTotal: Int             { dice.reduce(0, +) }
    var hasRolled: Bool            { !isRolling && engine.hasRolled }
    var canRoll: Bool              { !isRolling && engine.gameState == .waitingToRoll }
    var canSelectTiles: Bool       { !isRolling && engine.gameState == .selecting }
    var canConfirm: Bool           { !isRolling && engine.canConfirm }
    var canUndo: Bool              { !isRolling && engine.canUndo }
    var turnCount: Int             { engine.turnCount }

    /// Timed modes (Speed Run, Big Box Speed) always animate at the standard
    /// "normal" speed regardless of the user's animation-speed setting, so the
    /// setting cannot be used to shave time off the clock. Untimed modes honour
    /// the user's choice as before.
    var effectiveDiceAnimationSpeed: DiceAnimationSpeed { isTimed ? .normal : diceAnimationSpeed }

    // MARK: - Save/restore (BOD-006)

    var engineSnapshot: GameEngine { engine }
    var gameStartTimeForSaving: Date? { gameStartTime }

    init(feedback: Any? = nil) { newGame() }

    func configure(diceAnimationSpeed: DiceAnimationSpeed, feedbackOptions: FeedbackOptions, isTimed: Bool = false) {
        self.diceAnimationSpeed = diceAnimationSpeed
        self.hapticsEnabled = feedbackOptions.hapticsEnabled
        self.isTimed = isTimed
    }

    func newGame(settings: GameSettings? = nil, seed: UInt64? = nil, isTimed: Bool? = nil) {
        rollTask?.cancel()
        rollTask = nil
        stopTimer()
        gameGeneration += 1
        pendingRollDiceForSaving = nil
        if let isTimed { self.isTimed = isTimed }
        engine.reset(settings: settings, seed: seed)
        rollingDieCount = engine.currentDieCount
        highlightedHint = []
        elapsedSeconds = 0
        gameStartTime  = nil
        isRolling    = false
        revision += 1
    }

    /// Adopts a previously saved engine snapshot in place of the current
    /// game. A pending roll (dice already drawn but not yet committed when
    /// the app was saved, e.g. backgrounded mid-animation) is committed
    /// immediately — never redrawn, and the game is never left stuck
    /// "rolling" forever.
    func restore(engine restoredEngine: GameEngine, pendingRollDice: [Int]?, gameStartTime restoredStartTime: Date?, isTimed restoredIsTimed: Bool) {
        rollTask?.cancel()
        rollTask = nil
        stopTimer()
        gameGeneration += 1
        pendingRollDiceForSaving = nil

        engine = restoredEngine
        isTimed = restoredIsTimed
        highlightedHint = []
        isRolling = false
        rollingDieCount = engine.currentDieCount

        if let pendingRollDice, case .waitingToRoll = engine.gameState {
            engine.roll(dice: pendingRollDice)
        }

        if isTimed, let restoredStartTime, !engine.isGameOver {
            gameStartTime = restoredStartTime
            elapsedSeconds = Int(now().timeIntervalSince(restoredStartTime))
            beginTimerLoop()
        } else {
            gameStartTime = nil
            elapsedSeconds = 0
        }
        revision += 1
    }

    func rollDice() {
        guard canRoll else { invalidFeedback(); return }
        if isTimed && gameStartTime == nil { startTimer() }
        highlightedHint = []
        isRolling = true
        rollingDieCount = engine.currentDieCount
        let finalDice = engine.randomDice()
        pendingRollDiceForSaving = finalDice
        let rollDuration = effectiveDiceAnimationSpeed.rollDurationNanoseconds
        let generation = gameGeneration
        rollTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: rollDuration)
            guard let self, !Task.isCancelled, self.gameGeneration == generation else { return }
            self.engine.roll(dice: finalDice)
            self.pendingRollDiceForSaving = nil
            self.isRolling = false
            if case .gameOver = self.engine.gameState { self.stopTimer() }
            self.rollFeedback()
            self.revision += 1
        }
    }

    /// The tile-tray gesture (magnify-on-drag) and each tile's own Button
    /// both call this for a plain tap — by design, so the Button's action
    /// still works for VoiceOver activation (which never goes through the
    /// drag gesture) while the gesture handles sighted taps and magnify.
    /// `highPriorityGesture` is documented to suppress a view's own gesture
    /// for the same touch, so in practice exactly one of the two fires; this
    /// tracks the immediately-preceding toggle as a second, independent
    /// safeguard so a genuine double-fire can never double-toggle (select
    /// then immediately deselect) the same tile.
    private var lastToggle: (tileId: Int, time: Date)?

    func toggleTile(_ number: Int) {
        guard canSelectTiles, engine.tiles.first(where: { $0.id == number })?.isOpen == true else {
            invalidFeedback(); return
        }
        if let last = lastToggle, last.tileId == number, now().timeIntervalSince(last.time) < 0.05 {
            return
        }
        lastToggle = (number, now())
        highlightedHint = []
        engine.toggleTile(number)
        clickFeedback()
        revision += 1
    }

    func confirmSelection() {
        guard canConfirm else { invalidFeedback(); return }
        engine.confirmSelection()
        highlightedHint = []
        if case .gameOver(true) = engine.gameState {
            stopTimer()
            successFeedback()
        } else {
            clickFeedback()
        }
        revision += 1
    }

    func showHint() {
        guard canSelectTiles, let hint = engine.bestHint() else { invalidFeedback(); return }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.7)) {
            highlightedHint = Set(hint)
        }
        clickFeedback()
    }

    func undoLastMove() {
        guard canUndo else { invalidFeedback(); return }
        engine.undoLastMove()
        highlightedHint = []
        clickFeedback()
        revision += 1
    }

    func diceSettledFeedback() {}

    /// Called when the app moves to the background. A roll in flight has
    /// already drawn its final dice (`pendingRollDiceForSaving`) — this
    /// commits that same result immediately instead of leaving the
    /// animation's sleep timer (and each die's cosmetic pip-cycling task)
    /// running while suspended. This never changes the actual result, only
    /// how soon it's applied; it mirrors what `restore(...)` already does
    /// for a pending roll saved mid-animation.
    func handleScenePhaseBackground() {
        guard isRolling, let finalDice = pendingRollDiceForSaving else { return }
        rollTask?.cancel()
        rollTask = nil
        engine.roll(dice: finalDice)
        pendingRollDiceForSaving = nil
        isRolling = false
        if case .gameOver = engine.gameState { stopTimer() }
        revision += 1
    }

    private func startTimer() {
        gameStartTime = now()
        beginTimerLoop()
    }

    /// Starts the periodic elapsed-seconds tick from whatever `gameStartTime`
    /// already is — shared by a fresh `startTimer()` and by `restore(...)`
    /// resuming a timed game's clock from its original (possibly long-past,
    /// even pre-relaunch) start time.
    private func beginTimerLoop() {
        let generation = gameGeneration
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard let self, !Task.isCancelled, self.gameGeneration == generation,
                      let t = self.gameStartTime else { break }
                self.elapsedSeconds = Int(self.now().timeIntervalSince(t))
            }
        }
    }

    private func stopTimer() {
        // Recompute directly from the start time so the final result isn't stale
        // by up to one timer tick's worth of the periodic update below.
        if let start = gameStartTime {
            elapsedSeconds = Int(now().timeIntervalSince(start))
        }
        timerTask?.cancel()
        timerTask = nil
    }

    private func clickFeedback()   { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.click) }
    private func rollFeedback()    { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.directionUp) }
    private func invalidFeedback() { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.failure) }
    private func successFeedback() { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.success) }
}

struct FeedbackOptions {
    var hapticsEnabled = true
    var soundsEnabled  = true
}
