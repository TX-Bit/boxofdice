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
