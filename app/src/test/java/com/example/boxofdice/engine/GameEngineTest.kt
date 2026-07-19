package com.example.boxofdice.engine

import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.MoveRule
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for [GameEngine].
 *
 * All dice rolls are injected via the [diceRoller] constructor parameter so every test
 * is fully deterministic — no Random, no threading, no Android framework.
 */
class GameEngineTest {

    // ── Test helpers ──────────────────────────────────────────────────────────

    /** Returns a roller that always produces the given values (count param is ignored). */
    private fun roller(vararg values: Int): (Int) -> List<Int> = { values.toList() }

    /** Classic engine (12 tiles, 2 dice) with a fixed roller and optional initial state. */
    private fun classic(
        vararg dice: Int,
        open: Set<Int> = (1..12).toSet()
    ) = GameEngine(GameMode.CLASSIC, roller(*dice), open)

    /** Big Box engine (18 tiles, 3 dice) with a fixed roller and optional initial state. */
    private fun bigBox(
        vararg dice: Int,
        open: Set<Int> = (1..18).toSet()
    ) = GameEngine(GameMode.BIG_BOX, roller(*dice), open)

    // ─────────────────────────────────────────────────────────────────────────
    // Initialization
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `classic mode starts with tiles 1 to 12 all open`() {
        val e = GameEngine(GameMode.CLASSIC)
        assertEquals((1..12).toSet(), e.openTiles)
    }

    @Test fun `big box mode starts with tiles 1 to 18 all open`() {
        val e = GameEngine(GameMode.BIG_BOX)
        assertEquals((1..18).toSet(), e.openTiles)
    }

    @Test fun `new game has no closed tiles`() {
        assertTrue(GameEngine(GameMode.CLASSIC).closedTiles.isEmpty())
    }

    @Test fun `new game has no selected tiles`() {
        assertTrue(GameEngine(GameMode.CLASSIC).selectedTiles.isEmpty())
    }

    @Test fun `new game has no dice values`() {
        assertTrue(GameEngine(GameMode.CLASSIC).diceValues.isEmpty())
    }

    @Test fun `new game is not over`() {
        assertFalse(GameEngine(GameMode.CLASSIC).isGameOver())
    }

    @Test fun `new game board is not cleared`() {
        assertFalse(GameEngine(GameMode.CLASSIC).isBoardCleared())
    }

