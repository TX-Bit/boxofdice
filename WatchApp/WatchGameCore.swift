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

struct Tile: Identifiable, Equatable {
    let id: Int
    var isOpen = true
}

struct MoveRecord: Identifiable {
    let id = UUID()
    let dice: [Int]
    let closedTiles: [Int]
    let scoreAfterMove: Int

    var diceTotal: Int { dice.reduce(0, +) }
}

enum GameState: Equatable {
    case waitingToRoll
    case selecting
    case gameOver(won: Bool)
}

enum GameMode: String, CaseIterable, Identifiable {
    case classic
    case speedRun
    case bigBox
    case bigBoxSpeed
    case passAndPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:      return L10n.string("Classic")
        case .speedRun:     return L10n.string("Speed Run")
        case .bigBox:       return L10n.string("Big Box")
        case .bigBoxSpeed:  return L10n.string("Big Box Speed")
        case .passAndPlay:  return L10n.string("Pass & Play")
        }
    }

    var subtitle: String {
        switch self {
        case .classic:      return L10n.string("12 tiles, 2 dice")
        case .speedRun:     return L10n.string("Score plus time")
        case .bigBox:       return L10n.string("18 tiles, 3 dice")
        case .bigBoxSpeed:  return L10n.string("Big box plus time")
        case .passAndPlay:  return L10n.string("2-4 players")
        }
    }

    var tileCount: Int {
        switch self {
        case .classic, .speedRun, .passAndPlay: return 12
        case .bigBox, .bigBoxSpeed:             return 18
        }
    }

    var baseDiceCount: Int {
        switch self {
        case .classic, .speedRun, .passAndPlay: return 2
        case .bigBox, .bigBoxSpeed:             return 3
        }
    }

    var isTimed: Bool      { self == .speedRun || self == .bigBoxSpeed }
    var isMultiplayer: Bool { self == .passAndPlay }

    func finalScore(baseScore: Int, elapsedSeconds: Int) -> Int {
        baseScore + (isTimed ? elapsedSeconds : 0)
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
}

enum GameThemeName: String, CaseIterable, Identifiable {
    case classicWood
    case greenFelt
    case midnight
    case highContrast
    case minimalLight
    case darkWalnut

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

struct GameSettings: Equatable {
    var tileCount: Int
    var baseDiceCount: Int

    static let `default` = GameSettings(tileCount: 12, baseDiceCount: 2)

    static func from(mode: GameMode) -> GameSettings {
        GameSettings(tileCount: mode.tileCount, baseDiceCount: mode.baseDiceCount)
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
    static let gameMode             = "settings.gameMode"
    static let passAndPlayPlayerCount = "settings.passAndPlayPlayerCount"
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
    static let bestScoreClassic     = "statistics.bestScore.classic"
    static let bestScoreSpeedRun    = "statistics.bestScore.speedRun"
    static let bestScoreBigBox      = "statistics.bestScore.bigBox"
    static let bestScoreBigBoxSpeed = "statistics.bestScore.bigBoxSpeed"
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
    @Published private(set) var tiles: [Tile] = []
    @Published private(set) var selectedTiles: Set<Int> = []
    @Published private(set) var gameState: GameState = .waitingToRoll
    @Published private(set) var dice: [Int] = [0, 0, 0]
    @Published private(set) var isRolling = false
    @Published private(set) var highlightedHint: Set<Int> = []
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var moveHistory: [MoveRecord] = []

    private var settings = GameSettings.default
    private var timerTask: Task<Void, Never>?
    private var rollTask: Task<Void, Never>?
    private var gameStartTime: Date?
    private var isTimed = false
    private var hapticsEnabled = true

    var score: Int             { tiles.filter(\.isOpen).reduce(0) { $0 + $1.id } }
    var remainingOpenTiles: [Int] { tiles.filter(\.isOpen).map(\.id) }
    var selectionTotal: Int    { selectedTiles.reduce(0, +) }
    var dieCount: Int          { settings.baseDiceCount }
    var diceTotal: Int         { dice.reduce(0, +) }
    var hasRolled: Bool        { !isRolling && dice.contains { $0 > 0 } }
    var canRoll: Bool          { !isRolling && gameState == .waitingToRoll }
    var canSelectTiles: Bool   { !isRolling && gameState == .selecting }
    var canConfirm: Bool       { canSelectTiles && !selectedTiles.isEmpty && selectionTotal == diceTotal }
    var canUndo: Bool          { !isRolling && gameState == .waitingToRoll && !moveHistory.isEmpty }
    var turnCount: Int         { moveHistory.count }

    init(feedback: Any? = nil) { newGame() }

    func configure(diceAnimationSpeed: DiceAnimationSpeed, feedbackOptions: FeedbackOptions, isTimed: Bool = false) {
        self.hapticsEnabled = feedbackOptions.hapticsEnabled
        self.isTimed = isTimed
    }

    func newGame(settings: GameSettings? = nil, seed: UInt64? = nil, isTimed: Bool? = nil) {
        rollTask?.cancel()
        stopTimer()
        if let settings { self.settings = settings }
        if let isTimed  { self.isTimed = isTimed }
        tiles        = (1...self.settings.tileCount).map { Tile(id: $0) }
        selectedTiles = []
        dice         = [0, 0, 0]
        highlightedHint = []
        moveHistory  = []
        elapsedSeconds = 0
        gameStartTime  = nil
        gameState    = .waitingToRoll
        isRolling    = false
    }

    func rollDice() {
        guard canRoll else { invalidFeedback(); return }
        if isTimed && gameStartTime == nil { startTimer() }
        highlightedHint = []
        isRolling = true
        let finalDice = randomDice()
        rollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            dice = finalDice
            isRolling = false
            gameState = hasValidMoves() ? .selecting : .gameOver(won: false)
            if case .gameOver = gameState { stopTimer() }
            rollFeedback()
        }
    }

