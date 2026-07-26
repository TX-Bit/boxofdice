package com.example.boxofdice.engine

import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.MoveRule

/**
 * Self-contained game engine for Box of Dice (Shut the Box).
 *
 * @param currentGameMode  Mode controlling tile count and base dice count.
 * @param diceRoller       Injectable dice source — receives the number of dice to roll and
 *                         returns a list of that size. Defaults to (1..6).random() per die.
 *                         Override in tests to make rolls deterministic.
 * @param initialOpenTiles Starting set of open tile numbers. Defaults to every tile for the mode.
 *                         Supply a subset in tests to fast-forward to a specific board state.
 * @param diceMode         Whether all dice are always thrown, or a single die once only tiles
 *                         1–6 remain open.
 * @param moveRule         Whether any combination of open tiles may be closed, or only one/two.
 */
class GameEngine(
    val currentGameMode: GameMode,
    private val diceRoller: (count: Int) -> List<Int> = { n -> List(n) { (1..6).random() } },
    initialOpenTiles: Set<Int> = (1..currentGameMode.tileCount).toSet(),
    val diceMode: DiceMode = DiceMode.ALWAYS_ALL,
    val moveRule: MoveRule = MoveRule.ANY_COMBINATION
) {
    /** A single confirmed move, kept so it can be undone. */
    data class MoveRecord(val dice: List<Int>, val closedTiles: Set<Int>)

    // ── Internal mutable state
    // ────────────────────────────────────────────────

    private val _open: MutableSet<Int> =
        initialOpenTiles.toMutableSet()commit

    private val _closed: MutableSet<Int> =
        ((1..currentGameMode.tileCount).toSet() - initialOpenTiles).toMutableSet()

    private val _selected: MutableSet<Int> =
        mutableSetOf()

    private var _diceValues: List<Int> =
        emptyList()

    private var _gameOver: Boolean =
        false

    private val _history: MutableList<MoveRecord> =
        mutableListOf()

    // ── Public read-only state ────────────────────────────────────────────────

    /** Numbers of tiles that have not yet been closed. */
    val openTiles: Set<Int> get() = _open.toSet()

    /** Numbers of tiles that have been confirmed closed this game. */
    val closedTiles: Set<Int> get() = _closed.toSet()

    /** Subset of [openTiles] the player has highlighted for the current move. */
    val selectedTiles: Set<Int> get() = _selected.toSet()

    /** Values shown on the dice after the most recent [rollDice], empty when awaiting a roll. */
    val diceValues: List<Int> get() = _diceValues.toList()

    /** Sum of the current dice — the target the player must match with tile selections. */
    val currentTargetSum: Int get() = _diceValues.sum()

    /** Confirmed moves this game, oldest first. */
    val moveHistory: List<MoveRecord> get() = _history.toList()

    /** Number of confirmed moves so far. */
    val turnCount: Int get() = _history.size

    /**
     * How many dice the next roll will throw. With [DiceMode.ONE_DIE_WHEN_LOW] this drops to a
     * single die once every open tile is 6 or lower; otherwise it is the mode's base dice count.
     */
    val currentDieCount: Int
        get() = when (diceMode) {
            DiceMode.ALWAYS_ALL -> currentGameMode.diceCount
            DiceMode.ONE_DIE_WHEN_LOW ->
                if (_open.isNotEmpty() && _open.all { it <= 6 }) 1 else currentGameMode.diceCount
        }

    // ── Actions ───────────────────────────────────────────────────────────────

    /**
     * Roll the dice for this turn.
     * Clears any pending tile selection, generates [currentDieCount] dice via [diceRoller],
     * then immediately checks whether any valid move exists.
     * If none exists the game is over.
     */
    fun rollDice() {
        check(!_gameOver) { "Game is already over." }
        _selected.clear()
        _diceValues = diceRoller(currentDieCount)
        if (!hasValidMove()) {
            _gameOver = true
        }
    }

    /**
     * Toggle selection of an open tile.
     * Selecting a tile adds it to the pending move; selecting it again removes it.
     *
     * @throws IllegalStateException if dice have not been rolled yet, the game is over,
     *         or [tile] is not in [openTiles].
     */
    fun toggleTileSelection(tile: Int) {
        check(!_gameOver) { "Game is already over." }
        check(_diceValues.isNotEmpty()) { "Roll dice before selecting tiles." }
        check(tile in _open) { "Tile $tile is not open (open=$_open)." }
        if (tile in _selected) _selected.remove(tile) else _selected.add(tile)
    }

    /**
     * Returns true when the current selection is non-empty, allowed by the [moveRule], and its
     * sum equals [currentTargetSum]. This is the gate for [confirmMove].
     */
    fun canConfirmMove(): Boolean =
        _diceValues.isNotEmpty() &&
        _selected.isNotEmpty() &&
        isSelectionAllowed(_selected) &&
        _selected.sumOf { it } == currentTargetSum

    /**
     * Close all selected tiles and prepare for the next roll.
     * If the board is cleared the game ends with a perfect result.
     *
     * @throws IllegalStateException if [canConfirmMove] returns false.
     */
    fun confirmMove() {
        check(canConfirmMove()) {
            "Cannot confirm: selected ${_selected.sumOf { it }} ≠ target $currentTargetSum."
        }
        _history.add(MoveRecord(dice = _diceValues.toList(), closedTiles = _selected.toSet()))
        _open.removeAll(_selected)
        _closed.addAll(_selected)
        _selected.clear()
        _diceValues = emptyList()
        if (_open.isEmpty()) _gameOver = true
    }

    /** True when the most recent confirmed move can be undone (between rolls, game not over). */
    fun canUndo(): Boolean =
        !_gameOver && _diceValues.isEmpty() && _history.isNotEmpty()

    /**
     * Reopen the tiles closed by the most recent confirmed move and return to the
     * waiting-to-roll state. No-op when [canUndo] is false.
     */
    fun undoLastMove() {
        if (!canUndo()) return
        val last = _history.removeAt(_history.lastIndex)
        _open.addAll(last.closedTiles)
        _closed.removeAll(last.closedTiles)
        _selected.clear()
        _diceValues = emptyList()
    }

    /**
     * Returns true if any allowed subset of [openTiles] sums to [currentTargetSum].
     * With [MoveRule.ANY_COMBINATION] this uses 0/1 knapsack DP — O(n × target). With
     * [MoveRule.ONE_OR_TWO_TILES] only one- and two-tile selections count.
     * Always false before dice are rolled.
     */
    fun hasValidMove(): Boolean {
        if (_diceValues.isEmpty()) return false
        val target = currentTargetSum
        return when (moveRule) {
            MoveRule.ANY_COMBINATION -> hasSubsetWithSum(_open.toList(), target)
            MoveRule.ONE_OR_TWO_TILES -> hasOneOrTwoTileMove(_open.toList(), target)
        }
    }

    /**
     * All allowed tile selections that sum to the current dice total. Empty before a roll or when
     * the game is over. Honours the [moveRule].
     */
    fun validMoves(): List<List<Int>> {
        if (_diceValues.isEmpty() || _gameOver) return emptyList()
        return allowedSubsets(_open.toList().sorted(), currentTargetSum)
    }

    /**
     * The "best" hint: the valid move that closes the fewest tiles, breaking ties by the
     * lexicographically smallest set. Null when no move exists.
     */
    fun bestHint(): List<Int>? =
        validMoves().minWithOrNull(
            compareBy<List<Int>> { it.size }.thenComparator { a, b -> lexCompare(a, b) }
        )

    /** Sum of remaining open tile numbers — the player's current score (lower is better). */
    fun calculateScore(): Int = _open.sum()

    /** True when every tile has been closed (perfect game). */
    fun isBoardCleared(): Boolean = _open.isEmpty()

    /**
     * True when the game has ended — either because [rollDice] found no valid move,
     * or because [confirmMove] cleared the board.
     */
    fun isGameOver(): Boolean = _gameOver

    // ── Private helpers ───────────────────────────────────────────────────────

    private fun isSelectionAllowed(selection: Set<Int>): Boolean = when (moveRule) {
        MoveRule.ANY_COMBINATION -> true
        MoveRule.ONE_OR_TWO_TILES -> selection.size <= 2
    }

    private fun hasSubsetWithSum(numbers: List<Int>, target: Int): Boolean {
        if (target <= 0 || numbers.isEmpty()) return false
        if (target > numbers.sum()) return false      // quick-reject
        val dp = BooleanArray(target + 1)
        dp[0] = true
        for (num in numbers) {
            for (s in target downTo num) {
                if (dp[s - num]) dp[s] = true
            }
        }
        return dp[target]
    }

    private fun hasOneOrTwoTileMove(numbers: List<Int>, target: Int): Boolean {
        if (target <= 0) return false
        if (target in numbers) return true
        for (i in numbers.indices) {
            for (j in i + 1 until numbers.size) {
                if (numbers[i] + numbers[j] == target) return true
            }
        }
        return false
    }

    /** All subsets of [numbers] that sum to [target] and are permitted by the [moveRule]. */
    private fun allowedSubsets(numbers: List<Int>, target: Int): List<List<Int>> {
        if (target <= 0) return emptyList()
        val n = numbers.size
        val matches = mutableListOf<List<Int>>()
        // n is small (≤ 18); a bitmask sweep is clear and fast enough.
        for (mask in 1 until (1 shl n)) {
            var sum = 0
            val subset = mutableListOf<Int>()
            for (i in 0 until n) {
                if (mask and (1 shl i) != 0) {
                    sum += numbers[i]
                    subset.add(numbers[i])
                    if (sum > target) break
                }
            }
            if (sum == target && isSelectionAllowed(subset.toSet())) {
                matches.add(subset)
            }
        }
        return matches
    }

    private fun lexCompare(a: List<Int>, b: List<Int>): Int {
        val min = minOf(a.size, b.size)
        for (i in 0 until min) {
            val c = a[i].compareTo(b[i])
            if (c != 0) return c
        }
        return a.size.compareTo(b.size)
    }
}
