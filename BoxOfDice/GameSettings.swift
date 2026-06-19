//
//  GameSettings.swift
//  BoxOfDice
//

import Foundation

enum L10n {
    // An optional in-app language override (independent of the device language).
    // nil means "follow the system".
    private static var overrideCode: String? {
        let code = UserDefaults.standard.string(forKey: SettingsStorageKey.language)
        guard let code, code != AppLanguage.system.rawValue else { return nil }
        return code
    }

    /// The locale to use for number/date formatting, honouring the override.
    static var locale: Locale {
        if let overrideCode { return Locale(identifier: overrideCode) }
        return .current
    }

    static func string(_ key: String) -> String {
        guard let overrideCode else { return NSLocalizedString(key, comment: "") }
        // English is the development language — the keys themselves are the text.
        if overrideCode == AppLanguage.en.rawValue { return key }
        if let path = Bundle.main.path(forResource: overrideCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }
}

/// Selectable in-app language. `system` follows the device setting.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case fi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return L10n.string("System")
        case .en:     return "English"
        case .fi:     return "Suomi"
        }
    }
}

enum DiceMode: String, CaseIterable, Identifiable {
    case alwaysTwoDice
    case oneDieWhenLowTilesRemain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alwaysTwoDice:
            return L10n.string("Always use all dice")
        case .oneDieWhenLowTilesRemain:
            return L10n.string("Use one die when only tiles 1–6 remain open")
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
            return L10n.string("Any combination of open tiles")
        case .oneOrTwoTiles:
            return L10n.string("Only one or two tiles")
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
        case .short: return L10n.string("Short")
        case .normal: return L10n.string("Normal")
        case .long: return L10n.string("Long")
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
        case .normal: return L10n.string("Normal random game")
        case .daily: return L10n.string("Daily Challenge")
        case .customSeed: return L10n.string("Challenge seed")
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
        case .classicWood: return L10n.string("Classic Wood")
        case .greenFelt: return L10n.string("Green Felt")
        case .midnight: return L10n.string("Midnight")
        case .highContrast: return L10n.string("High Contrast")
        case .minimalLight: return L10n.string("Minimal Light")
        case .darkWalnut: return L10n.string("Dark Walnut")
        }
    }
}

struct GameSettings: Equatable {
    var tileCount: Int
    var baseDiceCount: Int
    var diceMode: DiceMode
    var moveRule: MoveRule

    static let `default` = GameSettings(
        tileCount: 12,
        baseDiceCount: 2,
        diceMode: .alwaysTwoDice,
        moveRule: .anyCombination
    )

    static func from(mode: GameMode, diceMode: DiceMode, moveRule: MoveRule) -> GameSettings {
        GameSettings(
            tileCount: mode.tileCount,
            baseDiceCount: mode.baseDiceCount,
            diceMode: diceMode,
            moveRule: moveRule
        )
    }

    init(tileCount: Int, baseDiceCount: Int, diceMode: DiceMode, moveRule: MoveRule) {
        self.tileCount = tileCount
        self.baseDiceCount = max(1, min(3, baseDiceCount))
        self.diceMode = diceMode
        self.moveRule = moveRule
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
    static let showHints = "settings.showHints"
    static let showDiceTotal = "settings.showDiceTotal"
    static let challengeMode = "settings.challengeMode"
    static let challengeSeed = "settings.challengeSeed"
    static let gameMode = "settings.gameMode"
    static let passAndPlayPlayerCount = "settings.passAndPlayPlayerCount"
    static let celebrations = "settings.celebrations"
    static let language = "settings.language"
}
