//
//  ThemedSheetStyle.swift
//  BoxOfDice
//

import SwiftUI

struct ThemedSheetBackground: View {
    let theme: GameTheme

    var body: some View {
        LinearGradient(
            colors: theme.background,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.18), Color.black.opacity(0.26)],
                center: .top,
                startRadius: 60,
                endRadius: 620
            )
        )
        .ignoresSafeArea()
    }
}

struct ThemedListRow: ViewModifier {
    let theme: GameTheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(theme.text)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(theme.name == .minimalLight ? 0.04 : 0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .padding(.vertical, 3)
            )
    }
}

extension View {
    func themedListRow(_ theme: GameTheme) -> some View {
        modifier(ThemedListRow(theme: theme))
    }

    /// Caps this view's height to whatever space is actually available
    /// (with a small margin) and makes it scrollable internally instead —
    /// for a fixed-composition modal card (game over, Pass & Play round
    /// end/results) whose natural content height can exceed the screen on
    /// a compact-height layout like iPhone landscape. On any layout where
    /// the content already fits, this is a no-op: the card still just hugs
    /// its natural height, unchanged.
    ///
    /// Apply this to the card's *content* (before background/border/shadow
    /// are added), inside a container that's actually proposed the real
    /// available screen space (e.g. a top-level ZStack) — the cap is
    /// computed from what's proposed to this modifier itself.
    func heightCappedScrollable() -> some View {
        modifier(HeightCappedScrollable())
    }
}

private struct HeightCappedScrollable: ViewModifier {
    // Seeded with a realistic estimate so there's no visible pop on the
    // common (fits-without-scrolling) case — see `heightCappedScrollable()`.
    @State private var measuredHeight: CGFloat = 600

    private struct HeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    func body(content: Content) -> some View {
        GeometryReader { outer in
            let cappedHeight = min(measuredHeight, max(0, outer.size.height - 24))
            ScrollView(showsIndicators: false) {
                content
                    .background(
                        GeometryReader { inner in
                            Color.clear.preference(key: HeightKey.self, value: inner.size.height)
                        }
                    )
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: cappedHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(HeightKey.self) { newValue in
            guard newValue > 0 else { return }
            measuredHeight = newValue
        }
    }
}
