//
//  PassAndPlayViews.swift
//  BoxOfDice
//

import SwiftUI

// MARK: - Round-end overlay (shown after each player's game)

struct PassAndPlayRoundEndView: View {
    let playerNumber: Int
    let tileScore: Int
    let isLastPlayer: Bool
    let onNext: () -> Void      // "Next Player" — starts the next player's round
    let onResults: () -> Void   // "See Results" — shown to last player

    var body: some View {
        VStack(spacing: 22) {
            header
            scorePanel
            primaryButton
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
            Text("Player \(playerNumber) done!")
                .font(GameTypography.title(size: 30))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)

            Text(isLastPlayer ? "All players have finished." : "Hand the device to the next player.")
                .font(GameTypography.label(size: 16))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.62).opacity(0.82))
                .multilineTextAlignment(.center)
        }
    }

    private var scorePanel: some View {
        VStack(spacing: 6) {
            Text("SCORE")
                .font(GameTypography.section(size: 12))
                .tracking(1.8)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.74))

            Text("\(tileScore)")
                .font(GameTypography.display(size: 64))
                .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.70))

            Text("Lower is better")
                .font(GameTypography.caption(size: 12))
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

    private var primaryButton: some View {
        Button(action: isLastPlayer ? onResults : onNext) {
            Text(isLastPlayer ? "See Results" : "Next Player")
                .font(GameTypography.button(size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(PassAndPlayButtonStyle())
        .padding(.top, 2)
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.88, blue: 0.60), Color(red: 0.96, green: 0.56, blue: 0.22)],
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
                    colors: [
                        Color.white.opacity(0.28),
                        Color(red: 1.0, green: 0.68, blue: 0.30).opacity(0.30),
                        Color.black.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Final results overlay (shown after all players have played)

struct PassAndPlayResultsView: View {
    let scores: [Int]
    let onNewGame: () -> Void

    private var sortedResults: [(player: Int, score: Int)] {
        scores.enumerated()
            .map { (player: $0.offset + 1, score: $0.element) }
            .sorted { $0.score < $1.score }
    }

    private var winnerScore: Int {
        sortedResults.first?.score ?? 0
    }

    var body: some View {
        VStack(spacing: 22) {
            header
            resultsTable
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
            Text("Results")
                .font(GameTypography.title(size: 34))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)

            Text("Lowest score wins!")
                .font(GameTypography.label(size: 16))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.62).opacity(0.82))
        }
    }

    private var resultsTable: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedResults.enumerated()), id: \.element.player) { index, result in
                if index > 0 {
                    Divider()
                        .overlay(Color.white.opacity(0.10))
                }
                resultRow(rank: index + 1, player: result.player, score: result.score)
            }
        }
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func resultRow(rank: Int, player: Int, score: Int) -> some View {
        let isWinner = score == winnerScore && rank == 1
        return HStack(spacing: 12) {
            Text("\(rank).")
                .font(GameTypography.value(size: 16))
                .foregroundStyle(isWinner
                    ? Color(red: 1.0, green: 0.88, blue: 0.40)
                    : Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.70))
                .frame(width: 26, alignment: .trailing)

            Text("Player \(player)")
                .font(GameTypography.label(size: 17))
                .foregroundStyle(isWinner ? Color(red: 1.0, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.80))

            Spacer()

            Text("\(score) pts")
                .font(GameTypography.value(size: 17))
                .foregroundStyle(isWinner ? Color(red: 1.0, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.80))

            if isWinner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var newGameButton: some View {
        Button(action: onNewGame) {
            Text("New Game")
                .font(GameTypography.button(size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(PassAndPlayButtonStyle())
        .padding(.top, 2)
    }

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.88, blue: 0.60), Color(red: 0.96, green: 0.68, blue: 0.22)],
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
                    colors: [
                        Color.white.opacity(0.28),
                        Color(red: 1.0, green: 0.68, blue: 0.30).opacity(0.30),
                        Color.black.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Shared button style

private struct PassAndPlayButtonStyle: ButtonStyle {
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

#Preview("Round End") {
    ZStack {
        Color(red: 0.30, green: 0.14, blue: 0.06).ignoresSafeArea()
        PassAndPlayRoundEndView(playerNumber: 2, tileScore: 18, isLastPlayer: false, onNext: {}, onResults: {})
    }
}

#Preview("Results") {
    ZStack {
        Color(red: 0.30, green: 0.14, blue: 0.06).ignoresSafeArea()
        PassAndPlayResultsView(scores: [12, 31, 8, 24], onNewGame: {})
    }
}
