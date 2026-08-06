//
//  WatchOnboardingView.swift
//  BoxOfDice Watch App
//

import SwiftUI

/// Watch's first-launch tutorial (BOD-012) — same flow and shared state
/// machine (`OnboardingViewModel`, from GameEngine.swift's target) as iOS's
/// OnboardingView.swift, with its own compact layout and short button/prompt
/// text sized for the small screen.
struct WatchOnboardingView: View {
    @StateObject private var model = OnboardingViewModel()
    let theme: GameTheme
    let isReplay: Bool
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            WatchBackground(theme: theme).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    promptText
                        .font(GameTypography.label(size: 13))
                        .foregroundStyle(theme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)

                    // BOD-012 follow-up (docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §2):
                    // the Watch tutorial showed neither how much the current
                    // selection adds up to nor the target, so a beginner
                    // facing a disabled Confirm button had no way to see what
                    // was missing. iOS has shown this from the start.
                    if let progress = progressText {
                        progress
                            .font(GameTypography.caption(size: 12))
                            .foregroundStyle(theme.text.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    board
                        .padding(.top, 2)

                    diceRow

                    actions
                        .padding(.top, 4)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
        }
        .navigationTitle(L10n.string("Box of Dice"))
    }

    // Same keys as iOS's OnboardingView.swift (not shortened Watch-only
    // variants) — one translation per concept, sized down here instead of
    // reworded, per BOD-013's guidance to prefer a natural short
    // translation over rewriting the source text per platform.
    private var promptText: Text {
        switch model.step {
        case .waitingForRoll:
            return Text(L10n.string("Roll the dice"))
        case .selecting:
            return Text(L10n.format("You rolled %lld. Try closing %lld, or %lld + %lld.", model.diceTotal, model.diceTotal, model.dice[0], model.dice[1]))
        case .resolved:
            return Text(L10n.string("Nice! The goal is to leave as few points as possible."))
        }
    }

    /// Selection progress during the selecting step, and the "empty board
    /// scores nothing" point at the end — both shown on iOS from the start.
    private var progressText: Text? {
        switch model.step {
        case .waitingForRoll:
            return nil
        case .selecting:
            // Same keys as iOS: the running selection sum, then the target
            // it has to reach.
            return Text(L10n.format("Selected %lld", model.selectionTotal))
                + Text(" · ")
                + Text(L10n.format("Target %lld", model.diceTotal))
        case .resolved:
            return Text(L10n.string("Empty board = 0."))
        }
    }

    private var board: some View {
        let columns = Array(repeating: GridItem(.fixed(26), spacing: 4), count: 5)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(model.tiles) { tile in
                Button {
                    model.toggleTile(tile.id)
                } label: {
                    Text("\(tile.id)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(width: 26, height: 30)
                        .background(
                            (model.selectedTiles.contains(tile.id) ? theme.accent : Color.black.opacity(0.22)),
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .foregroundStyle(tile.isOpen ? theme.text : theme.text.opacity(0.25))
                        .strikethrough(!tile.isOpen)
                }
                .buttonStyle(.plain)
                .disabled(model.step != .selecting || !tile.isOpen)
                .accessibilityLabel(
                    tile.isOpen
                        ? L10n.format("Tile %lld, open", tile.id)
                        : L10n.format("Tile %lld, closed", tile.id)
                )
                .accessibilityAddTraits(model.selectedTiles.contains(tile.id) ? .isSelected : [])
            }
        }
    }

    private var diceRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Text(model.hasRolled ? "\(model.dice[index])" : "–")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(theme.text)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch model.step {
        case .waitingForRoll:
            VStack(spacing: 4) {
                Button(L10n.string("Roll"), action: model.rollTutorialDice)
                    .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))
                skipButton
            }
        case .selecting:
            VStack(spacing: 4) {
                Button(L10n.string("Confirm"), action: model.confirm)
                    .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))
                    .disabled(!model.canConfirm)
                skipButton
            }
        case .resolved:
            Button(isReplay ? L10n.string("Back to Game") : L10n.string("Start Game"), action: onFinish)
                .buttonStyle(WatchSheetPrimaryButtonStyle(theme: theme))
        }
    }

    private var skipButton: some View {
        Button(isReplay ? L10n.string("Back to Game") : L10n.string("Skip"), action: onFinish)
            .buttonStyle(WatchDestructiveButtonStyle())
    }
}

#Preview {
    WatchOnboardingView(theme: GameTheme.palette(for: .greenFelt), isReplay: false, onFinish: {})
}
