//
//  DiceStyleTests.swift
//  BoxOfDiceTests
//
//  Covers the DiceStyle typed model (BoxOfDice/DiceStyle.swift): the single
//  source of truth for dice material numbers, shared by the live game dice
//  and the settings preview. Verifies pip/body contrast (independent of
//  which board GameTheme is active — dice styles are chosen separately, see
//  SettingsView's "Dice Style" row) and that the default (Ivory) exactly
//  matches the app's original, pre-dice-style look.
//

import SwiftUI
import XCTest
@testable import BoxOfDice

final class DiceStyleTests: XCTestCase {

    // MARK: - Contrast

    /// WCAG relative luminance of an sRGB color.
    private func relativeLuminance(_ color: Color) -> Double {
        let components = colorComponents(color)
        func linearize(_ v: Double) -> Double {
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let r = linearize(components.red)
        let g = linearize(components.green)
        let b = linearize(components.blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// WCAG contrast ratio between two colors (always >= 1).
    private func contrastRatio(_ a: Color, _ b: Color) -> Double {
        let l1 = relativeLuminance(a)
        let l2 = relativeLuminance(b)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Every style's pips must read clearly against its own die body — this
    /// is independent of the board theme behind the die (a dice style is
    /// chosen separately from the board theme), so a plain pip-vs-body
    /// check covers "legible pips on every current board theme" by
    /// construction.
    func testEveryStyleHasStrongPipToBodyContrast() {
        for name in DiceStyleName.allCases {
            let style = DiceStyle.palette(for: name)
            let ratio = contrastRatio(style.bodyColor, style.pipColor)
            XCTAssertGreaterThanOrEqual(
                ratio, 4.5,
                "\(name.rawValue): pip/body contrast ratio \(ratio) must meet at least WCAG AA text contrast (4.5:1)"
            )
        }
    }

    // MARK: - Distinctness

    func testAllFourStylesAreVisuallyDistinct() {
        let styles = DiceStyleName.allCases.map(DiceStyle.palette(for:))
        for i in styles.indices {
            for j in styles.indices where j > i {
                XCTAssertNotEqual(styles[i].bodyColor, styles[j].bodyColor,
                                   "\(styles[i].name) and \(styles[j].name) must not share a body color")
            }
        }
    }

    func testStyleCountMatchesFourRequiredStyles() {
        XCTAssertEqual(Set(DiceStyleName.allCases), [.ivory, .cherry, .midnightBlue, .graphite])
    }

    // MARK: - Default matches the original look

    /// Ivory (the default) must reproduce the app's original hardcoded dice
    /// material exactly, so switching in dice styles doesn't change any
    /// existing user's dice unless they explicitly pick a different style.
    func testIvoryMatchesOriginalHardcodedMaterial() {
        let style = DiceStyle.palette(for: .ivory)
        assertColorEqual(style.bodyColor, red: 245.0 / 255.0, green: 242.0 / 255.0, blue: 230.0 / 255.0)
        assertColorEqual(style.pipColor, red: 0.055, green: 0.055, blue: 0.052)
        XCTAssertEqual(style.roughness, 0.32, accuracy: 0.0001)
        XCTAssertEqual(style.clearCoat, 0.06, accuracy: 0.0001)
        XCTAssertEqual(style.clearCoatRoughness, 0.58, accuracy: 0.0001)
    }

    func testDefaultStorageValueIsIvory() {
        XCTAssertEqual(DiceStyleName.ivory.rawValue, "ivory")
    }

    private func assertColorEqual(_ color: Color, red: Double, green: Double, blue: Double,
                                   accuracy: Double = 0.001, file: StaticString = #filePath, line: UInt = #line) {
        let components = colorComponents(color)
        XCTAssertEqual(components.red, red, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(components.green, green, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(components.blue, blue, accuracy: accuracy, file: file, line: line)
    }

    private func colorComponents(_ color: Color) -> (red: Double, green: Double, blue: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return (Double(red), Double(green), Double(blue))
    }
}
