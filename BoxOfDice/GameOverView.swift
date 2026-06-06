//
//  GameOverView.swift
//  BoxOfDice
//

import SwiftUI

struct GameOverView: View {
    let won: Bool
    let score: Int
    let remainingOpenTiles: [Int]
    let onNewGame: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            header
            scorePanel
            remainingTilesSection
            newGameButton
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 28)
        .frame(maxWidth: 350)
        .background(cardBackground)
        .overlay(cardBorder)
        .padding(.horizontal, 28)
        .shadow(color: .black.opacity(0.48), radius: 28, x: 0, y: 16)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(won ? "You cleared the box!" : "Game Over")
                .font(.system(size: won ? 31 : 34, weight: .heavy, design: .rounded))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)

            Text(won ? "Every tile is closed." : "No valid move remains.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.62).opacity(0.82))
                .multilineTextAlignment(.center)
        }
    }

    private var scorePanel: some View {
        VStack(spacing: 6) {
            Text("FINAL SCORE")
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.74))

            Text("\(score)")
                .font(.system(size: 62, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.70))
                .contentTransition(.numericText())

            Text("Lower is better")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.66))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var remainingTilesSection: some View {
        VStack(spacing: 10) {
            Text("REMAINING OPEN TILES")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.76))

            if remainingOpenTiles.isEmpty {
                Text("None")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color(red: 0.58, green: 1.0, blue: 0.50))
                    .padding(.vertical, 4)
            } else {
                LazyVGrid(columns: tileColumns, spacing: 8) {
                    ForEach(remainingOpenTiles, id: \.self) { tile in
                        Text("\(tile)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
                            .frame(width: 36, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.88, blue: 0.56), Color(red: 0.79, green: 0.50, blue: 0.22)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var newGameButton: some View {
        Button(action: onNewGame) {
            Text("New Game")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(ModalButtonStyle())
        .padding(.top, 2)
    }

    private var tileColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(36), spacing: 8), count: 6)
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: won
                ? [Color(red: 0.72, green: 1.0, blue: 0.50), Color(red: 0.35, green: 0.82, blue: 0.30)]
                : [Color(red: 1.0, green: 0.88, blue: 0.60), Color(red: 0.96, green: 0.56, blue: 0.22)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.40, green: 0.19, blue: 0.08).opacity(0.94),
                                Color(red: 0.16, green: 0.07, blue: 0.03).opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 26)
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.28), Color(red: 1.0, green: 0.68, blue: 0.30).opacity(0.30), Color.black.opacity(0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
    }
}

private struct ModalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.82, blue: 0.37), Color(red: 0.88, green: 0.50, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview("Game Over") {
    ZStack {
        Color(red: 0.30, green: 0.14, blue: 0.06).ignoresSafeArea()
        GameOverView(won: false, score: 24, remainingOpenTiles: [2, 4, 5, 6, 7], onNewGame: {})
    }
}

#Preview("Cleared") {
    ZStack {
        Color(red: 0.30, green: 0.14, blue: 0.06).ignoresSafeArea()
        GameOverView(won: true, score: 0, remainingOpenTiles: [], onNewGame: {})
    }
}
