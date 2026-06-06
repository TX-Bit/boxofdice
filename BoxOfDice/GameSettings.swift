//
//  GameSettings.swift
//  BoxOfDice
//

import Foundation

enum DiceMode: String, CaseIterable, Identifiable {
    case alwaysTwoDice
    case oneDieWhenLowTilesRemain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alwaysTwoDice:
            return "Always use two dice"
        case .oneDieWhenLowTilesRemain:
            return "Use one die when only tiles 1-6 remain open"
        }
    }
}

enum MoveRule: String, CaseIterable, Identifiable {
    case anyCombination
    case oneOrTwoTiles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anyCombination:
            return "Any combination of open tiles"
        case .oneOrTwoTiles:
            return "Only one or two tiles"
        }
    }
}

enum ConfirmBehavior: String, CaseIterable, Identifiable {
    case manual
    case automatic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:
            return "Use Confirm button"
        case .automatic:
            return "Auto-confirm matching selection"
        }
    }
}

enum DiceAnimationSpeed: String, CaseIterable, Identifiable {
    case short
    case normal
    case long

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short: return "Short"
        case .normal: return "Normal"
        case .long: return "Long"
        }
    }

    var frameDelays: [UInt64] {
        switch self {
        case .short:
            return [38, 42, 48, 58, 72]
        case .normal:
            return [45, 48, 52, 56, 62, 70, 82, 98, 118]
        case .long:
            return [42, 45, 48, 52, 56, 62, 70, 82, 96, 112, 132, 154]
        }
    }
}

enum ChallengeMode: String, CaseIterable, Identifiable {
    case normal
    case daily
    case customSeed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: return "Normal random game"
        case .daily: return "Daily Challenge"
        case .customSeed: return "Challenge seed"
        }
    }
}

enum GameThemeName: String, CaseIterable, Identifiable {
    case classicWood
    case greenFelt
    case midnight
    case highContrast
    case minimalLight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicWood: return "Classic Wood"
        case .greenFelt: return "Green Felt"
        case .midnight: return "Midnight"
        case .highContrast: return "High Contrast"
        case .minimalLight: return "Minimal Light"
        }
    }
}

struct GameSettings: Equatable {
    var tileCount: Int
    var diceMode: DiceMode
    var moveRule: MoveRule

    static let `default` = GameSettings(
        tileCount: 12,
        diceMode: .alwaysTwoDice,
        moveRule: .anyCombination
    )

    init(tileCount: Int, diceMode: DiceMode, moveRule: MoveRule) {
        self.tileCount = [9, 10, 12].contains(tileCount) ? tileCount : 12
        self.diceMode = diceMode
        self.moveRule = moveRule
    }

    init(tileCount: Int, diceModeRawValue: String, moveRuleRawValue: String) {
        self.init(
            tileCount: tileCount,
            diceMode: DiceMode(rawValue: diceModeRawValue) ?? .alwaysTwoDice,
            moveRule: MoveRule(rawValue: moveRuleRawValue) ?? .anyCombination
        )
    }
}

enum SettingsStorageKey {
    static let tileCount = "settings.tileCount"
    static let diceMode = "settings.diceMode"
    static let moveRule = "settings.moveRule"
    static let theme = "settings.theme"
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let soundsEnabled = "settings.soundsEnabled"
    static let diceAnimationSpeed = "settings.diceAnimationSpeed"
    static let confirmBehavior = "settings.confirmBehavior"
    static let showHints = "settings.showHints"
    static let undoEnabled = "settings.undoEnabled"
    static let leftHandedLayout = "settings.leftHandedLayout"
    static let challengeMode = "settings.challengeMode"
    static let challengeSeed = "settings.challengeSeed"
}
