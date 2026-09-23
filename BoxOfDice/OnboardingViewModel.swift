//
//  OnboardingViewModel.swift
//  BoxOfDice
//

import Combine
import Foundation

/// Which situation the tutorial is on screen for. Shared by both platforms
/// (it used to be duplicated as a nested enum in ContentView and
/// WatchContentView; the save rule below has to be identical on both, so it
/// lives with the rule).
enum OnboardingContext {
    /// A brand-new install. Each platform starts its own default game
    /// after the tutorial is completed or skipped.
    case firstLaunch
    /// Reopened from Settings → "How to Play"; the game underneath is
    /// untouched and finishing just dismisses back to it.
    case replay

    /// Whether the normal game running underneath the tutorial may be written
    /// to the resumable-save file while the tutorial is on screen.
    ///
    /// `.firstLaunch` must not: the view model underneath still holds the
    /// untouched default Classic game that the player has never seen. Saving
    /// it (on backgrounding, or on any `revision` bump) makes the *next*
    /// launch restore that Classic game — and restore is checked before the
    /// tutorial is, deliberately, so a real interrupted game always wins — so
    /// a brand-new player would silently land in a 12-tile Classic game they
    /// never chose and never see the tutorial again.
    ///
    /// `.replay` must: there is a real game underneath that the player was in
    /// the middle of, and it has to survive the tutorial being opened from
    /// Settings and the app being backgrounded while it is open.
    var allowsPersistingUnderlyingGame: Bool {
        switch self {
        case .firstLaunch: return false
        case .replay:      return true
        }
    }
}

/// A tiny, self-contained state machine for the first-launch tutorial
/// (BOD-012) — a fixed practice roll on a configurable board (12 tiles on
/// iOS, 9 on Watch). Deliberately NOT
/// built on `GameEngine`/`GameViewModel`: it never rolls real random dice,
/// never records statistics, never persists a save, and never schedules an
/// auto-roll, so none of that logic needs a special "am I in the tutorial"
/// branch. `ContentView`/`WatchContentView` only ask it three questions
/// (state, dice, tiles) and call three actions (roll, toggle, confirm) —
/// nothing about the normal game needs to know this exists.
///
/// Shared verbatim by the iOS and watchOS targets (only depends on `Tile`
/// from GameEngine.swift, Combine and Foundation) — see this file's
/// explicit membership in both targets in project.pbxproj, same as
/// GameEngine.swift. The two platforms each have their own SwiftUI view for
/// it (OnboardingView.swift / WatchOnboardingView.swift).
@MainActor
final class OnboardingViewModel: ObservableObject {

    enum Step: Equatable {
        case waitingForRoll
        case selecting
        case resolved
    }

    /// The fixed practice roll: 3 + 5 = 8. Never random — the tutorial's
    /// point is a known, explainable target, and this must never affect or
    /// be confused with a real game's randomness.
    static let tutorialDice = [3, 5, 0]
    static let tutorialTarget = 8

    @Published private(set) var step: Step = .waitingForRoll
    @Published private(set) var tiles: [Tile]
    @Published private(set) var selectedTiles: Set<Int> = []
    @Published private(set) var dice: [Int] = [0, 0, 0]

    init(tileCount: Int = 9) {
        tiles = (1...tileCount).map { Tile(id: $0) }
    }

    var diceTotal: Int { dice.reduce(0, +) }
    var selectionTotal: Int { selectedTiles.reduce(0, +) }
    var canConfirm: Bool { !selectedTiles.isEmpty && selectionTotal == diceTotal }
    var hasRolled: Bool { step != .waitingForRoll }

    func rollTutorialDice() {
        guard step == .waitingForRoll else { return }
        dice = Self.tutorialDice
        step = .selecting
    }

    func toggleTile(_ id: Int) {
        guard step == .selecting, tiles.first(where: { $0.id == id })?.isOpen == true else { return }
        if selectedTiles.contains(id) {
            selectedTiles.remove(id)
        } else {
            selectedTiles.insert(id)
        }
    }

    /// Closes the selected tiles. Any rule-valid sum-8 combination is
    /// accepted — not just the two examples shown in the prompt — since
    /// both Classic and Quick Game permit any combination matching the dice.
    func confirm() {
        guard canConfirm else { return }
        for index in tiles.indices where selectedTiles.contains(tiles[index].id) {
            tiles[index].isOpen = false
        }
        selectedTiles = []
        step = .resolved
    }
}
