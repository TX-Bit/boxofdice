//
//  GameEngine.swift
//  BoxOfDice
//

import Foundation

// Platform-independent core game logic and pure models, shared verbatim by the
// iOS ("BoxOfDice") and watchOS ("BoxOfDice Watch App") targets — see this
// file's explicit membership in both targets in project.pbxproj. Keep SwiftUI,
// WatchKit, localization (L10n), haptics/sound feedback, persistence keys, and
// any other device-specific code out of this file; those stay per-platform.
struct Tile: Identifiable, Equatable, Codable {
    let id: Int
    var isOpen: Bool = true
}

struct MoveRecord: Identifiable, Codable {
    let id = UUID()
    let dice: [Int]
    let closedTiles: [Int]
    let scoreAfterMove: Int

    var diceTotal: Int { dice.reduce(0, +) }

    // `id` is a fresh, local Identifiable handle for SwiftUI lists; it's
    // never meaningful across a save/restore round-trip, so it's excluded
    // here rather than persisted and silently regenerated anyway.
    private enum CodingKeys: String, CodingKey {
        case dice, closedTiles, scoreAfterMove
    }
}

enum GameState: Equatable, Codable {
    case waitingToRoll
    case selecting
    case gameOver(won: Bool)
}

// Titles for these two are presentation/localization concerns and belong with
// whichever platform's settings UI eventually exposes them (none does today
// on either platform; both currently hardcode .alwaysTwoDice/.anyCombination).
enum DiceMode: String, CaseIterable, Identifiable, Codable {
    case alwaysTwoDice
    case oneDieWhenLowTilesRemain

    var id: String { rawValue }
}

enum MoveRule: String, CaseIterable, Identifiable, Codable {
    case anyCombination
    case oneOrTwoTiles

    var id: String { rawValue }
}

struct GameSettings: Equatable, Codable {
    var tileCount: Int
    var baseDiceCount: Int
    var diceMode: DiceMode
    var moveRule: MoveRule

    static let `default` = GameSettings(
        tileCount: 12,
        baseDiceCount: 2,
        diceMode: .alwaysTwoDice,
        moveRule: .anyCombination
    )

    static func from(mode: GameMode, diceMode: DiceMode, moveRule: MoveRule) -> GameSettings {
        GameSettings(
            tileCount: mode.tileCount,
            baseDiceCount: mode.baseDiceCount,
            diceMode: diceMode,
            moveRule: moveRule
        )
    }

