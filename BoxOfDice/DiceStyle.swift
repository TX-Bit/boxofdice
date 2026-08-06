//
//  DiceStyle.swift
//  BoxOfDice
//

import SwiftUI

/// Selectable dice material style, independent of the board `GameTheme`.
enum DiceStyleName: String, CaseIterable, Identifiable, Codable {
    case ivory
    case cherry
    case midnightBlue
    case graphite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ivory:        return L10n.string("Ivory")
        case .cherry:        return L10n.string("Cherry")
        case .midnightBlue:  return L10n.string("Midnight Blue")
        case .graphite:      return L10n.string("Graphite")
        }
    }

    var subtitle: String {
        switch self {
        case .ivory:        return L10n.string("Warm pale face, near-black pips")
        case .cherry:        return L10n.string("Deep cherry-red face, cream pips")
        case .midnightBlue:  return L10n.string("Dark blue face, white pips")
        case .graphite:      return L10n.string("Charcoal face, light pips")
        }
    }
}

/// Typed, physically-based material description for a die — the single
/// source of truth for dice material numbers, shared by the live game dice
/// and the settings preview (both render through `Dice3DView` /
/// `DiceSceneCoordinator`, so a style is only ever defined here, never
/// duplicated per call site).
struct DiceStyle: Equatable {
    let name: DiceStyleName
    let bodyColor: Color
    let pipColor: Color
    /// Physically-based roughness for the die body (0 = mirror, 1 = fully matte).
    let roughness: Double
    /// Clear-coat layer intensity — a restrained lacquer sheen, not a mirror.
    let clearCoat: Double
    let clearCoatRoughness: Double

    static func palette(for name: DiceStyleName) -> DiceStyle {
        switch name {
        case .ivory:
            // Matches the app's original (pre-dice-style) look exactly.
            return DiceStyle(
                name: name,
                bodyColor: Color(red: 245.0 / 255.0, green: 242.0 / 255.0, blue: 230.0 / 255.0),
                pipColor: Color(red: 0.055, green: 0.055, blue: 0.052),
                roughness: 0.32,
                clearCoat: 0.06,
                clearCoatRoughness: 0.58
            )
        case .cherry:
            return DiceStyle(
                name: name,
                bodyColor: Color(red: 0.40, green: 0.05, blue: 0.07),
                pipColor: Color(red: 0.97, green: 0.94, blue: 0.88),
                roughness: 0.22,
                clearCoat: 0.24,
                clearCoatRoughness: 0.32
            )
        case .midnightBlue:
            return DiceStyle(
                name: name,
                bodyColor: Color(red: 0.055, green: 0.085, blue: 0.19),
                pipColor: Color(white: 0.97),
                roughness: 0.40,
                clearCoat: 0.12,
                clearCoatRoughness: 0.50
            )
        case .graphite:
            return DiceStyle(
                name: name,
                bodyColor: Color(red: 0.165, green: 0.165, blue: 0.175),
                pipColor: Color(red: 0.85, green: 0.84, blue: 0.81),
                roughness: 0.58,
                clearCoat: 0.0,
                clearCoatRoughness: 0.85
            )
        }
    }
}
