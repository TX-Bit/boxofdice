//
//  GameOverView.swift
//  BoxOfDice
//

import SwiftUI

struct GameOverView: View {
    let won: Bool
    let tileScore: Int
    let elapsedSeconds: Int
    let isTimed: Bool
    let remainingOpenTiles: [Int]
    let theme: GameTheme
    let onNewGame: () -> Void
    let onSettings: () -> Void
    let onStats: () -> Void

    var finalScore: Int { isTimed ? tileScore + elapsedSeconds : tileScore }

    var body: some View {
        VStack(spacing: 22) {
            iconBar
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

    private var iconBar: some View {
        HStack {
            Button(action: onStats) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.text.opacity(0.70))
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.20), in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Statistics")

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.text.opacity(0.70))
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.20), in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(won ? "You cleared the box!" : "Game Over")
                .font(GameTypography.title(size: won ? 31 : 34))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)

            Text(won ? "Every tile is closed." : "No valid move remains.")
                .font(GameTypography.label(size: 16))
                .foregroundStyle(theme.text.opacity(0.72))
                .multilineTextAlignment(.center)
        }
    }

    private var scorePanel: some View {
        VStack(spacing: 6) {
            Text("FINAL SCORE")
                .font(GameTypography.section(size: 12))
                .tracking(1.8)
                .foregroundStyle(theme.accent.opacity(0.82))

            Text("\(finalScore)")
                .font(GameTypography.display(size: 64))
                .foregroundStyle(theme.text)

            if isTimed && elapsedSeconds > 0 {
                HStack(spacing: 6) {
                    Text("Tiles \(tileScore)")
                    Text("+")
                    Label("\(elapsedSeconds)s", systemImage: "timer")
                }
                .font(GameTypography.caption(size: 13))
                .foregroundStyle(theme.accent.opacity(0.76))
            } else {
                Text("Lower is better")
                    .font(GameTypography.caption(size: 12))
                    .foregroundStyle(theme.text.opacity(0.52))
            }
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
                .font(GameTypography.section(size: 12))
                .tracking(1.4)
                .foregroundStyle(theme.accent.opacity(0.78))

            if remainingOpenTiles.isEmpty {
                Text("None")
                    .font(GameTypography.button(size: 18))
                    .foregroundStyle(Color(red: 0.58, green: 1.0, blue: 0.50))
                    .padding(.vertical, 4)
            } else {
                LazyVGrid(columns: tileColumns, spacing: 8) {
                    ForEach(remainingOpenTiles, id: \.self) { tile in
                        Text("\(tile)")
                            .font(GameTypography.tileNumber(size: 18))
                            .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
                            .frame(width: 36, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: theme.button,
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
                .font(GameTypography.button(size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(ModalButtonStyle(theme: theme))
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
                            colors: theme.background.map { $0.opacity(0.96) },
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
                    colors: [
                        Color.white.opacity(0.28),
                        theme.accent.opacity(0.25),
                        Color.black.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
    }
}

private struct ModalButtonStyle: ButtonStyle {
    let theme: GameTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
            .background(
                LinearGradient(colors: theme.button, startPoint: .top, endPoint: .bottom)
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
    let theme = GameTheme.palette(for: .classicWood)
    ZStack {
        LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        GameOverView(won: false, tileScore: 24, elapsedSeconds: 0, isTimed: false, remainingOpenTiles: [2, 4, 5, 6, 7], theme: theme, onNewGame: {}, onSettings: {}, onStats: {})
    }
}

#Preview("Game Over — Timed") {
    let theme = GameTheme.palette(for: .classicWood)
    ZStack {
        LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        GameOverView(won: false, tileScore: 14, elapsedSeconds: 47, isTimed: true, remainingOpenTiles: [5, 9], theme: theme, onNewGame: {}, onSettings: {}, onStats: {})
    }
}

#Preview("Cleared") {
    let theme = GameTheme.palette(for: .classicWood)
    ZStack {
        LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        GameOverView(won: true, tileScore: 0, elapsedSeconds: 0, isTimed: false, remainingOpenTiles: [], theme: theme, onNewGame: {}, onSettings: {}, onStats: {})
    }
}