    @Test fun `custom initial open tiles exclude the rest as closed`() {
        val e = classic(1, 2, open = setOf(11, 12))
        assertEquals(setOf(11, 12), e.openTiles)
        assertEquals((1..10).toSet(), e.closedTiles)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Score calculation
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `initial classic score is 78`() {
        assertEquals(78, GameEngine(GameMode.CLASSIC).calculateScore()) // 1+2+…+12
    }

    @Test fun `initial big box score is 171`() {
        assertEquals(171, GameEngine(GameMode.BIG_BOX).calculateScore()) // 1+2+…+18
    }

    @Test fun `score equals sum of remaining open tiles`() {
        val e = classic(1, 1, open = setOf(3, 5, 11, 12))
        assertEquals(3 + 5 + 11 + 12, e.calculateScore())
    }

    @Test fun `score decreases by the sum of confirmed tiles`() {
        val e = classic(3, 4) // target 7
        val before = e.calculateScore()
        e.rollDice()
        e.toggleTileSelection(7)
        e.confirmMove()
        assertEquals(before - 7, e.calculateScore())
    }

    @Test fun `perfect score is zero after clearing the board`() {
        val e = classic(1, 1, open = setOf(2)) // only tile 2, target 2
        e.rollDice()
        e.toggleTileSelection(2)
        e.confirmMove()
        assertEquals(0, e.calculateScore())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Roll dice
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `roll dice stores values from the injected roller`() {
        val e = classic(3, 4)
        e.rollDice()
        assertEquals(listOf(3, 4), e.diceValues)
    }

    @Test fun `current target sum equals sum of dice after roll`() {
        val e = classic(5, 6)
        e.rollDice()
        assertEquals(11, e.currentTargetSum)
    }

    @Test fun `big box roll produces three dice values`() {
        val e = bigBox(2, 3, 4)
        e.rollDice()
        assertEquals(listOf(2, 3, 4), e.diceValues)
        assertEquals(9, e.currentTargetSum)
    }

    @Test fun `rolling clears any existing tile selection`() {
        val e = classic(3, 4)
        e.rollDice()
        e.toggleTileSelection(7)
        e.rollDice() // re-roll clears selection
        assertTrue(e.selectedTiles.isEmpty())
    }

    @Test(expected = IllegalStateException::class)
    fun `cannot roll when the game is already over`() {
        // open={1,2}, target=22 → no valid move → game over
        val e = classic(11, 11, open = setOf(1, 2))
        e.rollDice() // ends game
        e.rollDice() // must throw
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Tile selection
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `toggling an open tile marks it selected`() {
        val e = classic(1, 2)
        e.rollDice()
        e.toggleTileSelection(5)
        assertTrue(5 in e.selectedTiles)
    }

    @Test fun `toggling a selected tile deselects it but keeps it open`() {
        val e = classic(1, 2)
        e.rollDice()
        e.toggleTileSelection(5)
        e.toggleTileSelection(5)
        assertFalse(5 in e.selectedTiles)
        assertTrue(5 in e.openTiles)
    }

    @Test fun `toggling the same tile three times leaves it selected`() {
        val e = classic(1, 2)
        e.rollDice()
        e.toggleTileSelection(5)
        e.toggleTileSelection(5)
        e.toggleTileSelection(5)
        assertTrue(5 in e.selectedTiles)
    }

    @Test(expected = IllegalStateException::class)
    fun `cannot select tile before dice are rolled`() {
        classic(1, 2).toggleTileSelection(3)
    }

    @Test(expected = IllegalStateException::class)
    fun `cannot select a closed tile`() {
        val e = classic(1, 2) // target 3
        e.rollDice()
        e.toggleTileSelection(3)
        e.confirmMove() // tile 3 is now closed
        e.rollDice()    // target 3 again
        e.toggleTileSelection(3) // must throw — tile 3 is closed
    }

    @Test(expected = IllegalStateException::class)
    fun `cannot select tile when game is over`() {
        val e = classic(11, 11, open = setOf(1, 2))
        e.rollDice() // game over
        e.toggleTileSelection(1) // must throw
    }

    // ─────────────────────────────────────────────────────────────────────────
    // canConfirmMove — valid combinations
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `empty selection cannot be confirmed`() {
        val e = classic(3, 4)
        e.rollDice()
        assertFalse(e.canConfirmMove())
    }

    @Test fun `selection below target cannot be confirmed`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(3) // sum 3
        assertFalse(e.canConfirmMove())
    }

    @Test fun `selection above target cannot be confirmed`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(4)
        e.toggleTileSelection(5) // sum 9
        assertFalse(e.canConfirmMove())
    }

    @Test fun `single tile equal to target is a valid move`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(7)
        assertTrue(e.canConfirmMove())
    }

