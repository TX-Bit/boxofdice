//
//  GameOverView.swift
//  BoxOfDice
//

import SwiftUI

private struct LegacyShareSheet: UIViewControllerRepresentable {
    let message: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [message], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct ResultCardLayout<Content: View, Background: View, Border: View>: View {
    var usesCompactCard = false
    @ViewBuilder let content: (Bool, Bool) -> Content
    @ViewBuilder let background: () -> Background
    @ViewBuilder let border: () -> Border

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isWide = !usesCompactCard && size.width >= 480 && size.width > size.height
            let isCompact = usesCompactCard || size.height < (isWide ? 450 : 590)
            let card = content(isWide, isCompact)
                .padding(isCompact ? 12 : 22)
                .frame(maxWidth: usesCompactCard ? 350 : (isWide ? 620 : 372))
                .fixedSize(horizontal: false, vertical: true)
                .background(background())
                .overlay(border().allowsHitTesting(false))
                .shadow(color: .black.opacity(0.40), radius: 18, y: 9)
                .padding(.horizontal, 12)
                .padding(.vertical, isCompact ? 8 : 14)
                .frame(maxWidth: .infinity, minHeight: size.height)

            // The card fits supported full-screen sizes. Keep the fallback for
            // unusually small windows where the intrinsic content is taller.
            if #available(iOS 16.4, *) {
                ScrollView(showsIndicators: false) { card }
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                ScrollView(showsIndicators: false) { card }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

// Warm "premium board game" palette used only when the Light theme is active, so
// the result/celebration card reads as ivory & walnut instead of washed-out gray.
private enum WarmLight {
    static let parchment      = Color(red: 0.965, green: 0.914, blue: 0.824) // #F6E9D2
    static let parchmentTop   = Color(red: 0.984, green: 0.953, blue: 0.886) // lighter top
    static let goldBorder     = Color(red: 0.894, green: 0.784, blue: 0.569) // #E4C891
    static let walnut         = Color(red: 0.169, green: 0.102, blue: 0.055) // #2B1A0E
    static let warmBrown      = Color(red: 0.435, green: 0.329, blue: 0.220) // #6F5438
    static let taupe          = Color(red: 0.541, green: 0.463, blue: 0.369) // #8A765E
    static let label          = Color(red: 0.604, green: 0.416, blue: 0.184) // #9A6A2F
    static let cream          = Color(red: 0.918, green: 0.863, blue: 0.773) // #EADCC5
    static let creamBorder    = Color(red: 0.847, green: 0.737, blue: 0.533) // #D8BC88
    static let primaryTop     = Color(red: 0.961, green: 0.710, blue: 0.259) // #F5B542
    static let primaryBottom  = Color(red: 0.851, green: 0.510, blue: 0.086) // #D98216
    static let secondaryFill  = Color(red: 0.910, green: 0.843, blue: 0.722) // #E8D7B8
    static let secondaryText  = Color(red: 0.294, green: 0.204, blue: 0.125) // #4B3420
    static let secondaryBorder = Color(red: 0.824, green: 0.706, blue: 0.486) // #D2B47C
}

struct GameOverView: View {
    let kind: GameResultKind
    let tileScore: Int
    let elapsedSeconds: Int
    let isTimed: Bool
    let modeName: String
    let isNewBest: Bool
    let isFirstScore: Bool
    let previousBest: Int?
    let shareMessage: String
    let theme: GameTheme
    let onNewGame: () -> Void
    let onSettings: () -> Void
    let onStats: () -> Void

    @State private var isShowingLegacyShareSheet = false

    var won: Bool { kind == .boardCleared || kind == .perfectClear }
    var finalScore: Int { isTimed ? tileScore + elapsedSeconds : tileScore }

    // Light theme gets the dedicated warm palette; every other theme is untouched.
    private var isLight: Bool { theme.name == .minimalLight }
    private var primaryText: Color { isLight ? WarmLight.walnut : theme.text }
    private var secondaryText: Color { isLight ? WarmLight.warmBrown : theme.text.opacity(0.72) }
    private var mutedText: Color { isLight ? WarmLight.warmBrown : theme.text.opacity(0.52) }
    private var sectionLabel: Color { isLight ? WarmLight.label : theme.accent.opacity(0.82) }

    var body: some View {
        ResultCardLayout(usesCompactCard: true) { _, isCompact in
            VStack(spacing: isCompact ? 8 : 16) {
                HStack(alignment: .top, spacing: 8) {
                    iconButton("chart.bar.fill", label: "Statistics", action: onStats)
                    header(isCompact: isCompact)
                        .frame(maxWidth: .infinity)
                    iconButton("gearshape.fill", label: "Settings", action: onSettings)
                }
                scorePanel(isCompact: isCompact)
                actionButtons(isCompact: isCompact)
            }
        } background: {
            cardBackground
        } border: {
            cardBorder
        }
    }

    private func iconButton(_ systemName: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isLight ? WarmLight.walnut : theme.text.opacity(0.78))
                .frame(width: 34, height: 34)
                .background(isLight ? WarmLight.secondaryFill : Color.black.opacity(0.20), in: Circle())
                .overlay(Circle().strokeBorder(isLight ? WarmLight.secondaryBorder : Color.white.opacity(0.14), lineWidth: 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func header(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 4 : 8) {
            Text(L10n.string(titleText))
                .font(GameTypography.title(size: isCompact ? (kind == .gameOver ? 25 : 23) : (kind == .gameOver ? 34 : 31)))
                .foregroundStyle(titleGradient)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.78)
                .shadow(color: isLight ? WarmLight.walnut.opacity(0.18) : .clear,
                        radius: isLight ? 1 : 0, x: 0, y: isLight ? 1 : 0)

            if !modeName.isEmpty {
                modePill(isCompact: isCompact)
            }
        }
    }

    private func modePill(isCompact: Bool) -> some View {
        Text(modeName)
            .font(GameTypography.caption(size: isCompact ? 11 : 12))
            .tracking(0.4)
            .foregroundStyle(isLight ? WarmLight.warmBrown : theme.text.opacity(0.78))
            .padding(.horizontal, isCompact ? 10 : 12)
            .padding(.vertical, isCompact ? 3 : 4)
            .background(Capsule().fill(isLight ? WarmLight.cream : Color.black.opacity(0.22)))
            .overlay(Capsule().strokeBorder(isLight ? WarmLight.goldBorder : Color.white.opacity(0.12), lineWidth: 1))
            .padding(.top, isCompact ? 0 : 2)
    }

    private func scorePanel(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 3 : 6) {
            Text("FINAL SCORE")
                .font(GameTypography.section(size: isCompact ? 10 : 12))
                .tracking(isCompact ? 1.4 : 1.8)
                .foregroundStyle(sectionLabel)

            Text("\(finalScore)")
                .font(GameTypography.display(size: isCompact ? 40 : 64))
                .foregroundStyle(primaryText)

            if isTimed && elapsedSeconds > 0 {
                HStack(spacing: 6) {
                    Text("Tile score \(tileScore)")
                    Text("+")
                    Label("\(elapsedSeconds)s", systemImage: "timer")
                }
                .font(GameTypography.caption(size: isCompact ? 11 : 13))
                .foregroundStyle(isLight ? WarmLight.label : theme.accent.opacity(0.76))
            } else {
                Text("Lower is better")
                    .font(GameTypography.caption(size: isCompact ? 11 : 12))
                    .foregroundStyle(mutedText)
            }

            bestDetails(isCompact: isCompact)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 6 : 16)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 14 : 18)
                .fill(isLight ? WarmLight.cream : Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 14 : 18)
                        .strokeBorder(isLight ? WarmLight.creamBorder : Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func bestDetails(isCompact: Bool) -> some View {
        if isNewBest && (kind != .newBest || previousBest != nil) {
            VStack(spacing: isCompact ? 2 : 4) {
                if kind != .newBest {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: isCompact ? 11 : 13, weight: .bold))
                        Text(L10n.string(isFirstScore ? "First Score!" : "New Best!"))
                            .font(GameTypography.button(size: isCompact ? 14 : 16))
                    }
                    .foregroundStyle(isLight ? lightGoldTitle : goldGradient)
                }

                if let previousBest {
                    Text(L10n.format("Previous best %lld", previousBest))
                        .font(GameTypography.caption(size: isCompact ? 11 : 13))
                        .foregroundStyle(secondaryText)
                }
            }
            .padding(.top, 4)
        }
    }

    private func actionButtons(isCompact: Bool) -> some View {
        HStack(spacing: 10) {
            Button(action: onNewGame) {
                Text("New Game")
                    .font(GameTypography.button(size: isCompact ? 16 : 18))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isCompact ? 44 : 48)
            }
            .buttonStyle(ModalButtonStyle(theme: theme, isLight: isLight))

            if #available(iOS 16.0, *) {
                ShareLink(item: shareMessage) {
                    shareButtonLabel(isCompact: isCompact)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
            } else {
                Button {
                    isShowingLegacyShareSheet = true
                } label: {
                    shareButtonLabel(isCompact: isCompact)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
                .sheet(isPresented: $isShowingLegacyShareSheet) {
                    LegacyShareSheet(message: shareMessage)
                }
            }
        }
    }

    private func shareButtonLabel(isCompact: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
            Text("Share")
                .font(GameTypography.button(size: isCompact ? 14 : 16))
        }
        .foregroundStyle(isLight ? WarmLight.secondaryText : theme.text.opacity(0.82))
        .frame(maxWidth: .infinity)
        .frame(minHeight: isCompact ? 44 : 48)
        .background(isLight ? WarmLight.secondaryFill : Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(isLight ? WarmLight.secondaryBorder : Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Result-specific copy & colour

    private var titleText: String {
        switch kind {
        case .perfectClear: return "Perfect Clear!"
        case .boardCleared: return "Board Cleared!"
        case .newBest:      return isFirstScore ? "First Score!" : "New Best!"
        case .gameOver:     return "Game Over"
        }
    }

    private var titleGradient: LinearGradient {
        if isLight {
            switch kind {
            case .boardCleared:
                return LinearGradient(
                    colors: [Color(red: 0.31, green: 0.64, blue: 0.21), Color(red: 0.18, green: 0.46, blue: 0.13)],
                    startPoint: .top, endPoint: .bottom
                )
            case .perfectClear, .newBest:
                return lightGoldTitle
            case .gameOver:
                return LinearGradient(
                    colors: [Color(red: 0.78, green: 0.48, blue: 0.12), Color(red: 0.58, green: 0.30, blue: 0.07)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        switch kind {
        case .boardCleared:
            return LinearGradient(
                colors: [Color(red: 0.72, green: 1.0, blue: 0.50), Color(red: 0.35, green: 0.82, blue: 0.30)],
                startPoint: .top, endPoint: .bottom
            )
        case .perfectClear, .newBest:
            return goldGradient
        case .gameOver:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.88, blue: 0.60), Color(red: 0.96, green: 0.56, blue: 0.22)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    // Strong, celebratory gold→orange for the light card.
    private var lightGoldTitle: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.93, green: 0.62, blue: 0.13), Color(red: 0.76, green: 0.33, blue: 0.09)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.91, blue: 0.68), Color(red: 0.86, green: 0.56, blue: 0.24)],
            startPoint: .top, endPoint: .bottom
        )
    }

    @ViewBuilder
    private var cardBackground: some View {
        if isLight {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [WarmLight.parchmentTop, WarmLight.parchment],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 26)
            .strokeBorder(
                isLight
                    ? LinearGradient(
                        colors: [WarmLight.goldBorder.opacity(0.95), WarmLight.goldBorder.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            theme.accent.opacity(0.25),
                            Color.black.opacity(0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                lineWidth: 1.5
            )
    }
}

private struct ModalButtonStyle: ButtonStyle {
    let theme: GameTheme
    var isLight: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.169, green: 0.102, blue: 0.055))
            .background(
                LinearGradient(colors: buttonColors, startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(isLight ? 0.45 : 0.34), lineWidth: 1)
            )
            .shadow(color: isLight ? WarmLight.primaryBottom.opacity(0.40) : .black.opacity(0.30),
                    radius: 8, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var buttonColors: [Color] {
        isLight ? [WarmLight.primaryTop, WarmLight.primaryBottom] : theme.button
    }
}

#Preview("Game Over — Light") {
    let theme = GameTheme.palette(for: .minimalLight)
    ZStack {
        LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        GameOverView(kind: .gameOver, tileScore: 24, elapsedSeconds: 0, isTimed: false, modeName: "Classic", isNewBest: false, isFirstScore: false, previousBest: 18, shareMessage: "", theme: theme, onNewGame: {}, onSettings: {}, onStats: {})
    }
}

#Preview("New Best — Light") {
    let theme = GameTheme.palette(for: .minimalLight)
    ZStack {
        LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        GameOverView(kind: .newBest, tileScore: 14, elapsedSeconds: 0, isTimed: false, modeName: "Classic", isNewBest: true, isFirstScore: false, previousBest: 31, shareMessage: "", theme: theme, onNewGame: {}, onSettings: {}, onStats: {})
    }
}

#Preview("Perfect Clear") {
    let theme = GameTheme.palette(for: .classicWood)
    ZStack {
        LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        GameOverView(kind: .perfectClear, tileScore: 0, elapsedSeconds: 0, isTimed: false, modeName: "Classic", isNewBest: true, isFirstScore: false, previousBest: 6, shareMessage: "", theme: theme, onNewGame: {}, onSettings: {}, onStats: {})
    }
}
