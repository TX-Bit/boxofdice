//
//  OnboardingLayoutTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj).
//
//  docs/UUDISTUSTEN_TARKISTUS_2026-09-10.md §5 flagged the tutorial's layout
//  as a landscape risk: a fixed vertical column, fixed tile sizes, no
//  scrolling. It was: laid out at its natural size the column needed ~547pt,
//  against 390pt on a landscape iPhone and 375pt on the smallest supported
//  screen — so "Roll" and "Skip" sat below the bottom edge with no way to
//  reach them. The welcome choice and practice turn must both keep their
//  actions reachable without routine scrolling on supported devices.
//
//  These tests measure the hosted view instead of eyeballing a screenshot,
//  so every supported geometry is covered on every run — including the ones
//  this environment has no simulator for.

import SwiftUI
import XCTest
@testable import BoxOfDice

@MainActor
final class OnboardingLayoutTests: XCTestCase {

    /// Width × height of each geometry the tutorial has to work in.
    private static let supportedGeometries: [(name: String, size: CGSize)] = [
        ("iPhone portrait",        CGSize(width: 390, height: 844)),
        ("iPhone landscape",       CGSize(width: 844, height: 390)),
        ("smallest phone portrait", CGSize(width: 375, height: 667)),
        ("smallest phone landscape", CGSize(width: 667, height: 375)),
        ("iPad portrait",          CGSize(width: 834, height: 1194)),
        ("iPad landscape",         CGSize(width: 1194, height: 834)),
        ("iPad split view",        CGSize(width: 320, height: 1024)),
    ]

    /// Lays the tutorial out at `size` in a real window and returns its
    /// scroll view's bounds and content height.
    ///
    /// Measuring the scroll view's *content* is the whole point: asking the
    /// hosting controller for `sizeThatFits` reports the scroll view's own
    /// (already bounded) height, so it says "fits" no matter how far the
    /// content overflows — a test built on it passes while the buttons sit
    /// off-screen. Only `contentSize` vs `bounds` tells the truth.
    private func measureScrollGeometry(
        size: CGSize,
        isReplay: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (bounds: CGFloat, content: CGFloat)? {
        // `.ignoresSafeArea()` mirrors how ContentView presents the tutorial.
        // Without it, UIKit gives the hosted scroll view a phantom ~54pt top
        // content inset in this synthetic window, and the measurement
        // describes the test harness rather than the app.
        let host = UIHostingController(
            rootView: OnboardingView(
                theme: GameTheme.palette(for: .greenFelt),
                isReplay: isReplay,
                onFinish: {}
            )
            .ignoresSafeArea()
        )
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = CGRect(origin: .zero, size: size)
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        host.view.layoutIfNeeded()

        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        guard let scrollView = firstScrollView(in: host.view) else {
            XCTFail(
                "the tutorial must stay inside a scroll view so its actions can always be reached",
                file: file, line: line
            )
            return nil
        }
        let inset = scrollView.adjustedContentInset
        return (scrollView.bounds.height - inset.top - inset.bottom, scrollView.contentSize.height)
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews {
            if let found = firstScrollView(in: subview) { return found }
        }
        return nil
    }

    /// Every supported geometry must show the whole tutorial without
    /// scrolling. Scrolling is the safety net for cases this list doesn't
    /// predict (huge Dynamic Type, a future device); it is not meant to be
    /// the normal experience, and on the first screen a new player ever sees,
    /// an action below the fold is an action they may never find.
    func testWelcomeAndTutorialFitEverySupportedGeometryWithoutScrolling() {
        for geometry in Self.supportedGeometries {
            for isReplay in [false, true] {
                guard let measured = measureScrollGeometry(size: geometry.size, isReplay: isReplay) else { continue }
                XCTAssertLessThanOrEqual(
                    measured.content, measured.bounds + 0.5,
                    "\(geometry.name), \(isReplay ? "tutorial" : "welcome"): content \(measured.content)pt exceeds viewport \(measured.bounds)pt"
                )
            }
        }
    }

    /// The safety net itself: whatever the geometry, the content is inside a
    /// scroll view, so nothing can ever become permanently unreachable.
    func testTutorialIsAlwaysScrollable() {
        XCTAssertNotNil(measureScrollGeometry(size: CGSize(width: 320, height: 320)))
    }
}

@MainActor
final class GameOverLayoutTests: XCTestCase {

    private static let supportedGeometries: [(name: String, size: CGSize)] = [
        ("iPhone portrait",         CGSize(width: 390, height: 844)),
        ("iPhone landscape",        CGSize(width: 844, height: 390)),
        ("smallest phone portrait",  CGSize(width: 375, height: 667)),
        ("smallest phone landscape", CGSize(width: 667, height: 375)),
        ("iPad portrait",           CGSize(width: 834, height: 1194)),
        ("iPad landscape",          CGSize(width: 1194, height: 834)),
        ("iPad split view",         CGSize(width: 320, height: 1024)),
    ]

    private func measureGameOverGeometry(size: CGSize) -> (bounds: CGFloat, content: CGFloat)? {
        let host = UIHostingController(
            rootView: GameOverView(
                kind: .gameOver,
                tileScore: 12,
                elapsedSeconds: 0,
                isTimed: false,
                remainingOpenTiles: [1, 2, 4, 5],
                modeName: "Classic",
                isNewBest: true,
                isFirstScore: false,
                previousBest: 20,
                shareMessage: "Share",
                theme: GameTheme.palette(for: .greenFelt),
                onNewGame: {},
                onSettings: {},
                onStats: {}
            )
            .ignoresSafeArea()
        )
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = CGRect(origin: .zero, size: size)
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        host.view.layoutIfNeeded()

        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        guard let scrollView = firstScrollView(in: host.view) else { return nil }
        let inset = scrollView.adjustedContentInset
        return (scrollView.bounds.height - inset.top - inset.bottom, scrollView.contentSize.height)
    }

    private func measurePassAndPlayResultsGeometry(size: CGSize) -> (bounds: CGFloat, content: CGFloat)? {
        let host = UIHostingController(
            rootView: PassAndPlayResultsView(
                scores: [14, 22],
                onNewGame: {}
            )
            .ignoresSafeArea()
        )
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = CGRect(origin: .zero, size: size)
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        host.view.layoutIfNeeded()

        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        guard let scrollView = firstScrollView(in: host.view) else { return nil }
        let inset = scrollView.adjustedContentInset
        return (scrollView.bounds.height - inset.top - inset.bottom, scrollView.contentSize.height)
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews {
            if let found = firstScrollView(in: subview) { return found }
        }
        return nil
    }

    func testGameOverViewIsAlwaysScrollableInEveryGeometry() {
        for geometry in Self.supportedGeometries {
            let measured = measureGameOverGeometry(size: geometry.size)
            XCTAssertNotNil(
                measured,
                "\(geometry.name): GameOverView must be wrapped in a scroll view so its actions are never clipped or unreachable"
            )
        }
    }

    func testPassAndPlayResultsViewIsAlwaysScrollableInEveryGeometry() {
        for geometry in Self.supportedGeometries {
            let measured = measurePassAndPlayResultsGeometry(size: geometry.size)
            XCTAssertNotNil(
                measured,
                "\(geometry.name): PassAndPlayResultsView must be wrapped in a scroll view so results and actions are never clipped"
            )
        }
    }
}
