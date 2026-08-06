//
//  WatchLayoutBudgetTests.swift
//  BoxOfDice Watch App Tests
//
//  WatchGameplayLayoutMetrics.boardHeight(columns:rows:) must never claim
//  more vertical space than is actually available after the header, dice
//  row, primary button, and (when present) utility row — on the smallest
//  supported watch, forcing a taller board than fits pushed content off
//  screen. See WatchContentView.swift's `body` for how `showsUtilityRow`
//  must match whether that row is actually included in the VStack.
//

import XCTest
@testable import BoxOfDice_Watch_App

final class WatchLayoutBudgetTests: XCTestCase {

    /// Smallest supported watch size class (38mm-era) up to the largest
    /// (Ultra), both tile-grid shapes (3x3 for Quick Game, 4x3 for the
    /// other modes), and both utility-row states.
    private let sizes: [CGSize] = [
        CGSize(width: 136, height: 170), // smallest
        CGSize(width: 162, height: 197),
        CGSize(width: 198, height: 242), // largest (Ultra)
    ]

    func testBoardHeightNeverExceedsSpaceLeftAfterEveryOtherRow() {
        for size in sizes {
            for showsUtility in [true, false] {
                let metrics = WatchGameplayLayoutMetrics(size: size, showsUtilityRow: showsUtility)
                for (columns, rows) in [(3, 3), (4, 3)] {
                    let utility = showsUtility ? (metrics.utilityHeight + metrics.verticalSpacing) : 0
                    let spacingRows: CGFloat = showsUtility ? 3 : 2
                    let reserved = metrics.topPadding + metrics.bottomPadding + metrics.headerHeight
                                 + metrics.diceRowHeight + metrics.primaryHeight
                                 + utility + metrics.verticalSpacing * spacingRows
                    let available = max(1, size.height - reserved)

                    let boardHeight = metrics.boardHeight(columns: columns, rows: rows)

                    XCTAssertLessThanOrEqual(
                        boardHeight, available,
                        "columns=\(columns) rows=\(rows) size=\(size) utility=\(showsUtility): "
                        + "board (\(boardHeight)) must never exceed the space actually left (\(available))"
                    )
                    XCTAssertGreaterThan(boardHeight, 0)
                }
            }
        }
    }

    /// The full reserved stack (header + board + dice row + primary button
    /// + utility row, with the VStack's own inter-row spacing) must fit
    /// within the screen height on every supported size — the concrete,
    /// end-to-end version of the same budget check.
    func testFullVerticalStackFitsOnScreen() {
        for size in sizes {
            for showsUtility in [true, false] {
                let metrics = WatchGameplayLayoutMetrics(size: size, showsUtilityRow: showsUtility)
                for (columns, rows) in [(3, 3), (4, 3)] {
                    let boardHeight = metrics.boardHeight(columns: columns, rows: rows)
                    let rowsShown: CGFloat = showsUtility ? 5 : 4 // header, board, dice, primary, (utility)
                    let totalContentHeight = metrics.headerHeight + boardHeight + metrics.diceRowHeight
                        + metrics.primaryHeight + (showsUtility ? metrics.utilityHeight : 0)
                        + metrics.verticalSpacing * (rowsShown - 1)
                        + metrics.topPadding + metrics.bottomPadding

                    XCTAssertLessThanOrEqual(
                        totalContentHeight, size.height + 0.01,
                        "columns=\(columns) rows=\(rows) size=\(size) utility=\(showsUtility): "
                        + "full stack (\(totalContentHeight)) must fit within the screen (\(size.height))"
                    )
                }
            }
        }
    }
}
