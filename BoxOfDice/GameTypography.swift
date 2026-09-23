//
//  GameTypography.swift
//  BoxOfDice
//

import SwiftUI

enum GameTypography {
    static func title(size: CGFloat) -> Font {
        .custom("AmericanTypewriter-Bold", size: size, relativeTo: .largeTitle)
    }

    static func display(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .largeTitle)
    }

    static func tileNumber(size: CGFloat) -> Font {
        // SF Rounded reads cleanly as an engraved numeral on the ivory tiles —
        // even weight, generous counters, no thin serifs that muddy at small sizes.
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func button(size: CGFloat = 18) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: .headline)
    }

    static func label(size: CGFloat = 16) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: .subheadline)
    }

    static func value(size: CGFloat = 16) -> Font {
        .custom("AvenirNextCondensed-Heavy", size: size, relativeTo: .subheadline)
    }

    static func caption(size: CGFloat = 12) -> Font {
        .custom("AvenirNextCondensed-DemiBold", size: size, relativeTo: .caption)
    }

    static func section(size: CGFloat = 12) -> Font {
        .custom("AvenirNextCondensed-Heavy", size: size, relativeTo: .caption)
    }
}

/// Keep NavigationStack on iOS 16 and later. iOS 15 uses the equivalent
/// single-column NavigationView so the existing sheet content stays usable.
struct CompatibleNavigationContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @ViewBuilder var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(.stack)
        }
    }
}

extension View {
    @ViewBuilder func compatibleHiddenScrollBackground() -> some View {
        if #available(iOS 16.0, *) {
            scrollContentBackground(.hidden)
        } else {
            self
        }
    }

    @ViewBuilder func compatibleSemibold() -> some View {
        if #available(iOS 16.0, *) {
            fontWeight(.semibold)
        } else {
            font(.body.weight(.semibold))
        }
    }

    @ViewBuilder func compatibleBounceBasedOnSize() -> some View {
        if #available(iOS 16.4, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
