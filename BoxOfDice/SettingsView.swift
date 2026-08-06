//
//  SettingsView.swift
//  BoxOfDice
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    /// BOD-012: reopens the first-launch tutorial as a replay. Defaults to
    /// a no-op so `#Preview` and any other caller that doesn't need this
    /// doesn't have to pass it.
    var onShowHowToPlay: () -> Void = {}

    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.greenFelt.rawValue
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
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .greenFelt)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    lookAndFeelSection
                    gameFlowSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accent)
                }
            }
            .sheet(isPresented: $isShowingDiceStylePicker) {
                DiceStylePickerView(theme: theme)
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

    private var lookAndFeelSection: some View {
        settingsCard(title: "Look & Feel") {
            HStack {
                rowLabel("Language")
                Spacer()
                Picker("", selection: $languageRawValue) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.title).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.accent)
                .font(GameTypography.label(size: 18))
            }
            .rowPadding()

            cardDivider

            HStack {
                rowLabel("Theme")
                Spacer()
                Picker("", selection: $themeRawValue) {
                    ForEach(GameThemeName.allCases) { t in
                        Text(t.title)
                            .font(GameTypography.label(size: 18))
                            .tag(t.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.accent)
                .font(GameTypography.label(size: 18))
            }
            .rowPadding()

            cardDivider

            toggleRow("Haptics", isOn: $hapticsEnabled)
            cardDivider
            toggleRow("Sound Effects", isOn: $soundsEnabled)
            cardDivider

            HStack {
                rowLabel("Dice Animation")
                Spacer()
                Picker("", selection: $diceAnimationSpeedRawValue) {
                    ForEach(DiceAnimationSpeed.allCases) { speed in
                        Text(speed.title).tag(speed.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.accent)
                .font(GameTypography.label(size: 18))
            }
            .rowPadding()

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
            HStack {
                rowLabel(label)
                Spacer()
                Text(value)
                    .font(GameTypography.label(size: 18))
                    .foregroundStyle(theme.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text.opacity(0.40))
            }
            .rowPadding()
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
