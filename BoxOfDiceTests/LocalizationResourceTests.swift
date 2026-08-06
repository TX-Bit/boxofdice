//
//  LocalizationResourceTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj).
//
//  BOD-013: a lightweight, runnable check over every .lproj resource in the
//  repository — reads the .strings files directly from disk (via #filePath,
//  not through Bundle) so it does not depend on the test host loading a
//  particular bundle. It checks key sets and format-placeholder shape only;
//  it does NOT check that every SwiftUI view actually calls L10n for its
//  visible text — that must still be verified by reading the views (see
//  docs/LOKALISOINTI.md's "known gaps" section).
//
//  English has no en.lproj (development-language keys ARE the English text,
//  per GameSettings.swift's `L10n.string`), so English is represented here
//  by the KEY SET of the base fi.lproj file (every key that exists must have
//  an English form — the key itself — and a Finnish translation).

import XCTest
@testable import BoxOfDice

final class LocalizationResourceTests: XCTestCase {

    private struct ParsedFile {
        let path: String
        let entries: [(key: String, value: String)]
        var keys: [String] { entries.map(\.key) }
    }

    private func repoRoot() -> URL {
        // BoxOfDiceTests/LocalizationResourceTests.swift -> BoxOfDice/ (repo root, contains BoxOfDice/ and WatchApp/)
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func parseStringsFile(_ url: URL) throws -> ParsedFile {
        let content = try String(contentsOf: url, encoding: .utf8)
        let pattern = #"^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let range = NSRange(content.startIndex..., in: content)
        var entries: [(String, String)] = []
        regex.enumerateMatches(in: content, range: range) { match, _, _ in
            guard let match, let keyRange = Range(match.range(at: 1), in: content),
                  let valueRange = Range(match.range(at: 2), in: content) else { return }
            entries.append((String(content[keyRange]), String(content[valueRange])))
        }
        return ParsedFile(path: url.path, entries: entries)
    }

    private func placeholders(in value: String) -> [String] {
        let pattern = #"%(lld|ld|d|@|f|s)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(value.startIndex..., in: value)
        return regex.matches(in: value, range: range).compactMap { match in
            Range(match.range, in: value).map { String(value[$0]) }
        }
    }

    private func lprojFiles(under groupDir: URL) -> [(lang: String, url: URL)] {
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: groupDir, includingPropertiesForKeys: nil
        ) else { return [] }
        return children
            .filter { $0.lastPathComponent.hasSuffix(".lproj") }
            .compactMap { dir in
                let file = dir.appendingPathComponent("Localizable.strings")
                guard FileManager.default.fileExists(atPath: file.path) else { return nil }
                let lang = dir.lastPathComponent.replacingOccurrences(of: ".lproj", with: "")
                return (lang, file)
            }
    }

    private func checkGroup(name: String, dir: URL) throws {
        let files = lprojFiles(under: dir)
        XCTAssertFalse(files.isEmpty, "\(name): expected at least one .lproj/Localizable.strings")

        var parsedByLang: [String: ParsedFile] = [:]
        for (lang, url) in files {
            parsedByLang[lang] = try parseStringsFile(url)
        }

        // No duplicate keys within any single file.
        for (lang, parsed) in parsedByLang {
            var seen = Set<String>()
            var dupes = Set<String>()
            for key in parsed.keys {
                if !seen.insert(key).inserted { dupes.insert(key) }
            }
            XCTAssertTrue(dupes.isEmpty, "\(name)/\(lang): duplicate keys \(dupes)")
        }

        // English development-language key set: the base fi.lproj's keys
        // (English text = the key itself; there is no en.lproj on disk).
        guard let baseline = parsedByLang["fi"] else {
            XCTFail("\(name): missing fi.lproj baseline")
            return
        }
        let baselineKeySet = Set(baseline.keys)

        for (lang, parsed) in parsedByLang where lang != "fi" {
            let keySet = Set(parsed.keys)
            let missing = baselineKeySet.subtracting(keySet)
            let extra = keySet.subtracting(baselineKeySet)
            XCTAssertTrue(missing.isEmpty, "\(name)/\(lang): missing keys present in fi baseline: \(missing)")
            XCTAssertTrue(extra.isEmpty, "\(name)/\(lang): keys not present in fi baseline (stale/typo?): \(extra)")
        }

        // Format placeholders: same type sequence across every language for a shared key.
        var placeholdersByKeyAndLang: [String: [String: [String]]] = [:]
        for (lang, parsed) in parsedByLang {
            for (key, value) in parsed.entries {
                placeholdersByKeyAndLang[key, default: [:]][lang] = placeholders(in: value)
            }
        }
        for (key, byLang) in placeholdersByKeyAndLang {
            guard let reference = byLang["fi"] else { continue }
            for (lang, ph) in byLang where lang != "fi" {
                XCTAssertEqual(
                    ph, reference,
                    "\(name)/\(lang): key \"\(key)\" has placeholders \(ph), expected \(reference) (fi)"
                )
            }
        }
    }