    init(tileCount: Int, baseDiceCount: Int, diceMode: DiceMode, moveRule: MoveRule) {
        self.tileCount = tileCount
        self.baseDiceCount = max(1, min(3, baseDiceCount))
        self.diceMode = diceMode
        self.moveRule = moveRule
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator, Codable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

struct GameEngine: Codable {

    // MARK: - State

    private(set) var settings: GameSettings
    private(set) var tiles: [Tile]
    // Dice stored as array of up to 3 values; 0 = inactive die slot.
    private(set) var dice: [Int] = [0, 0, 0]
    private(set) var selectedTiles: Set<Int> = []
    private(set) var gameState: GameState = .waitingToRoll
    private(set) var moveHistory: [MoveRecord] = []
    private var randomGenerator: SeededRandomNumberGenerator?

    init(settings: GameSettings = .default, seed: UInt64? = nil) {
        self.settings = settings
        self.tiles = (1...settings.tileCount).map { Tile(id: $0) }
        if let seed {
            self.randomGenerator = SeededRandomNumberGenerator(seed: seed)
        }
    }

    // MARK: - Computed Properties

    var diceTotal: Int { dice.reduce(0, +) }

    var score: Int {
        tiles.filter { $0.isOpen }.reduce(0) { $0 + $1.id }
    }

    var selectionTotal: Int {
        selectedTiles.reduce(0, +)
    }

    var turnCount: Int { moveHistory.count }

    var canConfirm: Bool {
        !selectedTiles.isEmpty && isSelectionAllowed(selectedTiles) && selectionTotal == diceTotal
    }

    var canUndo: Bool {
        gameState == .waitingToRoll && !moveHistory.isEmpty
    }

    var hasRolled: Bool { dice.contains(where: { $0 > 0 }) }

    var openTiles: [Int] {
        tiles.filter { $0.isOpen }.map { $0.id }
    }

    var currentDieCount: Int {
        switch settings.diceMode {
        case .alwaysTwoDice:
            return settings.baseDiceCount
        case .oneDieWhenLowTilesRemain:
            return openTiles.allSatisfy { $0 <= 6 } ? 1 : settings.baseDiceCount
        }
    }

    var isGameOver: Bool {
        if case .gameOver = gameState { return true }
        return false
    }

    var isWinner: Bool {
        if case .gameOver(let won) = gameState { return won }
        return false
    }

    // MARK: - Actions

    /// Rolls the dice, clears any pending selection, then transitions to .selecting
    /// or .gameOver depending on whether a valid move exists.
    mutating func roll(dice rolledDice: [Int]? = nil) {
        guard case .waitingToRoll = gameState else { return }
        selectedTiles = []
        dice = rolledDice ?? randomDice()
        gameState = hasValidMoves() ? .selecting : .gameOver(won: false)
    }

    /// Toggles a tile in or out of the pending selection.
    mutating func toggleTile(_ number: Int) {
        guard case .selecting = gameState else { return }
        guard tiles.first(where: { $0.id == number })?.isOpen == true else { return }
        if selectedTiles.contains(number) {
            selectedTiles.remove(number)
        } else {
            selectedTiles.insert(number)
        }
    }

    /// Closes the selected tiles when they sum to the dice total, then transitions
    /// to .gameOver(won: true) if all tiles are closed, otherwise back to .waitingToRoll.
    mutating func confirmSelection() {
        guard canConfirm, case .selecting = gameState else { return }
        let closedTiles = selectedTiles.sorted()
        for i in tiles.indices where selectedTiles.contains(tiles[i].id) {
            tiles[i].isOpen = false
        }
        selectedTiles = []
        let won = tiles.allSatisfy { !$0.isOpen }
        moveHistory.append(MoveRecord(dice: dice, closedTiles: closedTiles, scoreAfterMove: score))
        gameState = won ? .gameOver(won: true) : .waitingToRoll
    }

    mutating func undoLastMove() {
        guard canUndo, let lastMove = moveHistory.popLast() else { return }
        for i in tiles.indices where lastMove.closedTiles.contains(tiles[i].id) {
            tiles[i].isOpen = true
        }
        dice = [0, 0, 0]
        selectedTiles = []
        gameState = .waitingToRoll
    }

    /// Resets all state to the beginning of a new game.
    mutating func reset(settings newSettings: GameSettings? = nil, seed: UInt64? = nil) {
        if let newSettings {
            settings = newSettings
        }
        if let seed {
            randomGenerator = SeededRandomNumberGenerator(seed: seed)
        } else {
            randomGenerator = nil
        }
        tiles = (1...settings.tileCount).map { Tile(id: $0) }
        dice = [0, 0, 0]
        selectedTiles = []
        moveHistory = []
        gameState = .waitingToRoll
    }

    mutating func randomDice() -> [Int] {
        let count = currentDieCount
        var result = [0, 0, 0]
        for i in 0..<count {
            result[i] = randomDie()
        }
        return result
    }

    // MARK: - Move Validation

    /// Returns true if any allowed selection of currently open tiles sums to the dice total.
    /// Stops at the first match instead of building the full move list.
    func hasValidMoves() -> Bool {
        !allowedCombinations(openTiles, target: diceTotal, stopAtFirst: true).isEmpty
    }

    func bestHint() -> [Int]? {
        validMoves().min { lhs, rhs in
            if lhs.count == rhs.count { return lhs.lexicographicallyPrecedes(rhs) }
            return lhs.count < rhs.count
        }
    }

    func validMoves() -> [[Int]] {
        allowedCombinations(openTiles, target: diceTotal, stopAtFirst: false)
    }

    // MARK: - Private

    private mutating func randomDie() -> Int {
        if var generator = randomGenerator {
            let value = Int.random(in: 1...6, using: &generator)
            randomGenerator = generator
            return value
        }
        return Int.random(in: 1...6)
    }

    private func isSelectionAllowed(_ selection: Set<Int>) -> Bool {
        switch settings.moveRule {
        case .anyCombination:
            return true
        case .oneOrTwoTiles:
            return selection.count <= 2
        }
    }

    /// The maximum number of tiles a single move may close under the current
    /// move rule, applied during the search below rather than as a filter
    /// afterwards. `nil` means no limit.
    private var maxTilesPerMove: Int? {
        switch settings.moveRule {
        case .anyCombination:      return nil
        case .oneOrTwoTiles:       return 2
        }
    }

    /// Depth-first search over ascending, strictly-positive tile numbers for
    /// every combination summing exactly to `target`, honouring the current
    /// move rule. Because tile numbers are positive and the list is sorted
    /// ascending, a running sum that already exceeds `target` can only grow
    /// with any further tile (whether the next one or any later, larger one)
    /// — so that whole branch is abandoned immediately instead of visiting
    /// each of its subsets individually, unlike the previous full bitmask
    /// scan of every one of the 2^n subsets. When `stopAtFirst` is true the
    /// search returns as soon as one match is found, without enumerating the
    /// rest — used by `hasValidMoves()`, which only needs an existence check.
    // Not private so BOD-004's tests (`@testable import`) can drive it directly
    // with arbitrary tile lists, independent of an engine's live tile state.
    func allowedCombinations(_ tileNumbers: [Int], target: Int, stopAtFirst: Bool) -> [[Int]] {
        guard target > 0, !tileNumbers.isEmpty else { return [] }
        let numbers = tileNumbers.sorted()
        let maxTiles = maxTilesPerMove

        var matches: [[Int]] = []
        var current: [Int] = []
        var currentSum = 0

        // Returns true once `stopAtFirst` is set and a match has been found,
        // so every enclosing call unwinds immediately without further work.
        func search(from index: Int) -> Bool {
            if currentSum == target {
                matches.append(current)
                return stopAtFirst
            }
            guard index < numbers.count else { return false }
            // Positive, ascending tile numbers: once adding the smallest
            // remaining tile would already overshoot, no combination built
            // from here (with this tile or any larger one after it) can ever
            // land back on target — abandon the whole branch.
            guard currentSum + numbers[index] <= target else { return false }
            if let maxTiles, current.count >= maxTiles { return false }

            current.append(numbers[index])
            currentSum += numbers[index]
            if search(from: index + 1) { return true }
            currentSum -= numbers[index]
            current.removeLast()

            return search(from: index + 1)
        }

        _ = search(from: 0)
        return matches
    }
}
