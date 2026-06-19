//
//  GameModeSelectionView.swift
//  BoxOfDice
//

import SwiftUI

struct GameModeSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsStorageKey.gameMode) private var gameModeRaw = GameMode.classic.rawValue
    @AppStorage(SettingsStorageKey.passAndPlayPlayerCount) private var playerCount = 2
    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.greenFelt.rawValue

    let onStart: (GameMode, Int) -> Void

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .classicWood)
    }

    private var selectedMode: GameMode {
        GameMode(rawValue: gameModeRaw) ?? .classic
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    modeGroup("Classic", modes: [.classic, .speedRun])
                    modeGroup("Big Box", modes: [.bigBox, .bigBoxSpeed])
                    modeGroup("Multiplayer", modes: [.passAndPlay])

                    if selectedMode == .passAndPlay {
                        playerCountSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    startButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .navigationTitle("Choose Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accent)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMode)
        }
    }

    // MARK: - Mode groups

    private func modeGroup(_ title: String, modes: [GameMode]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(title).uppercased())
                .font(GameTypography.section(size: 12))
                .tracking(1.3)
                .foregroundStyle(theme.text.opacity(0.58))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(modes.enumerated()), id: \.element) { index, mode in
                    if index > 0 {
                        cardDivider
                    }
                    modeRow(mode)
                }
            }
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
    }

    private func modeRow(_ mode: GameMode) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            gameModeRaw = mode.rawValue
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.title)
                        .font(GameTypography.label(size: 17))
                        .foregroundStyle(isSelected ? theme.text : theme.text.opacity(0.70))
                    Text(mode.subtitle)
                        .font(GameTypography.caption(size: 13))
                        .foregroundStyle(theme.text.opacity(0.50))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(theme.accent)
                } else {
                    Circle()
                        .strokeBorder(theme.text.opacity(0.22), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player count

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLAYERS")
                .font(GameTypography.section(size: 12))
                .tracking(1.3)
                .foregroundStyle(theme.text.opacity(0.58))
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(2...4, id: \.self) { count in
                    playerCountButton(count)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
    }

    private func playerCountButton(_ count: Int) -> some View {
        let selected = playerCount == count
        return Button { playerCount = count } label: {
            Text("\(count) players")
                .font(GameTypography.button(size: 16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    selected
                        ? LinearGradient(colors: theme.button, startPoint: .top, endPoint: .bottom)
                        : LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)],
                            startPoint: .top, endPoint: .bottom
                          ),
                    in: RoundedRectangle(cornerRadius: 11)
                )
                .foregroundStyle(
                    selected
                        ? Color(red: 0.15, green: 0.07, blue: 0.01)
                        : theme.text.opacity(0.60)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(
                            selected ? Color.white.opacity(0.40) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            onStart(selectedMode, playerCount)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Start Game")
                    .font(GameTypography.button(size: 19))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(ModeStartButtonStyle())
        .padding(.top, 4)
    }

    private var cardDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.08))
            .padding(.horizontal, 16)
    }
}

private struct ModeStartButtonStyle: ButtonStyle {
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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

#Preview {
    GameModeSelectionView { _, _ in }
}
