//
//  SettingsView.swift
//  BoxOfDice
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.classicWood.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    @AppStorage(SettingsStorageKey.language) private var languageRawValue = AppLanguage.system.rawValue

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
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
                .font(GameTypography.label(size: 16))
            }
            .rowPadding()

            cardDivider

            HStack {
                rowLabel("Theme")
                Spacer()
                Picker("", selection: $themeRawValue) {
                    ForEach(GameThemeName.allCases) { t in
                        Text(t.title).tag(t.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.accent)
                .font(GameTypography.label(size: 16))
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
                .font(GameTypography.label(size: 16))
            }
            .rowPadding()
        }
    }

    private var gameFlowSection: some View {
        settingsCard(title: "Game Flow") {
            toggleRow("Show Hints", isOn: $showHints)
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

    private func rowLabel(_ text: String) -> some View {
        Text(L10n.string(text))
            .font(GameTypography.label(size: 16))
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
