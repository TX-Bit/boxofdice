//
//  OnboardingView.swift
//  BoxOfDice
//

import SwiftUI

/// A short practice turn on a Classic twelve-tile board, with a choice
/// to start playing immediately on the first launch.
///
/// `isReplay` distinguishes the two contexts this can appear in:
/// - `false` (a brand-new install): finishing (Skip or the closing prompt's
///   button) starts a genuine new, normally-random 12-tile Classic game.
/// - `true` (reopened from Settings → "How to Play"): the game already
///   running underneath is left completely untouched; finishing just
///   dismisses back to it, and the closing prompt reads "Back to Game".
struct OnboardingView: View {
    @StateObject private var model = OnboardingViewModel(tileCount: 12)
    @State private var hasChosenTutorial = false
    let theme: GameTheme
    var diceStyle: DiceStyle = .palette(for: .ivory)
    let isReplay: Bool
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsWelcome: Bool { !isReplay && !hasChosenTutorial }

    var body: some View {
        ZStack {
            ThemedSheetBackground(theme: theme)

            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 520

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isCompactHeight ? 8 : 16) {
                        if showsWelcome {
                            welcomeHeader(isCompactHeight: isCompactHeight)
                        } else {
                            stepHeader(isCompactHeight: isCompactHeight)
                        }

                        board(availableWidth: proxy.size.width, isCompactHeight: isCompactHeight)
                        diceRow(isCompactHeight: isCompactHeight)

                        if showsWelcome {
                            welcomeActions(isCompactHeight: isCompactHeight)
                        } else {
                            actions(isCompactHeight: isCompactHeight)
                        }
                    }
                    .padding(.horizontal, isCompactHeight ? 12 : 16)
                    .padding(.vertical, isCompactHeight ? 6 : 18)
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .center)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.step)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: hasChosenTutorial)
    }

    private func welcomeHeader(isCompactHeight: Bool) -> some View {
        VStack(spacing: isCompactHeight ? 2 : 8) {
            Text(L10n.string("Box of Dice"))
                .font(GameTypography.title(size: isCompactHeight ? 24 : 31))
                .foregroundStyle(theme.text)
            Text(L10n.string("Would you like a quick tutorial?"))
                .font(.system(size: isCompactHeight ? 15 : 18, weight: .medium))
                .foregroundStyle(theme.text.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private func stepHeader(isCompactHeight: Bool) -> some View {
        VStack(spacing: isCompactHeight ? 2 : 7) {
            Text(stepNumber)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(theme.text.opacity(0.66))
            Text(promptTitle)
                .font(.system(size: isCompactHeight ? 17 : 21, weight: .bold, design: .rounded))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
            if let subtitle = promptSubtitle {
                Text(subtitle)
                    .font(.system(size: isCompactHeight ? 13 : 16, weight: .medium))
                    .foregroundStyle(theme.text.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var stepNumber: String {
        switch model.step {
        case .waitingForRoll: return "1 / 3"
        case .selecting: return "2 / 3"
        case .resolved: return "3 / 3"
        }
    }

    private var promptTitle: String {
        switch model.step {
        case .waitingForRoll:
            return L10n.string("Roll the dice")
        case .selecting:
            return L10n.format("You rolled %lld. Try closing %lld, or %lld + %lld.", model.diceTotal, model.diceTotal, model.dice[0], model.dice[1])
        case .resolved:
            return L10n.string("Nice! The goal is to leave as few points as possible.")
        }
    }

    private var promptSubtitle: String? {
        switch model.step {
        case .waitingForRoll:
            return nil
        case .selecting:
            return L10n.format("Selected %lld / %lld", model.selectionTotal, model.diceTotal)
        case .resolved:
            return L10n.string("Empty board = 0.")
        }
    }

    // MARK: - Board

    private func board(availableWidth: CGFloat, isCompactHeight: Bool) -> some View {
        let gap: CGFloat = isCompactHeight ? 4 : 6
        let tileWidth = min(isCompactHeight ? 43 : 60, max(34, (availableWidth - 56 - 5 * gap) / 6))
        let tileHeight = tileWidth * (isCompactHeight ? 1.13 : 1.38)
        let columns = Array(repeating: GridItem(.fixed(tileWidth), spacing: gap), count: 6)
        return LazyVGrid(columns: columns, spacing: gap) {
            ForEach(model.tiles) { tile in
                TileView(
                    number: tile.id,
                    isOpen: tile.isOpen,
                    isSelected: model.selectedTiles.contains(tile.id),
                    isEnabled: model.step == .selecting,
                    numberFontSize: isCompactHeight ? 18 : 25,
                    onTap: { model.toggleTile(tile.id) }
                )
                .frame(width: tileWidth, height: tileHeight)
            }
        }
        .padding(isCompactHeight ? 6 : 10)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Dice

    private func diceRow(isCompactHeight: Bool) -> some View {
        let dieSize: CGFloat = isCompactHeight ? 62 : 100
        return HStack(spacing: isCompactHeight ? 10 : 16) {
            ForEach(0..<2, id: \.self) { index in
                Dice3DView(value: model.hasRolled ? model.dice[index] : index + 1, isRolling: false, dieIndex: index, rollDuration: 0, style: diceStyle)
                    .frame(width: dieSize, height: dieSize)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            model.hasRolled
                ? L10n.format("Rolled %lld and %lld", model.dice[0], model.dice[1])
                : L10n.string("Dice, not rolled yet")
        )
    }

    // MARK: - Actions

    private func welcomeActions(isCompactHeight: Bool) -> some View {
        VStack(spacing: isCompactHeight ? 4 : 9) {
            Button { hasChosenTutorial = true } label: {
                Text(L10n.string("Show Tutorial"))
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isCompactHeight ? 42 : 52)
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())

            Button(action: onFinish) {
                Text(L10n.string("Start Game"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isCompactHeight ? 38 : 44)
            }
            .buttonStyle(.plain)

            if !isCompactHeight {
                Text(L10n.string("The tutorial is also available in Settings."))
                    .font(.system(size: 13))
                    .foregroundStyle(theme.text.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 340)
    }

    @ViewBuilder
    private func actions(isCompactHeight: Bool) -> some View {
        // `minHeight`, never a fixed height: at the largest Dynamic Type
        // sizes the label wraps, and a fixed height would clip it.
        let buttonHeight: CGFloat = isCompactHeight ? 42 : 52
        let stackSpacing: CGFloat = isCompactHeight ? 6 : 10

        switch model.step {
        case .waitingForRoll:
            VStack(spacing: stackSpacing) {
                Button(action: model.rollTutorialDice) {
                    Label(L10n.string("Roll"), systemImage: "dice.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: buttonHeight)
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                skipButton
            }
        case .selecting:
            VStack(spacing: stackSpacing) {
                Button(action: model.confirm) {
                    Label(L10n.string("Close tiles"), systemImage: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: buttonHeight)
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .disabled(!model.canConfirm)
                .opacity(model.canConfirm ? 1 : 0.45)
                skipButton
            }
        case .resolved:
            Button(action: onFinish) {
                Text(isReplay ? L10n.string("Back to Game") : L10n.string("Start Game"))
                    .font(.system(size: 19, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isCompactHeight ? 46 : 56)
            }
            .buttonStyle(OnboardingPrimaryButtonStyle())
        }
    }

    private var skipButton: some View {
        Button(action: onFinish) {
            Text(isReplay ? L10n.string("Back to Game") : L10n.string("Skip"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.text.opacity(0.62))
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.16, green: 0.08, blue: 0.03))
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.82, blue: 0.37), Color(red: 0.88, green: 0.50, blue: 0.12)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.32), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

#Preview {
    OnboardingView(theme: GameTheme.palette(for: .greenFelt), isReplay: false, onFinish: {})
}
