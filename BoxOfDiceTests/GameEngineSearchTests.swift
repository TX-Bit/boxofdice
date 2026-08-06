//
//  GameEngineSearchTests.swift
//  BoxOfDiceTests
//
//  Wired into the BoxOfDiceTests target (see project.pbxproj / R1 in
//  docs/KORJAUSTEN_TARKISTUS_2026-09-09.md).
//
//  BOD-004: GameEngine.allowedCombinations replaced the full bitmask scan of
//  every one of the 2^n subsets of open tiles with a pruned depth-first
//  search. These tests check the new search against a brute-force reference
//  (the original algorithm, kept here only for comparison) across many
//  boards, open-tile subsets, dice sums, and both move rules, and report —
//  without gating on a fragile wall-clock threshold — the measured speed-up
//  on a full 18-tile board.

import XCTest
@testable import BoxOfDice

final class GameEngineSearchTests: XCTestCase {

    /// The original, unoptimized algorithm (full bitmask scan of every
    /// non-empty subset), reimplemented standalone here purely as a
    /// brute-force correctness reference — not used by the app anymore.
    private func bruteForceMoves(_ numbers: [Int], target: Int, moveRule: MoveRule) -> [[Int]] {
        guard target > 0 else { return [] }
        let n = numbers.count
        var matches: [[Int]] = []
        for mask in 1..<(1 << n) {
            var subset: [Int] = []
            var sum = 0
            for i in 0..<n where mask & (1 << i) != 0 {
                sum += numbers[i]
                subset.append(numbers[i])
            }
            let allowed: Bool
            switch moveRule {
            case .anyCombination: allowed = true
            case .oneOrTwoTiles: allowed = subset.count <= 2
            }
            if sum == target && allowed {
                matches.append(subset)
            }
        }
        return matches
    }

    private func normalized(_ moves: [[Int]]) -> Set<[Int]> {
        Set(moves.map { $0.sorted() })
    }

    private func searchEngine(moveRule: MoveRule) -> GameEngine {
        // tileCount/baseDiceCount/diceMode are irrelevant here: allowedCombinations
        // takes the tile list and target explicitly and only reads settings.moveRule.
        GameEngine(settings: GameSettings(tileCount: 1, baseDiceCount: 1, diceMode: .alwaysTwoDice, moveRule: moveRule))
    }

    // MARK: - Correctness vs. brute force

    /// Compares the optimized search against the brute-force reference across
    /// many boards, open-tile subsets, dice-sum targets, and both move rules.
    /// Small boards (≤8 tiles) exhaustively try every open-tile subset;
    /// larger boards sample the full board, the empty board, and 40 random
    /// subsets each, to keep the brute-force side itself tractable in a test.
    func testMatchesBruteForceReferenceAcrossManyBoardsAndRules() {
        var casesChecked = 0
        let tileCounts = [1, 2, 3, 5, 8, 12, 15, 18]

        for tileCount in tileCounts {
            for moveRule: MoveRule in [.anyCombination, .oneOrTwoTiles] {
                let allTiles = Array(1...tileCount)
                var opensToTry: [[Int]] = []
                if tileCount <= 8 {
                    for mask in 0..<(1 << tileCount) {
                        var subset: [Int] = []
                        for i in 0..<tileCount where mask & (1 << i) != 0 { subset.append(allTiles[i]) }
                        opensToTry.append(subset)
                    }
                } else {
                    opensToTry.append(allTiles)
                    opensToTry.append([])
                    for _ in 0..<40 {
                        opensToTry.append(allTiles.filter { _ in Bool.random() })
                    }
                }

                let engine = searchEngine(moveRule: moveRule)
                for openSubset in opensToTry {
                    for target in 0...max(1, tileCount * 3) {
                        casesChecked += 1
                        let expected = normalized(bruteForceMoves(openSubset, target: target, moveRule: moveRule))
                        let actual = normalized(engine.allowedCombinations(openSubset, target: target, stopAtFirst: false))
                        XCTAssertEqual(
                            expected, actual,
                            "mismatch tileCount=\(tileCount) rule=\(moveRule) open=\(openSubset) target=\(target)"
                        )
                    }
                }
            }
        }

        XCTAssertGreaterThan(casesChecked, 10_000, "sanity check that this test actually exercised a large number of cases")
    }

    /// `hasValidMoves()`'s early-exit path must agree with whether the full
    /// (brute-force-verified) move list is non-empty.
    func testHasValidMovesAgreesWithFullSearchExistence() {
        for tileCount in [1, 4, 12, 18] {
            for moveRule: MoveRule in [.anyCombination, .oneOrTwoTiles] {
                let engine = searchEngine(moveRule: moveRule)
                let allTiles = Array(1...tileCount)
                for target in 0...(tileCount * 3) {
                    let full = engine.allowedCombinations(allTiles, target: target, stopAtFirst: false)
                    let firstOnly = engine.allowedCombinations(allTiles, target: target, stopAtFirst: true)
                    XCTAssertEqual(!full.isEmpty, !firstOnly.isEmpty, "tileCount=\(tileCount) rule=\(moveRule) target=\(target)")
                }
            }
        }
    }

    // MARK: - bestHint tie-break (unchanged strategy)

    func testBestHintPrefersFewestTilesThenLexicographicallyFirst() {
        var engine = GameEngine(settings: GameSettings(tileCount: 12, baseDiceCount: 3, diceMode: .alwaysTwoDice, moveRule: .anyCombination))
        engine.roll(dice: [3, 3, 0]) // total 6: valid moves include [6], [2,4], [1,2,3], [1,5], ...
        let hint = engine.bestHint()
        XCTAssertEqual(hint, [6], "single-tile [6] must win over any multi-tile combination")
    }

    func testBestHintTieBreaksLexicographically() {
        // 10 tiles (no single tile can equal 11), dice sum 11: the two-tile
        // matches are [1,10], [2,9], [3,8], [4,7], [5,6] — all size 2, so the
        // tie-break must pick the lexicographically first, [1,10].
        var engine = GameEngine(settings: GameSettings(tileCount: 10, baseDiceCount: 2, diceMode: .alwaysTwoDice, moveRule: .anyCombination))
        engine.roll(dice: [5, 6])
        let hint = engine.bestHint()
        XCTAssertEqual(hint, [1, 10])
    }

    // MARK: - Performance: full 18-tile board, before vs. after

    /// Measures the optimized search against the brute-force reference on a
    /// full 18-tile (Big Box) board and reports the measured times and
    /// speed-up. Asserts only the direction (optimized must not be slower),
    /// not any specific wall-clock threshold, since absolute timings are not
    /// portable across machines/CI.
    func testFullEighteenTileBoardSearchIsFasterThanBruteForce() {
        let fullBoard = Array(1...18)
        let engine = searchEngine(moveRule: .anyCombination)

        for target in [9, 18, 27] {
            let bruteStart = Date()
            _ = bruteForceMoves(fullBoard, target: target, moveRule: .anyCombination)
            let bruteTime = Date().timeIntervalSince(bruteStart)

            let optimizedStart = Date()
            _ = engine.allowedCombinations(fullBoard, target: target, stopAtFirst: false)
            let optimizedTime = Date().timeIntervalSince(optimizedStart)

            let speedup = bruteTime / max(optimizedTime, 1e-9)
            print("BOD-004 full 18-tile board, target=\(target): brute=\(bruteTime)s optimized=\(optimizedTime)s speedup=\(speedup)x")
            XCTAssertLessThan(optimizedTime, bruteTime, "optimized search must not be slower than the brute-force reference (target=\(target))")
        }
    }
}
