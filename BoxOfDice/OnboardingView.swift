//
//  OnboardingView.swift
//  BoxOfDice
//

import SwiftUI

/// The first-launch tutorial (BOD-012): a fixed practice roll on a nine-tile
/// board. Fully self-contained — its own view model, its own tiny board
/// layout — so it doesn't add branching to the normal game's views.
///
/// `isReplay` distinguishes the two contexts this can appear in:
/// - `false` (a brand-new install): finishing (Skip or the closing prompt's
///   button) starts a genuine new, normally-random Quick Game.
/// - `true` (reopened from Settings → "How to Play"): the game already
///   running underneath is left completely untouched; finishing just
///   dismisses back to it, and the closing prompt reads "Back to Game".
struct OnboardingView: View {
    @StateObject private var model = OnboardingViewModel()
    let theme: GameTheme
    var diceStyle: DiceStyle = .palette(for: .ivory)
    let isReplay: Bool
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ThemedSheetBackground(theme: theme)

            // The tutorial is the very first screen a new player sees, so its
            // actions must be reachable in every orientation. Laid out at its
            // natural size this column needs ~547pt of height — more than a
            // landscape iPhone has (390pt, or 375pt on the smallest supported
            // screen), which pushed Roll/Skip off the bottom with no way to
            // scroll to them (docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §5).
            // A scroll view that also stretches to the full height keeps the
            // content centred when it fits and scrollable when it doesn't;
            // the compact metrics keep scrolling rare rather than routine.
            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 520

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isCompactHeight ? 8 : 18) {
                        Spacer(minLength: 4)

                        // Decorative only — the first thing to go when height
                        // is scarce, so the actions stay on screen.
                        if !isCompactHeight {
                            Text("Box of Dice")
                                .font(GameTypography.section(size: 13))
                                .tracking(2)
                                .foregroundStyle(theme.text.opacity(0.55))
                        }

                        promptCard

                        board(isCompactHeight: isCompactHeight)
                            .padding(.top, isCompactHeight ? 0 : 4)

                        diceRow(isCompactHeight: isCompactHeight)

                        Spacer(minLength: 4)

                        actions(isCompactHeight: isCompactHeight)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, isCompactHeight ? 8 : 24)
                    .padding(.bottom, isCompactHeight ? 10 : 28)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82), value: model.step)
    }

    // MARK: - Prompt

    @ViewBuilder
    private var promptCard: some View {
        VStack(spacing: 6) {
            Text(promptTitle)
                .font(GameTypography.value(size: 18))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
            if let subtitle = promptSubtitle {
                Text(subtitle)
                    .font(GameTypography.caption(size: 13))
                    .foregroundStyle(theme.text.opacity(0.68))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        .accessibilityElement(children: .combine)
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
            return L10n.format("Selected %lld", model.selectionTotal)
        case .resolved:
            return L10n.string("Empty board = 0.")
        }
    }

    // MARK: - Board

    private func board(isCompactHeight: Bool) -> some View {
        let tileWidth: CGFloat = isCompactHeight ? 36 : 44
        let tileHeight: CGFloat = isCompactHeight ? 52 : 66
        let columns = Array(repeating: GridItem(.fixed(tileWidth), spacing: 8), count: 5)
        return LazyVGrid(columns: columns, spacing: isCompactHeight ? 7 : 10) {
            ForEach(model.tiles) { tile in
                TileView(
                    number: tile.id,
                    isOpen: tile.isOpen,
                    isSelected: model.selectedTiles.contains(tile.id),
                    isEnabled: model.step == .selecting,
                    numberFontSize: isCompactHeight ? 18 : 22,
                    onTap: { model.toggleTile(tile.id) }
                )
                .frame(width: tileWidth, height: tileHeight)
            }
        }
        .padding(isCompactHeight ? 10 : 14)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Dice

    private func diceRow(isCompactHeight: Bool) -> some View {
        let dieSize: CGFloat = isCompactHeight ? 44 : 56
        return HStack(spacing: 14) {
            ForEach(0..<2, id: \.self) { index in
                Dice3DView(value: model.dice[index], isRolling: false, dieIndex: index, rollDuration: 0, style: diceStyle)
                    .frame(width: dieSize, height: dieSize)
                    .opacity(model.hasRolled ? 1 : 0.28)
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

    @ViewBuilder
    private func actions(isCompactHeight: Bool) -> some View {
        // `minHeight`, never a fixed height: at the largest Dynamic Type
        // sizes the label wraps, and a fixed height would clip it.
        let buttonHeight: CGFloat = isCompactHeight ? 44 : 52
        let stackSpacing: CGFloat = isCompactHeight ? 6 : 10

        switch model.step {
        case .waitingForRoll:
            VStack(spacing: stackSpacing) {
                Button(action: model.rollTutorialDice) {
                    Label("Roll", systemImage: "dice.fill")
                        .font(GameTypography.button(size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: buttonHeight)
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
                skipButton
            }
        case .selecting:
            VStack(spacing: stackSpacing) {
                Button(action: model.confirm) {
                    Label("Confirm", systemImage: "checkmark")
                        .font(GameTypography.button(size: 18))
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
                    .font(GameTypography.button(size: 19))
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
                .font(GameTypography.label(size: 15))
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
