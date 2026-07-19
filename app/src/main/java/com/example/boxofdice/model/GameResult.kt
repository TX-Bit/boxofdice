package com.example.boxofdice.model

data class GameResult(
    val mode: GameMode,
    val score: Int,
    val tileScore: Int,
    val timeSeconds: Int,
    val isPerfect: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)
