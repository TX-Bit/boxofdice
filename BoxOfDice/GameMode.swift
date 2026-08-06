//
//  GameMode.swift
//  BoxOfDice
//

import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    // quickGame is declared first so CaseIterable.allCases (used by the
    // Watch mode picker) lists it first, matching BOD-011's requirement
    // that Quick Game appears first in mode selection. iOS's hand-built
    // GameModeSelectionView lists its groups in the same order separately.
    case quickGame
    case classic
    case speedRun
    case bigBox
    case bigBoxSpeed
    case passAndPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickGame:   return L10n.string("Quick Game")
        case .classic:     return L10n.string("Classic")
        case .speedRun:    return L10n.string("Speed Run")
        case .bigBox:      return L10n.string("Big Box")
        case .bigBoxSpeed: return L10n.string("Big Box Speed")
        case .passAndPlay: return L10n.string("Pass & Play")
        }
    }

    var subtitle: String {
        switch self {
        case .quickGame:   return L10n.string("9 tiles · short and simple")
        case .classic:     return L10n.string("12 tiles · 2 dice · lowest score wins")
        case .speedRun:    return L10n.string("12 tiles · 2 dice · score + elapsed seconds")
        case .bigBox:      return L10n.string("18 tiles · 3 dice · lowest score wins")
        case .bigBoxSpeed: return L10n.string("18 tiles · 3 dice · score + elapsed seconds")
        case .passAndPlay: return L10n.string("2–4 players · each plays one Classic round")
        }
    }

    var tileCount: Int {
        switch self {
        case .quickGame:                        return 9
        case .classic, .speedRun, .passAndPlay: return 12
        case .bigBox, .bigBoxSpeed:             return 18
        }
    }

    var baseDiceCount: Int {
        switch self {
        case .quickGame, .classic, .speedRun, .passAndPlay: return 2
        case .bigBox, .bigBoxSpeed:                         return 3
        }
    }

    /// Quick Game is the only mode that switches down to a single die once
    /// only the low tiles remain (BOD-011) — every other mode always uses
    /// its base dice count.
    var diceMode: DiceMode {
        self == .quickGame ? .oneDieWhenLowTilesRemain : .alwaysTwoDice
    }

    var isTimed: Bool {
        self == .speedRun || self == .bigBoxSpeed
    }

    var isMultiplayer: Bool {
        self == .passAndPlay
    }

    var group: Group {
        switch self {
        case .quickGame:             return .quick
        case .classic, .speedRun:    return .classic
        case .bigBox, .bigBoxSpeed:  return .bigBox
        case .passAndPlay:           return .multiplayer
        }
    }

    func finalScore(baseScore: Int, elapsedSeconds: Int) -> Int {
        baseScore + (isTimed ? elapsedSeconds : 0)
    }

    enum Group: String {
        case quick       = "Quick"
        case classic     = "Classic"
        case bigBox      = "Big Box"
        case multiplayer = "Multiplayer"
    }
}
