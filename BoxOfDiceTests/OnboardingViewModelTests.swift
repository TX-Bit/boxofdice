//
//  OnboardingViewModelTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj).
//
//  BOD-012: the first-launch tutorial's state machine. `OnboardingViewModel`
//  is shared verbatim with the watchOS target (see GameEngine.swift's
//  explicit membership in project.pbxproj for the pattern); these tests
//  import the iOS module, so they cover the shared source, not a watchOS
//  target run of it (no watchOS simulator runtime in this environment — see
//  the BOD-006/BOD-011 entries in docs/KORJAUSSEURANTA.md for the same
//  limitation).

import XCTest
@testable import BoxOfDice

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    func testStartsWithNineOpenTilesAndNoRoll() {
        let model = OnboardingViewModel()
        XCTAssertEqual(model.tiles.map(\.id), Array(1...9))
        XCTAssertTrue(model.tiles.allSatisfy(\.isOpen))
        XCTAssertEqual(model.step, .waitingForRoll)
        XCTAssertFalse(model.hasRolled)
    }

    func testRollIsAlwaysTheFixedThreeAndFive() {
        for _ in 0..<5 {
            let model = OnboardingViewModel()
            model.rollTutorialDice()
            XCTAssertEqual(model.dice, [3, 5, 0])
            XCTAssertEqual(model.diceTotal, 8)
            XCTAssertEqual(model.step, .selecting)
        }
    }

    func testRollingTwiceDoesNothingTheSecondTime() {
        let model = OnboardingViewModel()
        model.rollTutorialDice()
        model.toggleTile(8) // move into a partial selection
        model.rollTutorialDice() // must not reset the in-progress selection
        XCTAssertEqual(model.selectedTiles, [8])
        XCTAssertEqual(model.step, .selecting)
    }

    // MARK: - Accepting any valid sum-8 combination, not just the example

    func testAcceptsTheSingleTileExample() {
        let model = OnboardingViewModel()
        model.rollTutorialDice()
        model.toggleTile(8)
        XCTAssertTrue(model.canConfirm)
        model.confirm()
        XCTAssertEqual(model.step, .resolved)
        XCTAssertFalse(model.tiles.first(where: { $0.id == 8 })!.isOpen)
    }

    func testAcceptsTheThreePlusFiveExample() {
        let model = OnboardingViewModel()
        model.rollTutorialDice()
        model.toggleTile(3)
        model.toggleTile(5)
        XCTAssertTrue(model.canConfirm)
        model.confirm()
        XCTAssertEqual(model.step, .resolved)
        XCTAssertFalse(model.tiles.first(where: { $0.id == 3 })!.isOpen)
        XCTAssertFalse(model.tiles.first(where: { $0.id == 5 })!.isOpen)
    }

    func testAcceptsAThirdCombinationNotShownInThePrompt() {
        let model = OnboardingViewModel()
        model.rollTutorialDice()
        model.toggleTile(1)
        model.toggleTile(2)
        model.toggleTile(5) // 1+2+5 = 8, never mentioned in the prompt text
        XCTAssertTrue(model.canConfirm)
        model.confirm()
        XCTAssertEqual(model.step, .resolved)
        for id in [1, 2, 5] {
            XCTAssertFalse(model.tiles.first(where: { $0.id == id })!.isOpen)
        }
        // Tiles not part of the chosen combination stay open.
        for id in [3, 4, 6, 7, 8, 9] {
            XCTAssertTrue(model.tiles.first(where: { $0.id == id })!.isOpen)
        }
    }

    // MARK: - Rejecting a wrong sum without punishing/locking the player

    func testWrongSumCannotBeConfirmedButSelectionStaysEditable() {
        let model = OnboardingViewModel()
        model.rollTutorialDice()
        model.toggleTile(4) // sum 4, not 8
        XCTAssertFalse(model.canConfirm)

        model.confirm() // must be a no-op: canConfirm is false
        XCTAssertEqual(model.step, .selecting, "an invalid attempt must not lock or advance the tutorial")
        XCTAssertTrue(model.tiles.first(where: { $0.id == 4 })!.isOpen, "must not close anything on a rejected confirm")

        // The player can keep adjusting the selection afterwards.
        model.toggleTile(4)
        model.toggleTile(8)
        XCTAssertTrue(model.canConfirm)
    }

    func testTogglingAnAlreadyClosedTileIsIgnored() {
        let model = OnboardingViewModel()
        model.rollTutorialDice()
        model.toggleTile(8)
        model.confirm()
        model.toggleTile(8) // already closed; must be ignored, and step is .resolved anyway
        XCTAssertTrue(model.selectedTiles.isEmpty)
    }
}
