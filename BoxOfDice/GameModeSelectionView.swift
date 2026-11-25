//
//  GameModeSelectionView.swift
//  BoxOfDice
//

import SwiftUI

struct GameModeSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsStorageKey.theme) private var themeRawValue = GameThemeName.defaultTheme.rawValue

    @State private var selectedMode: GameMode
    @State private var playerCount: Int
    @State private var isConfirmingReplacement = false

    let requiresReplacementConfirmation: () -> Bool
    let onStart: (GameMode, Int) -> Void

    init(requiresReplacementConfirmation: @escaping () -> Bool = { false },
         onStart: @escaping (GameMode, Int) -> Void) {
        self.requiresReplacementConfirmation = requiresReplacementConfirmation
        self.onStart = onStart
        let defaults = UserDefaults.standard
        let rawMode = defaults.string(forKey: SettingsStorageKey.gameMode) ?? GameMode.classic.rawValue
        _selectedMode = State(initialValue: GameMode(rawValue: rawMode) ?? .classic)
        let savedPlayerCount = defaults.object(forKey: SettingsStorageKey.passAndPlayPlayerCount) as? Int ?? 2
        _playerCount = State(initialValue: min(4, max(2, savedPlayerCount)))
    }

    private var theme: GameTheme {
        GameTheme.palette(for: GameThemeName(rawValue: themeRawValue) ?? .defaultTheme)
    }

    var body: some View {
        CompatibleNavigationContainer {
            GeometryReader { proxy in
                let canSplitGroups = proxy.size.width >= 540
                let playersBesideStart = canSplitGroups && proxy.size.height < 430 && selectedMode == .passAndPlay

                VStack(spacing: 8) {
                    modeList(canSplitGroups: canSplitGroups, showsPlayers: !playersBesideStart && selectedMode == .passAndPlay)
                    if playersBesideStart {
                        HStack(alignment: .bottom, spacing: 12) {
                            playerCountSection
                            startButton.frame(width: proxy.size.width * 0.30)
                        }
                    } else {
                        startButton
                    }
                }
                .frame(maxWidth: 640)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .compatibleHiddenScrollBackground()
            .background(ThemedSheetBackground(theme: theme))
            .tint(theme.accent)
            .navigationTitle("Choose Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .compatibleSemibold()
                        .foregroundStyle(theme.accent)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMode)
        }
        .alert(Text(L10n.string("Start a new game?")), isPresented: $isConfirmingReplacement) {
            Button(role: .cancel) {} label: { Text(L10n.string("Cancel")) }
            Button(role: .destructive, action: startSelectedGame) {
                Text(L10n.string("Start Game"))
            }
        } message: {
            Text(L10n.string("Your current game will end."))
        }
    }

    @ViewBuilder
    private func modeList(canSplitGroups: Bool, showsPlayers: Bool) -> some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .vertical) {
                groupedModes(split: false, showsPlayers: showsPlayers)
                    .fixedSize(horizontal: false, vertical: true)
                if canSplitGroups {
                    groupedModes(split: true, showsPlayers: showsPlayers)
                        .fixedSize(horizontal: false, vertical: true)
                }
                scrollableGroups(split: canSplitGroups, showsPlayers: showsPlayers)
            }
        } else {
            scrollableGroups(split: false, showsPlayers: showsPlayers)
        }
    }

    private func scrollableGroups(split: Bool, showsPlayers: Bool) -> some View {
        ScrollView(showsIndicators: false) {
            groupedModes(split: split, showsPlayers: showsPlayers)
        }
        .compatibleBounceBasedOnSize()
    }

    private func groupedModes(split: Bool, showsPlayers: Bool) -> some View {
        VStack(spacing: 8) {
            if split {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 8) {
                        modeGroup("Quick", modes: [.quickGame])
                        modeGroup("Classic", modes: [.classic, .speedRun])
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 8) {
                        modeGroup("Big Box", modes: [.bigBox, .bigBoxSpeed])
                        modeGroup("Multiplayer", modes: [.passAndPlay])
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                modeGroup("Quick", modes: [.quickGame])
                modeGroup("Classic", modes: [.classic, .speedRun])
                modeGroup("Big Box", modes: [.bigBox, .bigBoxSpeed])
                modeGroup("Multiplayer", modes: [.passAndPlay])
            }
            if showsPlayers {
                playerCountSection
            }
        }
    }

    private func modeGroup(_ title: String, modes: [GameMode]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L10n.string(title).uppercased())
                .font(GameTypography.section(size: 12))
                .tracking(1.3)
                .foregroundStyle(theme.text.opacity(0.58))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(modes.enumerated()), id: \.element) { index, mode in
                    if index > 0 {
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.horizontal, 12)
                    }
                    modeRow(mode)
                }
            }
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
    }

    private func modeRow(_ mode: GameMode) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            selectedMode = mode
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.title)
                        .font(GameTypography.label(size: 17))
                        .foregroundStyle(isSelected ? theme.text : theme.text.opacity(0.70))
                    Text(mode.subtitle)
                        .font(GameTypography.caption(size: 13))
                        .foregroundStyle(theme.text.opacity(0.50))
                        .fixedSize(horizontal: false, vertical: true)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Player count

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 3) {
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
            .padding(.vertical, 2)
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
            if requiresReplacementConfirmation() {
                isConfirmingReplacement = true
            } else {
                startSelectedGame()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Start Game")
                    .font(GameTypography.button(size: 19))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .buttonStyle(ModeStartButtonStyle())
    }

    private func startSelectedGame() {
        UserDefaults.standard.set(playerCount, forKey: SettingsStorageKey.passAndPlayPlayerCount)
        onStart(selectedMode, playerCount)
        dismiss()
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
