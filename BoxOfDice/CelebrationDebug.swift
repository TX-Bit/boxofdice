//
//  CelebrationDebug.swift
//  BoxOfDice
//
//  Simulator-only helper for previewing every celebration animation without
//  having to actually finish a game. The whole file compiles out of device /
//  release builds via `#if targetEnvironment(simulator)`.
//

#if targetEnvironment(simulator)
import SwiftUI

/// The preset celebrations offered by the debug menu.
enum DebugCelebration: String, CaseIterable, Identifiable {
    case perfectFireworks
    case perfectDiceRain
    case newBest
    case firstScore
    case perfectNewBest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .perfectFireworks:    return "Perfect · Golden Fireworks"
        case .perfectDiceRain:     return "Perfect · Dice Rain"
        case .newBest:             return "New Best"
        case .firstScore:          return "First Score"
        case .perfectNewBest:      return "Perfect + New Best"
        }
    }

    func outcome(modeName: String, tileCount: Int) -> CelebrationOutcome {
        switch self {
        case .perfectFireworks:
            return perfect(style: .goldenFireworks, modeName: modeName, tileCount: tileCount)
        case .perfectDiceRain:
            return perfect(style: .diceRain, modeName: modeName, tileCount: tileCount)
        case .newBest:
            return CelebrationOutcome(type: .newBest, resultKind: .newBest,
                                      isNewBest: true, isFirstScore: false,
                                      finalScore: 24, previousBest: 31,
                                      tileCount: tileCount, modeName: modeName,
                                      perfectClearStyle: .goldenFireworks)
        case .firstScore:
            return CelebrationOutcome(type: .newBest, resultKind: .newBest,
                                      isNewBest: true, isFirstScore: true,
                                      finalScore: 22, previousBest: nil,
                                      tileCount: tileCount, modeName: modeName,
                                      perfectClearStyle: .goldenFireworks)
        case .perfectNewBest:
            return CelebrationOutcome(type: .perfectClear, resultKind: .perfectClear,
                                      isNewBest: true, isFirstScore: false,
                                      finalScore: 0, previousBest: 8,
                                      tileCount: tileCount, modeName: modeName,
                                      perfectClearStyle: .goldenFireworks)
        }
    }

    private func perfect(style: PerfectClearStyle, modeName: String, tileCount: Int) -> CelebrationOutcome {
        CelebrationOutcome(type: .perfectClear, resultKind: .perfectClear,
                           isNewBest: false, isFirstScore: false,
                           finalScore: 0, previousBest: 6,
                           tileCount: tileCount, modeName: modeName,
                           perfectClearStyle: style)
    }
}

/// Floating "wand" button that pops a menu of every celebration preset.
struct CelebrationDebugMenu: View {
    let modeName: String
    let tileCount: Int
    let onSelect: (CelebrationOutcome) -> Void

    var body: some View {
        Menu {
            ForEach(DebugCelebration.allCases) { item in
                Button(item.label) {
                    onSelect(item.outcome(modeName: modeName, tileCount: tileCount))
                }
            }
        } label: {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.82, blue: 0.37),
                                 Color(red: 0.88, green: 0.50, blue: 0.12)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    in: Circle()
                )
                .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Preview celebrations")
    }
}
#endif