    func testIOSLocalizationResourcesAreComplete() throws {
        try checkGroup(name: "BoxOfDice (iOS)", dir: repoRoot().appendingPathComponent("BoxOfDice"))
    }

    func testWatchLocalizationResourcesAreComplete() throws {
        try checkGroup(name: "WatchApp", dir: repoRoot().appendingPathComponent("WatchApp"))
    }

    // MARK: - Keys the UI actually asks for

    // docs/KIELITARKISTUS_2026-09-10.md: `TileView.swift` asked for
    // "Tile %lld" / "Closed tile %lld", which are translated nowhere, so
    // VoiceOver read every tile in English in all six non-English languages.
    // The resource tests above all passed, because the .strings files were
    // perfectly consistent with each other — they just didn't contain the
    // keys the code wanted. These two tests close that gap from the other
    // side: every key the source asks for must exist in the baseline.

    /// Source strings that are deliberately not localized: pure symbols,
    /// bare numbers, and debug-only affordances.
    private static let unlocalizedLiteralAllowList: Set<String> = [
        "Preview celebrations", // CelebrationDebug.swift, never shipped in a release build
    ]

    /// Scans `text` for Swift string literals and returns each one already
    /// normalized to the key SwiftUI would look up — an interpolation becomes
    /// `%lld` (`"Die showing \(value)"` → `"Die showing %lld"`).
    ///
    /// Extraction and normalization are one pass on purpose: an interpolation
    /// can itself contain string literals and parentheses
    /// (`"Last: closed \(tiles.joined(separator: ", "))"`), which a plain
    /// regex would mistake for the end of the outer literal.
    private func localizationKeys(inSwiftExpression text: String) -> [String] {
        var keys: [String] = []
        var index = text.startIndex

        while index < text.endIndex {
            guard text[index] == "\"" else {
                index = text.index(after: index)
                continue
            }
            index = text.index(after: index) // past the opening quote

            var key = ""
            var isClosed = false
            while index < text.endIndex {
                let character = text[index]

                if character == "\\" {
                    let next = text.index(after: index)
                    guard next < text.endIndex else { break }
                    if text[next] == "(" {
                        index = skipInterpolation(in: text, from: text.index(after: next))
                        key += "%lld"
                        continue
                    }
                    key.append(character)
                    key.append(text[next])
                    index = text.index(after: next)
                    continue
                }

                if character == "\"" {
                    isClosed = true
                    index = text.index(after: index)
                    break
                }

                key.append(character)
                index = text.index(after: index)
            }

            if isClosed { keys.append(key) }
        }
        return keys
    }

    /// Returns the index just past the `)` that closes an interpolation
    /// opened before `start`, ignoring parens inside nested string literals.
    private func skipInterpolation(in text: String, from start: String.Index) -> String.Index {
        var index = start
        var depth = 1
        var insideString = false
        while index < text.endIndex, depth > 0 {
            let character = text[index]
            if insideString {
                if character == "\\" {
                    index = text.index(index, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
                    continue
                }
                if character == "\"" { insideString = false }
            } else {
                switch character {
                case "\"": insideString = true
                case "(":  depth += 1
                case ")":  depth -= 1
                default:   break
                }
            }
            index = text.index(after: index)
        }
        return index
    }

    /// True when the key contains translatable words — i.e. letters that are
    /// not just part of a format specifier. Skips "%lld", "%lld×", "·", "+".
    private func carriesTranslatableText(_ key: String) -> Bool {
        var stripped = key
        for specifier in ["%lld", "%ld", "%d", "%@", "%f", "%s"] {
            stripped = stripped.replacingOccurrences(of: specifier, with: "")
        }
        return stripped.contains(where: \.isLetter)
    }

    private func swiftSources(in directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "swift" } ?? []
    }