    func toggleTile(_ number: Int) {
        guard canSelectTiles, tiles.first(where: { $0.id == number })?.isOpen == true else {
            invalidFeedback(); return
        }
        highlightedHint = []
        if selectedTiles.contains(number) { selectedTiles.remove(number) }
        else { selectedTiles.insert(number) }
        clickFeedback()
    }

    func confirmSelection() {
        guard canConfirm else { invalidFeedback(); return }
        let closedTiles = selectedTiles.sorted()
        for index in tiles.indices where selectedTiles.contains(tiles[index].id) {
            tiles[index].isOpen = false
        }
        selectedTiles = []
        moveHistory.append(MoveRecord(dice: dice, closedTiles: closedTiles, scoreAfterMove: score))
        if tiles.allSatisfy({ !$0.isOpen }) {
            gameState = .gameOver(won: true)
            stopTimer()
            successFeedback()
        } else {
            gameState = .waitingToRoll
            clickFeedback()
        }
    }

    func showHint() {
        guard canSelectTiles, let hint = bestHint() else { invalidFeedback(); return }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.7)) {
            highlightedHint = Set(hint)
        }
        clickFeedback()
    }

    func undoLastMove() {
        guard canUndo, let lastMove = moveHistory.popLast() else { invalidFeedback(); return }
        for index in tiles.indices where lastMove.closedTiles.contains(tiles[index].id) {
            tiles[index].isOpen = true
        }
        dice = [0, 0, 0]
        selectedTiles   = []
        highlightedHint = []
        gameState = .waitingToRoll
        clickFeedback()
    }

    func diceSettledFeedback() {}

    private func randomDice() -> [Int] {
        var result = [0, 0, 0]
        for i in 0..<settings.baseDiceCount { result[i] = Int.random(in: 1...6) }
        return result
    }

    private func hasValidMoves() -> Bool { bestHint() != nil }

    private func bestHint() -> [Int]? {
        validMoves().min {
            $0.count == $1.count ? $0.lexicographicallyPrecedes($1) : $0.count < $1.count
        }
    }

    private func validMoves() -> [[Int]] {
        let open = remainingOpenTiles
        guard diceTotal > 0 else { return [] }
        var matches: [[Int]] = []
        for mask in 1..<(1 << open.count) {
            var subset: [Int] = [], sum = 0
            for i in 0..<open.count where mask & (1 << i) != 0 {
                sum += open[i]; subset.append(open[i])
                if sum > diceTotal { break }
            }
            if sum == diceTotal { matches.append(subset) }
        }
        return matches
    }

    private func startTimer() {
        gameStartTime = Date()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard let t = gameStartTime else { break }
                elapsedSeconds = Int(Date().timeIntervalSince(t))
            }
        }
    }

    private func stopTimer() { timerTask?.cancel(); timerTask = nil }

    private func clickFeedback()   { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.click) }
    private func rollFeedback()    { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.directionUp) }
    private func invalidFeedback() { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.failure) }
    private func successFeedback() { guard hapticsEnabled else { return }; WKInterfaceDevice.current().play(.success) }
}

struct FeedbackOptions {
    var hapticsEnabled = true
    var soundsEnabled  = true
}
