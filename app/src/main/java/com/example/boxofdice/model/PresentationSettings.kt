package com.example.boxofdice.model

/**
 * In-app language override, mirroring the iOS `AppLanguage`. [SYSTEM] follows the
 * device locale; the others force the given resource locale for the whole UI.
 */
enum class AppLanguage(val code: String?) {
    SYSTEM(null),
    ENGLISH("en"),
    FINNISH("fi");
}

/**
 * Dice roll animation length, mirroring the iOS `DiceAnimationSpeed`.
 * [rollDelayMillis] is the tumbling window before the final faces settle
 * (the iOS frame-delay sequences sum to roughly these totals).
 */
enum class DiceAnimationSpeed(val rollDelayMillis: Long) {
    SHORT(350L),
    NORMAL(700L),
    LONG(1100L);
}