    /// Every key passed explicitly to `L10n.string` / `L10n.format`.
    private func explicitL10nKeys(in source: String) -> [String] {
        matches(of: #"L10n\.(?:string|format)\(\s*"((?:[^"\\]|\\.)*)""#, in: source)
    }

    /// Every string literal appearing anywhere inside a `Text(...)` or
    /// `.accessibilityLabel(...)` call — SwiftUI treats those as
    /// `LocalizedStringKey`, so they are looked up in the .strings table
    /// exactly like an `L10n` call.
    ///
    /// Scans the whole balanced argument list, not just its first token: the
    /// bug this guards against was written as a ternary
    /// (`.accessibilityLabel(isOpen ? "Tile \(n)" : "Closed tile \(n)")`),
    /// so a pattern anchored to "literal right after the paren" sees nothing.
    private func localizedStringKeyLiterals(in source: String) -> [String] {
        var found: [String] = []
        for call in ["Text(", ".accessibilityLabel("] {
            var searchStart = source.startIndex
            while let callRange = source.range(of: call, range: searchStart..<source.endIndex) {
                searchStart = callRange.upperBound
                guard let arguments = balancedArgumentText(in: source, openParenAfter: callRange.upperBound)
                else { continue }
                found.append(contentsOf: localizationKeys(inSwiftExpression: arguments))
            }
        }
        return found
    }

    /// Text between `start` and the paren that closes the call, respecting
    /// nesting and skipping over parens/escapes inside string literals.
    private func balancedArgumentText(in source: String, openParenAfter start: String.Index) -> String? {
        var depth = 1
        var index = start
        var insideString = false
        while index < source.endIndex {
            let character = source[index]
            if insideString {
                if character == "\\" {
                    index = source.index(index, offsetBy: 2, limitedBy: source.endIndex) ?? source.endIndex
                    continue
                }
                if character == "\"" { insideString = false }
            } else {
                switch character {
                case "\"": insideString = true
                case "(":  depth += 1
                case ")":
                    depth -= 1
                    if depth == 0 { return String(source[start..<index]) }
                case "\n":
                    // A call that never closes on this statement is almost
                    // certainly a mis-parse; give up rather than run away.
                    if depth > 4 { return nil }
                default: break
                }
            }
            index = source.index(after: index)
        }
        return nil
    }

    private func matches(of pattern: String, in source: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            Range(match.range(at: 1), in: source).map { String(source[$0]) }
        }
    }

    private func assertRequestedKeysExist(
        sourceDirectory: String,
        baseline baselineLproj: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let root = repoRoot()
        let baseline = try parseStringsFile(
            root.appendingPathComponent("\(baselineLproj)/fi.lproj/Localizable.strings")
        )
        let known = Set(baseline.keys)

        var missing: [String] = []
        for source in swiftSources(in: root.appendingPathComponent(sourceDirectory)) {
            guard let text = try? String(contentsOf: source, encoding: .utf8) else { continue }
            let requested = explicitL10nKeys(in: text) + localizedStringKeyLiterals(in: text)
            for key in requested {
                if Self.unlocalizedLiteralAllowList.contains(key) { continue }
                guard carriesTranslatableText(key) else { continue }
                // An interpolation is normalized to %lld above, but SwiftUI
                // emits %@ for a String and some call sites spell the integer
                // form %d — accept any of the three for the same slot.
                let alternatives = [
                    key,
                    key.replacingOccurrences(of: "%lld", with: "%d"),
                    key.replacingOccurrences(of: "%lld", with: "%@"),
                ]
                guard !alternatives.contains(where: known.contains) else { continue }
                missing.append("\(source.lastPathComponent): \"\(key)\"")
            }
        }

        XCTAssertTrue(
            missing.isEmpty,
            """
            \(sourceDirectory): the UI asks for keys that no .strings file defines, \
            so these read in English in every other language:
            \(missing.sorted().joined(separator: "\n"))
            """,
            file: file, line: line
        )
    }

    func testEveryLocalizationKeyTheIOSUIAsksForExists() throws {
        try assertRequestedKeysExist(sourceDirectory: "BoxOfDice", baseline: "BoxOfDice")
    }

    func testEveryLocalizationKeyTheWatchUIAsksForExists() throws {
        try assertRequestedKeysExist(sourceDirectory: "WatchApp", baseline: "WatchApp")
    }

    /// All seven languages named in docs/CLAUDE_UUDET_OMINAISUUDET.md /
    /// docs/LOKALISOINTI.md are actually present as resources (guards
    /// against a language being "documented" but never added on disk).
    func testAllSevenLanguagesArePresentOnBothPlatforms() {
        let expected: Set<String> = ["fi", "de", "fr", "es", "it", "pt-BR"] // + en (no en.lproj by design)
        for group in ["BoxOfDice", "WatchApp"] {
            let dir = repoRoot().appendingPathComponent(group)
            let present = Set(lprojFiles(under: dir).map(\.lang))
            XCTAssertEqual(present, expected, "\(group): lproj languages present \(present), expected \(expected)")
        }
    }
}
