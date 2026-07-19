package com.example.boxofdice.model

enum class GameMode(
    val displayName: String,
    val description: String,
    val tileCount: Int,
    val diceCount: Int,
    val hasTimer: Boolean,
    val isMultiplayer: Boolean = false
) {
    CLASSIC(
        displayName = "Classic",
        description = "12 tiles · 2 dice",
        tileCount = 12,
        diceCount = 2,
        hasTimer = false
    ),
    SPEED_RUN(
        displayName = "Speed Run",
        description = "12 tiles · 2 dice · timed",
        tileCount = 12,
        diceCount = 2,
        hasTimer = true
    ),
    BIG_BOX(
        displayName = "Big Box",
        description = "18 tiles · 3 dice",
        tileCount = 18,
        diceCount = 3,
        hasTimer = false
    ),
    BIG_BOX_SPEED(
        displayName = "Big Box Speed",
        description = "18 tiles · 3 dice · timed",
        tileCount = 18,
        diceCount = 3,
        hasTimer = true
    ),
    PASS_AND_PLAY(
        displayName = "Pass & Play",
        description = "2–4 players · one Classic round each",
        tileCount = 12,
        diceCount = 2,
        hasTimer = false,
        isMultiplayer = true
    )
}
