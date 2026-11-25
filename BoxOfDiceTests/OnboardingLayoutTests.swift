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
    // Content sizes after allowing for the status bar, home indicator or active hinge.
    private static let supportedGeometries: [(name: String, size: CGSize)] = [
        ("iPhone portrait", CGSize(width: 390, height: 750)),
        ("iPhone landscape", CGSize(width: 746, height: 350)),
        ("small iPhone portrait", CGSize(width: 320, height: 520)),
        ("small iPhone landscape", CGSize(width: 568, height: 300)),
        ("iPad portrait", CGSize(width: 834, height: 1140)),
        ("iPad landscape", CGSize(width: 1194, height: 780)),
        ("iPad split view", CGSize(width: 320, height: 720)),
        ("Duo outer portrait", CGSize(width: 396, height: 655)),
        ("Duo outer landscape", CGSize(width: 618, height: 414)),
        ("Duo inner portrait", CGSize(width: 669, height: 870)),
        ("Duo inner landscape", CGSize(width: 905, height: 608)),
        ("Duo tabletop pane", CGSize(width: 669, height: 405)),
        ("Duo book pane", CGSize(width: 435, height: 608)),
    ]

    private func assertFits<Content: View>(
        _ content: Content,
        name: String,
        size: CGSize,
        attachmentName: String? = nil
    ) throws {
        let host = UIHostingController(rootView: content.ignoresSafeArea())
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        host.view.layoutIfNeeded()

        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        let scroll = try XCTUnwrap(firstScrollView(in: host.view), name)
        let inset = scroll.adjustedContentInset
        let visibleHeight = scroll.bounds.height - inset.top - inset.bottom
        XCTAssertGreaterThan(visibleHeight, 0, name)
        XCTAssertLessThanOrEqual(scroll.contentSize.height, visibleHeight + 1, "\(name) needs scrolling")

        if let attachmentName, scroll.contentSize.height > visibleHeight + 1 {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                host.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            }
            let screenshot = XCTAttachment(image: image)
            screenshot.name = attachmentName
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for subview in view.subviews {
            if let found = firstScrollView(in: subview) { return found }
        }
        return nil
    }

    func testSoloResultFitsWithTimedScoreAndRecordDetails() throws {
        let theme = GameTheme.palette(for: .greenFelt)
        for geometry in Self.supportedGeometries {
            let result = ZStack {
                LinearGradient(colors: theme.background, startPoint: .top, endPoint: .bottom)
                Color.black.opacity(0.68)
                GameOverView(
                    kind: .newBest,
                    tileScore: 171,
                    elapsedSeconds: 27,
                    isTimed: true,
                    modeName: "Big Box Speed",
                    isNewBest: true,
                    isFirstScore: false,
                    previousBest: 210,
                    shareMessage: "Share",
                    theme: theme,
                    onNewGame: {},
                    onSettings: {},
                    onStats: {}
                )
            }
            try assertFits(result, name: geometry.name, size: geometry.size, attachmentName: geometry.name)
        }
    }

    func testMultiplayerRoundAndFourPlayerResultsFit() throws {
        for geometry in Self.supportedGeometries {
            try assertFits(
                PassAndPlayRoundEndView(
                    playerNumber: 4, tileScore: 67, isLastPlayer: true, onNext: {}, onResults: {}
                ),
                name: "\(geometry.name), round end",
                size: geometry.size
            )
            try assertFits(
                PassAndPlayResultsView(scores: [14, 22, 67, 14], onNewGame: {}),
                name: "\(geometry.name), four-player results",
                size: geometry.size,
                attachmentName: geometry.name == "Duo outer landscape" ? "Duo outer landscape, multiplayer" : nil
            )
        }
    }
}
