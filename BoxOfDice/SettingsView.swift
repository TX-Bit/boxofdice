//
//  SettingsView.swift
//  BoxOfDice
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fullGameStore = FullGameStore.shared
    @State private var isShowingFullVersion = false

    /// BOD-012: reopens the first-launch tutorial as a replay. Defaults to
    /// a no-op so `#Preview` and any other caller that doesn't need this
    /// doesn't have to pass it.
    var onShowHowToPlay: () -> Void = {}

    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.defaultTheme.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.diceStyle) private var diceStyleRawValue = DiceStyleName.ivory.rawValue
    @State private var isShowingDiceStylePicker = false
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    // Same default as ContentView.swift — see the comment there (BOD-012).
    @AppStorage(SettingsStorageKey.showDiceTotal) private var showDiceTotal = true
    @AppStorage(SettingsStorageKey.language) private var languageRawValue = AppLanguage.system.rawValue

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .defaultTheme)
    }

    var body: some View {
        CompatibleNavigationContainer {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    fullVersionSection
                    lookAndFeelSection
                    gameFlowSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .compatibleHiddenScrollBackground()
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .compatibleSemibold()
                        .foregroundStyle(theme.accent)
                }
            }
            .sheet(isPresented: $isShowingDiceStylePicker) {
                DiceStylePickerView(theme: theme)
            }
            .sheet(isPresented: $isShowingFullVersion) {
                FullGamePurchaseView(store: fullGameStore, theme: theme)
                    .environment(\.locale, languageLocale)
            }
        }
        // Menu pickers don't refresh their displayed label from a plain state
        // change when the selection tag is unchanged — rebuild the whole sheet so
        // the Theme / Dice Animation values switch language immediately.
        .id(languageRawValue)
        .environment(\.locale, languageLocale)
    }

    private var languageLocale: Locale {
        let language = AppLanguage(rawValue: languageRawValue) ?? .system
        return language == .system ? .current : Locale(identifier: language.rawValue)
    }

    // MARK: - Sections

    private var fullVersionSection: some View {
        settingsCard(title: "Full Version") {
            navigationRow(fullGameStore.isUnlocked ? "Full Version Unlocked" : "Unlock Unlimited Play") {
                isShowingFullVersion = true
            }
        }
    }

    private var lookAndFeelSection: some View {
        settingsCard(title: "Look & Feel") {
            Menu {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        languageRawValue = lang.rawValue
                    } label: {
                        if languageRawValue == lang.rawValue {
                            Label(lang.title, systemImage: "checkmark")
                        } else {
                            Text(lang.title)
                        }
                    }
                }
            } label: {
                selectionRowContent("Language", value: (AppLanguage(rawValue: languageRawValue) ?? .system).title)
            }

            cardDivider

            Menu {
                ForEach(GameThemeName.allCases) { selectedTheme in
                    Button {
                        themeRawValue = selectedTheme.rawValue
                    } label: {
                        if themeRawValue == selectedTheme.rawValue {
                            Label(selectedTheme.title, systemImage: "checkmark")
                        } else {
                            Text(selectedTheme.title)
                        }
                    }
                }
            } label: {
                selectionRowContent("Theme", value: (GameThemeName(rawValue: themeRawValue) ?? .defaultTheme).title)
            }

            cardDivider

            toggleRow("Haptics", isOn: $hapticsEnabled)
            cardDivider
            toggleRow("Sound Effects", isOn: $soundsEnabled)
            cardDivider

            Menu {
                ForEach(DiceAnimationSpeed.allCases) { speed in
                    Button {
                        diceAnimationSpeedRawValue = speed.rawValue
                    } label: {
                        if diceAnimationSpeedRawValue == speed.rawValue {
                            Label(speed.title, systemImage: "checkmark")
                        } else {
                            Text(speed.title)
                        }
                    }
                }
            } label: {
                selectionRowContent("Dice Animation", value: (DiceAnimationSpeed(rawValue: diceAnimationSpeedRawValue) ?? .normal).title)
            }

            cardDivider

            valueNavigationRow(
                "Dice Style",
                value: (DiceStyleName(rawValue: diceStyleRawValue) ?? .ivory).title
            ) {
                isShowingDiceStylePicker = true
            }
        }
    }

    private var gameFlowSection: some View {
        settingsCard(title: "Game Flow") {
            toggleRow("Show Hints", isOn: $showHints)
            cardDivider
            toggleRow("Show Dice Total", isOn: $showDiceTotal)
            cardDivider
            navigationRow("How to Play") {
                dismiss()
                onShowHowToPlay()
            }
        }
    }

    // MARK: - Card wrapper

    private func settingsCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(title).uppercased())
                .font(GameTypography.section(size: 12))
                .tracking(1.3)
                .foregroundStyle(theme.text.opacity(0.58))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
    }

    // MARK: - Row components

    private func selectionRowContent(_ label: String, value: String, chevron: String = "chevron.down") -> some View {
        Group {
            if #available(iOS 16.0, *) {
                ViewThatFits(in: .horizontal) {
                    horizontalSelectionRow(label, value: value, chevron: chevron)
                    verticalSelectionRow(label, value: value, chevron: chevron)
                }
            } else {
                // The two-line layout avoids clipped localized values on iOS 15.
                verticalSelectionRow(label, value: value, chevron: chevron)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func horizontalSelectionRow(_ label: String, value: String, chevron: String) -> some View {
        HStack(spacing: 8) {
            rowLabel(label)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            selectedValue(value)
                .fixedSize(horizontal: true, vertical: false)
            selectionChevron(chevron)
        }
    }

    private func verticalSelectionRow(_ label: String, value: String, chevron: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            rowLabel(label)
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                selectedValue(value)
                    .multilineTextAlignment(.trailing)
                selectionChevron(chevron)
            }
        }
    }

    private func selectedValue(_ value: String) -> some View {
        Text(value)
            .font(GameTypography.label(size: 18))
            .foregroundStyle(theme.accent)
    }

    private func selectionChevron(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.text.opacity(0.40))
            .accessibilityHidden(true)
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            rowLabel(label)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.accent)
        }
        .rowPadding()
    }

    private func navigationRow(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                rowLabel(label)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.text.opacity(0.40))
            }
            .rowPadding()
        }
        .buttonStyle(.plain)
    }

    /// Like `navigationRow`, but also shows the current value (e.g. the
    /// selected dice style's name) before the chevron — for a row whose
    /// picker lives on its own screen rather than an inline menu.
    private func valueNavigationRow(_ label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            selectionRowContent(label, value: value, chevron: "chevron.right")
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(L10n.string(text))
            .font(GameTypography.label(size: 18))
            .foregroundStyle(theme.text.opacity(0.85))
    }

    private var cardDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.08))
            .padding(.horizontal, 16)
    }
}

private extension View {
    func rowPadding() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
}