    @Test fun `two tiles summing to target is a valid move`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(3)
        e.toggleTileSelection(4) // 3+4=7
        assertTrue(e.canConfirmMove())
    }

    @Test fun `three tiles summing to target is a valid move`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(1)
        e.toggleTileSelection(2)
        e.toggleTileSelection(4) // 1+2+4=7
        assertTrue(e.canConfirmMove())
    }

    @Test fun `cannot confirm without rolling first`() {
        assertFalse(classic(3, 4).canConfirmMove())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // confirmMove
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `confirmed tiles move from open to closed`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(3)
        e.toggleTileSelection(4)
        e.confirmMove()
        assertTrue(3 in e.closedTiles && 4 in e.closedTiles)
        assertFalse(3 in e.openTiles || 4 in e.openTiles)
    }

    @Test fun `confirm clears the selection`() {
        val e = classic(3, 4)
        e.rollDice()
        e.toggleTileSelection(7)
        e.confirmMove()
        assertTrue(e.selectedTiles.isEmpty())
    }

    @Test fun `confirm resets dice values for next roll`() {
        val e = classic(3, 4)
        e.rollDice()
        e.toggleTileSelection(7)
        e.confirmMove()
        assertTrue(e.diceValues.isEmpty())
        assertEquals(0, e.currentTargetSum)
    }

    @Test fun `closed tiles accumulate correctly over multiple rounds`() {
        val e = classic(3, 4) // always target 7
        e.rollDice(); e.toggleTileSelection(7); e.confirmMove()   // closes 7
        e.rollDice(); e.toggleTileSelection(3); e.toggleTileSelection(4); e.confirmMove() // closes 3,4
        assertEquals(setOf(3, 4, 7), e.closedTiles)
    }

    @Test(expected = IllegalStateException::class)
    fun `confirm throws when selection is invalid`() {
        val e = classic(3, 4) // target 7
        e.rollDice()
        e.toggleTileSelection(5) // sum 5 ≠ 7
        e.confirmMove()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // hasValidMove
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `hasValidMove is false before rolling`() {
        assertFalse(classic(3, 4).hasValidMove())
    }

    @Test fun `hasValidMove is true when a single open tile equals target`() {
        val e = classic(3, 4, open = setOf(7, 11, 12)) // target 7, tile 7 present
        e.rollDice()
        assertTrue(e.hasValidMove())
    }

    @Test fun `hasValidMove is true when two open tiles sum to target`() {
        val e = classic(3, 4, open = setOf(3, 4, 9)) // 3+4=7
        e.rollDice()
        assertTrue(e.hasValidMove())
    }

    @Test fun `hasValidMove is true when three open tiles sum to target`() {
        val e = classic(3, 4, open = setOf(1, 2, 4, 9)) // 1+2+4=7
        e.rollDice()
        assertTrue(e.hasValidMove())
    }

    @Test fun `hasValidMove is false when no subset of open tiles sums to target`() {
        val e = classic(3, 4, open = setOf(11, 12)) // target 7, no subset of {11,12} sums to 7
        e.rollDice()
        assertFalse(e.hasValidMove())
    }

    @Test fun `hasValidMove is false when target exceeds sum of all open tiles`() {
        val e = classic(6, 6, open = setOf(1, 2)) // target 12, max reachable 3
        e.rollDice()
        assertFalse(e.hasValidMove())
    }

    @Test fun `hasValidMove considers only open tiles not closed ones`() {
        // Tile 7 will be closed; target 7 must come from other tiles
        val e = classic(3, 4, open = setOf(3, 4, 7))
        e.rollDice()
        e.toggleTileSelection(7)
        e.confirmMove() // 7 is closed; open = {3,4}

        e.rollDice() // target 7 again
        assertTrue(e.hasValidMove()) // 3+4=7 still works
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Game over detection
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `game is over when roll produces no valid move`() {
        val e = classic(3, 4, open = setOf(11, 12)) // target 7, no valid subset
        e.rollDice()
        assertTrue(e.isGameOver())
    }

    @Test fun `game is over when board is cleared after confirm`() {
        val e = classic(1, 1, open = setOf(2)) // only tile 2, target 2
        e.rollDice()
        e.toggleTileSelection(2)
        e.confirmMove()
        assertTrue(e.isGameOver())
    }

    @Test fun `game is not over when valid moves remain`() {
        val e = classic(1, 2) // many valid combos with 12 tiles
        e.rollDice()
        assertFalse(e.isGameOver())
    }

    @Test fun `game over state does not change after it is set`() {
        val e = classic(3, 4, open = setOf(11, 12))
        e.rollDice()
        assertTrue(e.isGameOver())
        // State is sticky — still game over
        assertTrue(e.isGameOver())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Board cleared (perfect game)
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `board is cleared after last tile is confirmed`() {
        val e = classic(1, 1, open = setOf(2))
        e.rollDice()
        e.toggleTileSelection(2)
        e.confirmMove()
        assertTrue(e.isBoardCleared())
    }

    @Test fun `board is not cleared when tiles remain`() {
        val e = classic(3, 4)
        e.rollDice()
        e.toggleTileSelection(7)
        e.confirmMove()
        assertFalse(e.isBoardCleared())
    }

    @Test fun `cleared board has empty open set and game is over`() {
        val e = classic(1, 1, open = setOf(2))
        e.rollDice()
        e.toggleTileSelection(2)
        e.confirmMove()
        assertTrue(e.openTiles.isEmpty())
        assertTrue(e.isBoardCleared())
        assertTrue(e.isGameOver())
    }

    @Test fun `cleared board has score of zero`() {
        val e = classic(1, 1, open = setOf(2))
        e.rollDice()
        e.toggleTileSelection(2)
        e.confirmMove()
        assertEquals(0, e.calculateScore())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Full-round integration checks
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `full classic round reduces open tiles and increases closed tiles`() {
        val e = classic(3, 4) // target 7
        val openBefore = e.openTiles.size
        e.rollDice()
        e.toggleTileSelection(3)
        e.toggleTileSelection(4)
        e.confirmMove()
        assertEquals(openBefore - 2, e.openTiles.size)
        assertEquals(2, e.closedTiles.size)
    }

    @Test fun `game proceeds correctly through multiple rounds`() {
        // Target always 7; close {7}, then {3,4}, then {1,2,4} would reuse 4 but it's closed
        // So: round1 closes 7; round2 closes 3+4; after that {1,2,5,6,8,9,10,11,12} remain
        val e = classic(3, 4)
        e.rollDice(); e.toggleTileSelection(7); e.confirmMove()
        assertFalse(e.isGameOver())
        assertFalse(e.isBoardCleared())

        e.rollDice(); e.toggleTileSelection(3); e.toggleTileSelection(4); e.confirmMove()
        assertFalse(e.isGameOver())
        assertEquals(setOf(1, 2, 5, 6, 8, 9, 10, 11, 12), e.openTiles)
    }

    @Test fun `big box mode game over when no valid move after roll`() {
        // open={17,18}, target=9 (3+3+3) — no subset of {17,18} sums to 9
        val e = bigBox(3, 3, 3, open = setOf(17, 18))
        e.rollDice()
        assertTrue(e.isGameOver())
        assertFalse(e.isBoardCleared()) // tiles remain, not a perfect game
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Undo
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `cannot undo before any move`() {
        assertFalse(classic(3, 4).canUndo())
    }

    @Test fun `undo reopens the tiles closed by the last move`() {
        val e = classic(3, 4) // target 7
        e.rollDice(); e.toggleTileSelection(7); e.confirmMove()
        assertTrue(e.canUndo())
        e.undoLastMove()
        assertTrue(7 in e.openTiles)
        assertFalse(7 in e.closedTiles)
        assertFalse(e.canUndo())
    }

    @Test fun `cannot undo in the middle of a turn`() {
        val e = classic(3, 4)
        e.rollDice(); e.toggleTileSelection(7); e.confirmMove()
        e.rollDice() // dice are out again — undo blocked until next confirm/idle
        assertFalse(e.canUndo())
    }

    @Test fun `undo restores score`() {
        val e = classic(3, 4)
        val before = e.calculateScore()
        e.rollDice(); e.toggleTileSelection(7); e.confirmMove()
        e.undoLastMove()
        assertEquals(before, e.calculateScore())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // validMoves / bestHint
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `bestHint prefers the fewest tiles`() {
        // target 7, open includes 7 and {3,4} — single tile 7 is the best hint
        val e = classic(3, 4, open = setOf(3, 4, 7, 11, 12))
        e.rollDice()
        assertEquals(listOf(7), e.bestHint())
    }

    @Test fun `bestHint is null when game is over`() {
        val e = classic(3, 4, open = setOf(11, 12))
        e.rollDice()
        assertNull(e.bestHint())
    }

    @Test fun `validMoves lists every summing subset`() {
        val e = classic(3, 4, open = setOf(3, 4, 7)) // {7} and {3,4} both sum to 7
        e.rollDice()
        val moves = e.validMoves().map { it.sorted().toSet() }.toSet()
        assertEquals(setOf(setOf(7), setOf(3, 4)), moves)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MoveRule
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `one or two tile rule rejects a three tile selection`() {
        val e = GameEngine(
            GameMode.CLASSIC, roller(3, 4), (1..12).toSet(),
            moveRule = MoveRule.ONE_OR_TWO_TILES
        )
        e.rollDice() // target 7
        e.toggleTileSelection(1); e.toggleTileSelection(2); e.toggleTileSelection(4) // 3 tiles = 7
        assertFalse(e.canConfirmMove())
    }

    @Test fun `one or two tile rule allows a two tile selection`() {
        val e = GameEngine(
            GameMode.CLASSIC, roller(3, 4), (1..12).toSet(),
            moveRule = MoveRule.ONE_OR_TWO_TILES
        )
        e.rollDice()
        e.toggleTileSelection(3); e.toggleTileSelection(4)
        assertTrue(e.canConfirmMove())
    }

    @Test fun `one or two tile rule ends game when only a three tile move exists`() {
        // target 7, open = {1,2,4} → only 1+2+4 works, which the rule forbids
        val e = GameEngine(
            GameMode.CLASSIC, roller(3, 4), setOf(1, 2, 4),
            moveRule = MoveRule.ONE_OR_TWO_TILES
        )
        e.rollDice()
        assertTrue(e.isGameOver())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DiceMode
    // ─────────────────────────────────────────────────────────────────────────

    @Test fun `one die mode throws a single die once only low tiles remain`() {
        val e = GameEngine(
            GameMode.CLASSIC, roller(2), setOf(1, 2, 3),
            diceMode = DiceMode.ONE_DIE_WHEN_LOW
        )
        assertEquals(1, e.currentDieCount)
    }

    @Test fun `one die mode still throws all dice while a high tile is open`() {
        val e = GameEngine(
            GameMode.CLASSIC, roller(3, 4), setOf(1, 2, 7),
            diceMode = DiceMode.ONE_DIE_WHEN_LOW
        )
        assertEquals(2, e.currentDieCount)
    }
}
