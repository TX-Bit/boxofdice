//
//  SettingsView.swift
//  BoxOfDice
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsStorageKey.tileCount) private var tileCount = GameSettings.default.tileCount
    @AppStorage(SettingsStorageKey.diceMode) private var diceModeRawValue = GameSettings.default.diceMode.rawValue
    @AppStorage(SettingsStorageKey.moveRule) private var moveRuleRawValue = GameSettings.default.moveRule.rawValue
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.classicWood.rawValue
    @AppStorage(SettingsStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsStorageKey.soundsEnabled) private var soundsEnabled = true
    @AppStorage(SettingsStorageKey.diceAnimationSpeed) private var diceAnimationSpeedRawValue = DiceAnimationSpeed.normal.rawValue
    @AppStorage(SettingsStorageKey.confirmBehavior) private var confirmBehaviorRawValue = ConfirmBehavior.manual.rawValue
    @AppStorage(SettingsStorageKey.showHints) private var showHints = true
    @AppStorage(SettingsStorageKey.undoEnabled) private var undoEnabled = true
    @AppStorage(SettingsStorageKey.leftHandedLayout) private var leftHandedLayout = false
    @AppStorage(SettingsStorageKey.challengeMode) private var challengeModeRawValue = ChallengeMode.normal.rawValue
    @AppStorage(SettingsStorageKey.challengeSeed) private var challengeSeed = ""

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Look and Feel") {
                    Picker("Theme", selection: $themeRawValue) {
                        ForEach(GameThemeName.allCases) { theme in
                            Text(theme.title).foregroundStyle(self.theme.text).tag(theme.rawValue)
                        }
                    }

                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Sound effects", isOn: $soundsEnabled)

                    Picker("Dice animation", selection: $diceAnimationSpeedRawValue) {
                        ForEach(DiceAnimationSpeed.allCases) { speed in
                            Text(speed.title).foregroundStyle(theme.text).tag(speed.rawValue)
                        }
                    }
                }
                .themedListRow(theme)

                Section("Tile Count") {
                    Picker("Tile count", selection: $tileCount) {
                        Text("9 tiles").tag(9)
                        Text("10 tiles").tag(10)
                        Text("12 tiles").tag(12)
                    }
                    .pickerStyle(.segmented)
                }
                .themedListRow(theme)

                Section("Dice Mode") {
                    Picker("Dice mode", selection: $diceModeRawValue) {
                        ForEach(DiceMode.allCases) { mode in
                            Text(mode.title).foregroundStyle(theme.text).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .themedListRow(theme)

                Section("Move Rule") {
                    Picker("Move rule", selection: $moveRuleRawValue) {
                        ForEach(MoveRule.allCases) { rule in
                            Text(rule.title).foregroundStyle(theme.text).tag(rule.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .themedListRow(theme)

                Section("Game Flow") {
                    Picker("Confirm", selection: $confirmBehaviorRawValue) {
                        ForEach(ConfirmBehavior.allCases) { behavior in
                            Text(behavior.title).foregroundStyle(theme.text).tag(behavior.rawValue)
                        }
                    }

                    Toggle("Show hints", isOn: $showHints)
                    Toggle("Allow undo last move", isOn: $undoEnabled)
                    Toggle("Left-handed layout", isOn: $leftHandedLayout)
                }
                .themedListRow(theme)

                Section("Challenges") {
                    Picker("Mode", selection: $challengeModeRawValue) {
                        ForEach(ChallengeMode.allCases) { mode in
                            Text(mode.title).foregroundStyle(theme.text).tag(mode.rawValue)
                        }
                    }

                    TextField("Seed", text: $challengeSeed)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .themedListRow(theme)

                Section {
                    Text("Rule and challenge settings apply when you start a new game. Theme, sound, haptics, hints, undo, and layout apply immediately.")
                        .font(.footnote)
                        .foregroundStyle(theme.text.opacity(0.78))
                }
                .themedListRow(theme)
            }
            .scrollContentBackground(.hidden)
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .foregroundStyle(theme.text)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.accent)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
