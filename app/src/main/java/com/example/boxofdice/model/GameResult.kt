package com.example.boxofdice.model

data class GameResult(
    val mode: GameMode,
    val score: Int,
    val tileScore: Int,
    val timeSeconds: Int,
    val isPerfect: Boolean,
    /** Confirmed moves in the finished game — iOS `viewModel.turnCount`. */
    val turns: Int = 0,
    /** Tiles still open at the end, for the "most common remaining" histogram. */
    val remainingTiles: List<Int> = emptyList(),
    val timestamp: Long = System.currentTimeMillis()
)
