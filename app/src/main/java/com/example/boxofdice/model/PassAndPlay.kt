package com.example.boxofdice.model

/**
 * State for a Pass & Play session where 2–4 players each play one Classic round on the
 * same device, then compare scores (lowest wins). Mirrors the iOS Pass & Play flow.
 *
 * @param playerCount   How many players are in this session (2–4).
 * @param currentPlayer 1-based index of the player whose round is active or just finished.
 * @param scores        Final tile score per player; null until that player has finished.
 * @param showRoundEnd  True while the "Player N done" hand-off overlay is showing.
 * @param lastScore     The score to display on the hand-off overlay.
 * @param showResults   True while the final ranking overlay is showing.
 */
data class PassAndPlayState(
    val playerCount: Int,
    val currentPlayer: Int,
    val scores: List<Int?>,
    val showRoundEnd: Boolean = false,
    val lastScore: Int = 0,
    val showResults: Boolean = false
) {
    val isLastPlayer: Boolean get() = currentPlayer >= playerCount

    /** Players and final scores sorted best (lowest) first; only finished players. */
    val ranking: List<Pair<Int, Int>>
        get() = scores
            .mapIndexedNotNull { i, s -> s?.let { (i + 1) to it } }
            .sortedBy { it.second }
}
