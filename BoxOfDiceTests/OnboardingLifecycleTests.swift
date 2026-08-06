//
//  OnboardingLifecycleTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj).
//
//  Regression tests for docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §1: while
//  the first-launch tutorial is on screen, the normal `GameViewModel`
//  underneath still holds the untouched default *Classic* game. Saving that
//  (on backgrounding, or on any `revision` bump) made the next launch restore
//  a 12-tile Classic game — restore is checked before the tutorial is — so a
//  brand-new player silently lost both the tutorial and Quick Game.
//
//  Two layers, deliberately:
//   1. `OnboardingContext.allowsPersistingUnderlyingGame` — the rule itself,
//      shared verbatim by both platforms (watchOS has no simulator runtime in
//      this environment, so this is the only coverage the Watch path gets).
//   2. A hosted `ContentView` driven through active → background, which is
//      what actually proves ContentView *consults* the rule. A unit test of
//      the rule alone would still have passed with the bug present.

import SwiftUI
import XCTest
@testable import BoxOfDice

@MainActor
final class OnboardingLifecycleTests: XCTestCase {

    // Keys ContentView reads to decide new-user vs returning-user.
    private let launchDefaultsKeys = [
        "hasSelectedInitialGameMode",
        SettingsStorageKey.onboardingCompletedOrSkipped,
        SettingsStorageKey.gameMode,
        StatisticsStorageKey.gamesPlayed,
    ]

    override func setUp() {
        super.setUp()
        clearFreshInstallState()
    }

    override func tearDown() {
        clearFreshInstallState()
        super.tearDown()
    }

    /// Simulates a genuinely fresh install: no save file, and none of the
    /// prior-use signals ContentView looks at.
    private func clearFreshInstallState() {
        GameSaveStore.clear()
        for key in launchDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.set(false, forKey: "hasSelectedInitialGameMode")
        UserDefaults.standard.set(false, forKey: SettingsStorageKey.onboardingCompletedOrSkipped)
        UserDefaults.standard.set(0, forKey: StatisticsStorageKey.gamesPlayed)
    }

    // MARK: - 1. The shared rule (covers the watchOS path too)

    func testFirstLaunchContextForbidsPersistingTheGameUnderneath() {
        XCTAssertFalse(OnboardingContext.firstLaunch.allowsPersistingUnderlyingGame)
    }

    func testReplayContextAllowsPersistingTheGameUnderneath() {
        // Reopened from Settings → "How to Play": there is a real game
        // underneath that must survive both the tutorial and backgrounding.
        XCTAssertTrue(OnboardingContext.replay.allowsPersistingUnderlyingGame)
    }

    // MARK: - 2. ContentView actually applies the rule

    /// Renders the real ContentView the way a fresh install would, then moves
    /// it to the background — the exact path that used to write a Classic
    /// save. Nothing may be written.
    func testBackgroundingDuringFirstLaunchOnboardingWritesNoSave() {
        XCTAssertNil(GameSaveStore.load(), "precondition: a fresh install has no save")

        let host = hostContentView(scenePhase: .active)
        defer { teardownHost(host) }

        XCTAssertNil(
            GameSaveStore.load(),
            "showing the first-launch tutorial must not write a save by itself"
        )

        moveToBackground(host)

        guard let saved = GameSaveStore.load() else { return } // the fix holds
        XCTFail(
            """
            Backgrounding during the first-launch tutorial wrote a resumable save \
            (mode=\(saved.gameMode.rawValue), tiles=\(saved.engine.tiles.count)). \
            The next launch would restore this instead of showing the tutorial.
            """
        )
    }

    /// The mirror image: a returning player whose real game is running
    /// underneath must keep being saved, including while the tutorial is
    /// reopened from Settings. Guards against "fixing" the bug above by
    /// simply never saving while any tutorial is visible.
    func testBackgroundingWithARealGameStillWritesASave() {
        // A returning user: prior-use signal set, so ContentView starts a
        // normal game instead of the tutorial.
        UserDefaults.standard.set(true, forKey: "hasSelectedInitialGameMode")
        UserDefaults.standard.set(GameMode.quickGame.rawValue, forKey: SettingsStorageKey.gameMode)

        let host = hostContentView(scenePhase: .active)
        defer { teardownHost(host) }

        moveToBackground(host)

        let saved = GameSaveStore.load()
        XCTAssertNotNil(saved, "a returning user's in-progress game must still be saved")
        XCTAssertEqual(saved?.gameMode, .quickGame)
        XCTAssertEqual(saved?.engine.tiles.count, 9)
    }

    // MARK: - Hosting helpers

    private func hostContentView(scenePhase: ScenePhase) -> UIHostingController<AnyView> {
        let host = UIHostingController(
            rootView: AnyView(ContentView().environment(\.scenePhase, scenePhase))
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        settle()
        return host
    }

    /// Swaps in the same view with a different scenePhase so ContentView's
    /// `.onChange(of: scenePhase)` fires, then lets SwiftUI commit the pass.
    private func moveToBackground(_ host: UIHostingController<AnyView>) {
        host.rootView = AnyView(ContentView().environment(\.scenePhase, .background))
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        settle()
    }

    private func teardownHost(_ host: UIHostingController<AnyView>) {
        host.view.window?.isHidden = true
        host.view.window?.rootViewController = nil
    }

    /// SwiftUI applies state changes and runs `onAppear`/`onChange` on the
    /// main run loop, not synchronously inside `layoutIfNeeded()`.
    private func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
}
