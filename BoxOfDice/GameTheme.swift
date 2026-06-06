//
//  GameTheme.swift
//  BoxOfDice
//

import SwiftUI

struct GameTheme {
    let name: GameThemeName
    let background: [Color]
    let board: [Color]
    let title: [Color]
    let text: Color
    let accent: Color
    let button: [Color]

    static func palette(for name: GameThemeName) -> GameTheme {
        switch name {
        case .classicWood:
            return GameTheme(
                name: name,
                background: [Color(red: 0.28, green: 0.12, blue: 0.05), Color(red: 0.55, green: 0.30, blue: 0.12), Color(red: 0.32, green: 0.14, blue: 0.05)],
                board: [Color(red: 0.47, green: 0.25, blue: 0.10), Color(red: 0.72, green: 0.43, blue: 0.20), Color(red: 0.42, green: 0.20, blue: 0.08)],
                title: [Color(red: 1.0, green: 0.91, blue: 0.68), Color(red: 0.86, green: 0.56, blue: 0.24)],
                text: Color(red: 1.0, green: 0.88, blue: 0.62),
                accent: Color(red: 1.0, green: 0.82, blue: 0.37),
                button: [Color(red: 1.0, green: 0.82, blue: 0.37), Color(red: 0.88, green: 0.50, blue: 0.12)]
            )
        case .greenFelt:
            return GameTheme(
                name: name,
                background: [Color(red: 0.02, green: 0.16, blue: 0.09), Color(red: 0.08, green: 0.36, blue: 0.20), Color(red: 0.02, green: 0.13, blue: 0.08)],
                board: [Color(red: 0.08, green: 0.30, blue: 0.18), Color(red: 0.13, green: 0.46, blue: 0.27), Color(red: 0.04, green: 0.20, blue: 0.12)],
                title: [Color(red: 0.90, green: 1.0, blue: 0.72), Color(red: 0.46, green: 0.86, blue: 0.40)],
                text: Color(red: 0.88, green: 1.0, blue: 0.76),
                accent: Color(red: 0.86, green: 0.74, blue: 0.34),
                button: [Color(red: 0.94, green: 0.82, blue: 0.40), Color(red: 0.64, green: 0.46, blue: 0.14)]
            )
        case .midnight:
            return GameTheme(
                name: name,
                background: [Color(red: 0.03, green: 0.05, blue: 0.11), Color(red: 0.10, green: 0.12, blue: 0.24), Color(red: 0.02, green: 0.03, blue: 0.08)],
                board: [Color(red: 0.10, green: 0.12, blue: 0.22), Color(red: 0.20, green: 0.23, blue: 0.42), Color(red: 0.06, green: 0.07, blue: 0.16)],
                title: [Color(red: 0.78, green: 0.88, blue: 1.0), Color(red: 0.48, green: 0.62, blue: 0.95)],
                text: Color(red: 0.82, green: 0.88, blue: 1.0),
                accent: Color(red: 0.55, green: 0.70, blue: 1.0),
                button: [Color(red: 0.60, green: 0.74, blue: 1.0), Color(red: 0.32, green: 0.42, blue: 0.84)]
            )
        case .highContrast:
            return GameTheme(
                name: name,
                background: [.black, Color(red: 0.05, green: 0.05, blue: 0.05), .black],
                board: [Color(red: 0.12, green: 0.12, blue: 0.12), Color(red: 0.24, green: 0.24, blue: 0.24), Color(red: 0.06, green: 0.06, blue: 0.06)],
                title: [.white, Color(red: 1.0, green: 0.86, blue: 0.20)],
                text: .white,
                accent: .yellow,
                button: [.yellow, Color(red: 0.85, green: 0.62, blue: 0.0)]
            )
        case .minimalLight:
            return GameTheme(
                name: name,
                background: [Color(red: 0.92, green: 0.91, blue: 0.88), Color(red: 0.98, green: 0.97, blue: 0.94), Color(red: 0.88, green: 0.87, blue: 0.84)],
                board: [Color(red: 0.70, green: 0.62, blue: 0.50), Color(red: 0.86, green: 0.78, blue: 0.64), Color(red: 0.60, green: 0.53, blue: 0.43)],
                title: [Color(red: 0.16, green: 0.12, blue: 0.08), Color(red: 0.46, green: 0.32, blue: 0.14)],
                text: Color(red: 0.20, green: 0.14, blue: 0.08),
                accent: Color(red: 0.68, green: 0.42, blue: 0.14),
                button: [Color(red: 0.95, green: 0.70, blue: 0.32), Color(red: 0.72, green: 0.42, blue: 0.12)]
            )
        }
    }
}
