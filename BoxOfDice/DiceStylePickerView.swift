//
//  DiceStylePickerView.swift
//  BoxOfDice
//

import SwiftUI

/// Dedicated dice-style picker reached from Settings → "Dice Style". Shows a
/// live, tappable 3D preview of the currently selected style at the top —
/// through the same `Dice3DView` the real game uses — and a plain list of
/// the four styles below it. The preview owns its own tiny local state; it
/// never touches `GameViewModel` or any persisted game state.
struct DiceStylePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let theme: GameTheme
    @AppStorage(SettingsStorageKey.diceStyle) private var diceStyleRawValue = DiceStyleName.ivory.rawValue

    @State private var previewValue = 5
    @State private var previewIsRolling = false

    private var selectedName: DiceStyleName {
        DiceStyleName(rawValue: diceStyleRawValue) ?? .ivory
    }

    var body: some View {
        CompatibleNavigationContainer {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    preview
                    styleList
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .compatibleHiddenScrollBackground()
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .navigationTitle(L10n.string("Dice Style"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("Done")) { dismiss() }
                        .compatibleSemibold()
                        .foregroundStyle(theme.accent)
                }
            }
        }
    }

    // MARK: - Live preview

    private var preview: some View {
        VStack(spacing: 10) {
            Button(action: spin) {
                Dice3DView(
                    value: previewValue,
                    isRolling: previewIsRolling,
                    dieIndex: 0,
                    rollDuration: DiceAnimationSpeed.normal.tumbleDuration,
                    style: DiceStyle.palette(for: selectedName)
                )
                .frame(width: 132, height: 132)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("Dice style preview"))
            .accessibilityHint(L10n.string("Double-tap to roll the preview die"))
            .accessibilityAddTraits(.isButton)

            Text(L10n.string("Tap to roll"))
                .font(GameTypography.label(size: 13))
                .foregroundStyle(theme.text.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func spin() {
        guard !previewIsRolling else { return }
        let next = Int.random(in: 1...6)
        if reduceMotion {
            // No tumble — the die simply shows the new face, matching the
            // reduced-motion behavior of the real in-game roll.
            previewValue = next
            return
        }
        previewValue = next
        previewIsRolling = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: DiceAnimationSpeed.normal.totalRollDurationNanoseconds(dieCount: 1))
            previewIsRolling = false
        }
    }

    // MARK: - Style list

    private var styleList: some View {
        VStack(spacing: 0) {
            ForEach(Array(DiceStyleName.allCases.enumerated()), id: \.element) { index, name in
                if index > 0 {
                    Divider().overlay(Color.white.opacity(0.08)).padding(.horizontal, 16)
                }
                styleRow(name)
            }
        }
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func styleRow(_ name: DiceStyleName) -> some View {
        let isSelected = name == selectedName
        return Button {
            diceStyleRawValue = name.rawValue
        } label: {
            HStack(spacing: 12) {
                swatch(for: name)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name.title)
                        .font(GameTypography.label(size: 16))
                        .foregroundStyle(theme.text.opacity(0.92))
                    Text(name.subtitle)
                        .font(GameTypography.label(size: 12))
                        .foregroundStyle(theme.text.opacity(0.55))
                }

                Spacer()

                // Selection is never color-only: a filled checkmark badge,
                // not just a tinted row, marks the current choice — legible
                // under every board theme and to color-blind users.
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? theme.accent : theme.text.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(Text("\(name.title). \(name.subtitle)"))
    }

    /// A small flat swatch (die body + a 3-pip hint in the pip color) — a
    /// quick static reference beside each row, independent of the live
    /// SceneKit preview above.
    private func swatch(for name: DiceStyleName) -> some View {
        let style = DiceStyle.palette(for: name)
        return RoundedRectangle(cornerRadius: 8)
            .fill(style.bodyColor)
            .overlay(
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(style.pipColor).frame(width: 4, height: 4)
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.black.opacity(0.18), lineWidth: 1))
            .frame(width: 34, height: 34)
    }
}

#Preview {
    DiceStylePickerView(theme: .palette(for: .greenFelt))
}
