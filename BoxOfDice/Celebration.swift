//
//  Celebration.swift
//  BoxOfDice
//
//  End-of-game celebration model: the levels of celebration, the random
//  Perfect Clear styles, the user setting, and the resolved outcome that the
//  CelebrationView and the result card both read from. This file contains no
//  UI — keep SwiftUI views in CelebrationView.swift.
//

import Foundation

/// The kind of celebration to play after a single-player game ends.
/// Priority (highest first): perfectClear, boardCleared, newBest, none.
enum CelebrationType: Equatable {
    case none
    case newBest
    case boardCleared
    case perfectClear
}

/// The visual style used for a Perfect Clear. One is picked at random per
/// perfect clear so the strongest celebration stays fresh.
enum PerfectClearStyle: String, CaseIterable, Equatable {
    case goldenFireworks
    case diceRain

    static func random() -> PerfectClearStyle {
        allCases.randomElement() ?? .goldenFireworks
    }
}

/// User-facing setting controlling how much celebration to show.
enum CelebrationLevel: String, CaseIterable, Identifiable {
    case on
    case reduced
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .on:      return L10n.string("On")
        case .reduced: return L10n.string("Reduced")
        case .off:     return L10n.string("Off")
        }
    }
}

/// The headline shown on the result card once any celebration finishes.
enum GameResultKind: Equatable {
    case gameOver
    case boardCleared
    case perfectClear
    case newBest
}

/// Everything the celebration UI and the result card need to know about how a
/// single-player game ended. Built once, in ContentView, the moment the game is
/// over (and before statistics overwrite the previous best score).
struct CelebrationOutcome: Equatable {
    var type: CelebrationType
    var resultKind: GameResultKind
    /// True when the final score beats the stored best for this mode, or when
    /// this is the first ever score for the mode (shown as "First Score!").
    var isNewBest: Bool
    var isFirstScore: Bool
    var finalScore: Int
    /// The mode's previous best, or nil when there was none.
    var previousBest: Int?
    var tileCount: Int
    var modeName: String
    var perfectClearStyle: PerfectClearStyle

    /// A do-nothing outcome (normal game over with no celebration).
    static func none(resultKind: GameResultKind = .gameOver,
                     finalScore: Int = 0,
                     tileCount: Int = 12,
                     modeName: String = "") -> CelebrationOutcome {
        CelebrationOutcome(
            type: .none,
            resultKind: resultKind,
            isNewBest: false,
            isFirstScore: false,
            finalScore: finalScore,
            previousBest: nil,
            tileCount: tileCount,
            modeName: modeName,
            perfectClearStyle: .goldenFireworks
        )
    }

    /// Resolves the celebration for a finished single-player game.
    ///
    /// - Parameters:
    ///   - won: whether every tile is closed (board cleared).
    ///   - isClassicMode: perfect clear is reserved for Classic mode.
    ///   - tileScore: the sum of open tiles (0 when the board is cleared).
    ///   - finalScore: the recorded score including any time penalty.
    ///   - storedBest: the mode's saved best score; 0 means "none recorded yet".
    ///   - tileCount / modeName: used by the celebration visuals and result card.
    static func resolve(won: Bool,
                        isClassicMode: Bool,
                        tileScore: Int,
                        finalScore: Int,
                        storedBest: Int,
                        tileCount: Int,
                        modeName: String) -> CelebrationOutcome {
        let hasPrevious = storedBest != 0
        let previousBest: Int? = hasPrevious ? storedBest : nil
        // Lower is better. A first-ever score for the mode still earns a (gentle)
        // "First Score!" moment.
        let isNewBest = hasPrevious && finalScore < storedBest
        let isFirstScore = !hasPrevious
        let earnedBadge = isNewBest || isFirstScore

        let type: CelebrationType
        let resultKind: GameResultKind
        if won && isClassicMode && tileScore == 0 {
            type = .perfectClear
            resultKind = .perfectClear
        } else if won {
            // Board Cleared no longer plays its own celebration — the result card
            // still shows "Board Cleared!". A New Best on the same game keeps its
            // (small) celebration.
            type = earnedBadge ? .newBest : .none
            resultKind = .boardCleared
        } else if earnedBadge {
            type = .newBest
            resultKind = .newBest
        } else {
            type = .none
            resultKind = .gameOver
        }

        return CelebrationOutcome(
            type: type,
            resultKind: resultKind,
            isNewBest: earnedBadge,
            isFirstScore: isFirstScore,
            finalScore: finalScore,
            previousBest: previousBest,
            tileCount: tileCount,
            modeName: modeName,
            perfectClearStyle: .random()
        )
    }
}
