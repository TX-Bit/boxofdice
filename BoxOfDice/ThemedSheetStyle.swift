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
}
