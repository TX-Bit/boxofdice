package com.example.boxofdice.model

/**
 * Controls how many dice are thrown each turn.
 * Mirrors the iOS `DiceMode`.
 */
enum class DiceMode(val displayName: String) {
    /** Always throw the mode's full set of dice. */
    ALWAYS_ALL("Always use all dice"),

    /** Throw a single die once only tiles 1–6 remain open. */
    ONE_DIE_WHEN_LOW("Use one die when only tiles 1–6 remain open");
}

/**
 * Controls which tile combinations the player is allowed to close.
 * Mirrors the iOS `MoveRule`.
 */
enum class MoveRule(val displayName: String) {
    /** Any subset of open tiles whose sum matches the dice total. */
    ANY_COMBINATION("Any combination of open tiles"),

    /** Only one or two tiles may be closed per move. */
    ONE_OR_TWO_TILES("Only one or two tiles");
}

/**
 * Which random source a game draws its dice from.
 * Mirrors the iOS `ChallengeMode`.
 */
enum class ChallengeMode(val displayName: String) {
    NORMAL("Normal random game"),
    DAILY("Daily Challenge"),
    CUSTOM_SEED("Challenge seed");
}
