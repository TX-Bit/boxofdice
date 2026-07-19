package com.example.boxofdice.model

data class TileState(
    val number: Int,
    val isOpen: Boolean = true,
    val isSelected: Boolean = false
)

enum class GamePhase {
    IDLE,
    ROLLING,
    SELECTING,
    GAME_OVER
}

data class GameState(
    val mode: GameMode,
    val tiles: List<TileState>,
    val dice: List<Int> = emptyList(),
    val phase: GamePhase = GamePhase.IDLE,
    val elapsedMillis: Long = 0L,
    val isRolling: Boolean = false,
    val canUndo: Boolean = false
) {
    val diceTotal: Int get() = dice.sum()
    val openTiles: List<TileState> get() = tiles.filter { it.isOpen }
    val selectedTiles: List<TileState> get() = tiles.filter { it.isSelected }
    val selectedSum: Int get() = selectedTiles.sumOf { it.number }
    val remainingScore: Int get() = openTiles.sumOf { it.number }
    val elapsedSeconds: Int get() = (elapsedMillis / 1000).toInt()
    val isGameOver: Boolean get() = phase == GamePhase.GAME_OVER
    val isPerfect: Boolean get() = isGameOver && openTiles.isEmpty()
    val hasRolled: Boolean get() = dice.isNotEmpty()
}
