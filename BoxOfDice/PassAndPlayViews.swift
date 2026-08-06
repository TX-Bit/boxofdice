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

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let isCompactLandscape = isLandscape && (proxy.size.height < 560 || verticalSizeClass == .compact)

            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if isCompactLandscape {
                        compactLandscapeCard
                    } else {
                        portraitCard
                    }
                }
                .padding(.horizontal, isCompactLandscape ? 20 : 26)
                .padding(.vertical, isCompactLandscape ? 16 : 28)
                .frame(maxWidth: isCompactLandscape ? min(540, proxy.size.width - 32) : 350)
                .background(cardBackground)
                .overlay(cardBorder)
                .shadow(color: .black.opacity(0.48), radius: 28, x: 0, y: 16)
                .padding(.horizontal, isCompactLandscape ? 16 : 28)
                .padding(.vertical, isCompactLandscape ? 10 : 20)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var portraitCard: some View {
        VStack(spacing: 22) {
            header(isCompact: false)
            scorePanel(isCompact: false)
            primaryButton(isCompact: false)
        }
    }

    private var compactLandscapeCard: some View {
        HStack(alignment: .center, spacing: 20) {
            header(isCompact: true)
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                scorePanel(isCompact: true)
                primaryButton(isCompact: true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func header(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 4 : 8) {
            Text("Player \(playerNumber) done!")
                .font(GameTypography.title(size: isCompact ? 24 : 30))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)

            Text(L10n.string(isLastPlayer ? "All players have finished." : "Hand the device to the next player."))
                .font(GameTypography.label(size: isCompact ? 13 : 16))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.62).opacity(0.82))
                .multilineTextAlignment(.center)
        }
    }

    private func scorePanel(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 2 : 6) {
            Text("SCORE")
                .font(GameTypography.section(size: isCompact ? 10 : 12))
                .tracking(isCompact ? 1.4 : 1.8)
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.74))

            Text("\(tileScore)")
                .font(GameTypography.display(size: isCompact ? 44 : 64))
                .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.70))

            Text("Lower is better")
                .font(GameTypography.caption(size: isCompact ? 11 : 12))
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.66))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 8 : 16)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 14 : 18)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 14 : 18)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func primaryButton(isCompact: Bool) -> some View {
        Button(action: isLastPlayer ? onResults : onNext) {
            Text(L10n.string(isLastPlayer ? "See Results" : "Next Player"))
                .font(GameTypography.button(size: isCompact ? 16 : 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompact ? 11 : 15)
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

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var sortedResults: [(player: Int, score: Int)] {
        scores.enumerated()
            .map { (player: $0.offset + 1, score: $0.element) }
            .sorted { $0.score < $1.score }
    }

    private var winnerScore: Int {
        sortedResults.first?.score ?? 0
    }

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let isCompactLandscape = isLandscape && (proxy.size.height < 560 || verticalSizeClass == .compact)

            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    if isCompactLandscape {
                        compactLandscapeCard
                    } else {
                        portraitCard
                    }
                }
                .padding(.horizontal, isCompactLandscape ? 20 : 26)
                .padding(.vertical, isCompactLandscape ? 16 : 28)
                .frame(maxWidth: isCompactLandscape ? min(560, proxy.size.width - 32) : 350)
                .background(cardBackground)
                .overlay(cardBorder)
                .shadow(color: .black.opacity(0.48), radius: 28, x: 0, y: 16)
                .padding(.horizontal, isCompactLandscape ? 16 : 28)
                .padding(.vertical, isCompactLandscape ? 10 : 20)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var portraitCard: some View {
        VStack(spacing: 22) {
            header(isCompact: false)
            resultsTable(isCompact: false)
            newGameButton(isCompact: false)
        }
    }

    private var compactLandscapeCard: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(spacing: 12) {
                header(isCompact: true)
                Spacer(minLength: 8)
                newGameButton(isCompact: true)
            }
            .frame(maxWidth: .infinity)

            resultsTable(isCompact: true)
                .frame(maxWidth: .infinity)
        }
    }

    private func header(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 4 : 8) {
            Text("Results")
                .font(GameTypography.title(size: isCompact ? 26 : 34))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)

            Text("Lowest score wins!")
                .font(GameTypography.label(size: isCompact ? 13 : 16))
                .foregroundStyle(Color(red: 1.0, green: 0.86, blue: 0.62).opacity(0.82))
        }
    }

    private func resultsTable(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedResults.enumerated()), id: \.element.player) { index, result in
                if index > 0 {
                    Divider()
                        .overlay(Color.white.opacity(0.10))
                }
                resultRow(rank: index + 1, player: result.player, score: result.score, isCompact: isCompact)
            }
        }
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func resultRow(rank: Int, player: Int, score: Int, isCompact: Bool) -> some View {
        let isWinner = score == winnerScore
        return HStack(spacing: isCompact ? 8 : 12) {
            Text("\(rank).")
                .font(GameTypography.value(size: isCompact ? 14 : 16))
                .foregroundStyle(isWinner
                    ? Color(red: 1.0, green: 0.88, blue: 0.40)
                    : Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.70))
                .frame(width: isCompact ? 22 : 26, alignment: .trailing)

            Text("Player \(player)")
                .font(GameTypography.label(size: isCompact ? 14 : 17))
                .foregroundStyle(isWinner ? Color(red: 1.0, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.80))

            Spacer()

            Text(L10n.format("%d pts", score))
                .font(GameTypography.value(size: isCompact ? 14 : 17))
                .foregroundStyle(isWinner ? Color(red: 1.0, green: 0.92, blue: 0.70) : Color(red: 1.0, green: 0.82, blue: 0.52).opacity(0.80))

            if isWinner {
                Image(systemName: "trophy.fill")
                    .font(.system(size: isCompact ? 13 : 15))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
            }
        }
        .padding(.horizontal, isCompact ? 12 : 16)
        .padding(.vertical, isCompact ? 8 : 12)
    }

    private func newGameButton(isCompact: Bool) -> some View {
        Button(action: onNewGame) {
            Text("New Game")
                .font(GameTypography.button(size: isCompact ? 16 : 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompact ? 11 : 15)
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

struct PassAndPlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.20, green: 0.10, blue: 0.04))
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.82, blue: 0.38),
                        Color(red: 0.92, green: 0.64, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(0.40), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 8, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
