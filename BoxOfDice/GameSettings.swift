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
    case de
    case fr
    case es
    case it
    // BOD-013: Brazilian Portuguese specifically, not generic Portuguese.
    // The rawValue matches the on-disk `pt-BR.lproj` resource folder name.
    case ptBR = "pt-BR"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return L10n.string("System")
        case .en:     return "English"
        case .fi:     return "Suomi"
        case .de:     return "Deutsch"
        case .fr:     return "Français"
        case .es:     return "Español"
        case .it:     return "Italiano"
        case .ptBR:   return "Português (Brasil)"
        }
    }
}

// DiceMode, MoveRule, and GameSettings now live in GameEngine.swift, shared
// verbatim by the iOS and watchOS targets.

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

    /// SceneKit tumble duration. The view model adds the small per-die stagger
    /// before it enables the next move, so interaction never resumes mid-roll.
    var tumbleDuration: TimeInterval {
        switch self {
        case .short:
            return 0.42
        case .normal:
            return 0.86
        case .long:
            return 1.24
        }
    }

    func totalRollDurationNanoseconds(dieCount: Int) -> UInt64 {
        let stagger = 0.06 * Double(max(0, dieCount - 1))
        return UInt64((tumbleDuration + stagger + 0.03) * 1_000_000_000)
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

    static let defaultTheme: Self = .midnight

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

enum SettingsStorageKey {
    static let tileCount = "settings.tileCount"
    static let diceMode = "settings.diceMode"
    static let moveRule = "settings.moveRule"
    static let theme = "settings.theme"
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let soundsEnabled = "settings.soundsEnabled"
    static let diceAnimationSpeed = "settings.diceAnimationSpeed"
    static let diceStyle = "settings.diceStyle"
    static let showHints = "settings.showHints"
    static let showDiceTotal = "settings.showDiceTotal"
    static let challengeMode = "settings.challengeMode"
    static let challengeSeed = "settings.challengeSeed"
    static let gameMode = "settings.gameMode"
    static let passAndPlayPlayerCount = "settings.passAndPlayPlayerCount"
    static let celebrations = "settings.celebrations"
    static let language = "settings.language"

    /// BOD-012: set once the first-launch onboarding tutorial has been
    /// completed or explicitly skipped. Device-local only — no
    /// WatchConnectivity sync; the Watch target has its own equivalent key.
    static let onboardingCompletedOrSkipped = "settings.onboardingCompletedOrSkipped"
}
