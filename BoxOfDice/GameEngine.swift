//
//  GameEngine.swift
//  BoxOfDice
//

import Foundation

// Platform-independent core game logic shared by iOS today and a future watchOS target.
// Keep SwiftUI, UIKit, haptics, sounds, persistence, and device-specific layout out of this file.
// A future WatchGameView can drive this engine directly or through GameViewModel.
struct Tile: Identifiable, Equatable {
    let id: Int
    var isOpen: Bool = true
}

struct MoveRecord: Identifiable {
    let id = UUID()
    let dice: [Int]
    let closedTiles: [Int]
    let scoreAfterMove: Int

    var diceTotal: Int { dice.reduce(0, +) }
}

enum GameState: Equatable {
    case waitingToRoll
    case selecting
    case gameOver(won: Bool)
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
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

struct GameEngine {

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
    func hasValidMoves() -> Bool {
        !validMoves().isEmpty
    }

    func bestHint() -> [Int]? {
        validMoves().min { lhs, rhs in
            if lhs.count == rhs.count { return lhs.lexicographicallyPrecedes(rhs) }
            return lhs.count < rhs.count
        }
    }

    func validMoves() -> [[Int]] {
        allowedSubsets(openTiles, target: diceTotal)
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

    private func allowedSubsets(_ numbers: [Int], target: Int) -> [[Int]] {
        guard target > 0 else { return [] }
        let n = numbers.count
        var matches: [[Int]] = []

        for mask in 1..<(1 << n) {
            var subset: [Int] = []
            var sum = 0
            for i in 0..<n where mask & (1 << i) != 0 {
                sum += numbers[i]
                subset.append(numbers[i])
                if sum > target { break }
            }
            if sum == target && isSelectionAllowed(Set(subset)) {
                matches.append(subset)
            }
        }

        return matches
    }
}
