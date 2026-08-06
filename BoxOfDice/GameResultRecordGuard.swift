//
//  GameResultRecordGuard.swift
//  BoxOfDice
//

import Foundation

/// Ensures one finished game's stats are recorded at most once, and allows
/// recording again once a new game begins. Shared verbatim by the iOS and
/// watchOS targets — see this file's explicit membership in both targets in
/// project.pbxproj, same as GameEngine.swift.
///
/// Pulled out of ContentView/WatchContentView (R3 in
/// docs/KORJAUSTEN_TARKISTUS_2026-09-09.md) so the guarding logic itself —
/// not just GameStatisticsRecorder's idempotent-looking math — has a test
/// that fails if the guard is ever weakened or removed. `ContentView` and
/// `WatchContentView` hold one of these as `@State` instead of a raw `Bool`,
/// calling `recordIfNeeded()` where they used to check-then-set the flag,
/// and `reset()` everywhere they used to reset it to `false`.
struct GameResultRecordGuard {
    private(set) var hasRecorded = false

    /// Returns `true` (and marks recorded) the first time this is called
    /// since the last `reset()`. Returns `false` on every call after that,
    /// until `reset()` is called again for the next game.
    mutating func recordIfNeeded() -> Bool {
        guard !hasRecorded else { return false }
        hasRecorded = true
        return true
    }

    mutating func reset() {
        hasRecorded = false
    }
}
