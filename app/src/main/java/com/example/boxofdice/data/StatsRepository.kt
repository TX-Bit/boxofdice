package com.example.boxofdice.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.GameResult
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.statsStore by preferencesDataStore(name = "stats")

data class ModeStats(
    val bestScore: Int?,
    val gamesPlayed: Int,
    val perfectGames: Int
)

/**
 * Everything the stats sheet shows, mirroring the iOS `StatisticsStorageKey` set
 * one-for-one. A "win" is a cleared board, exactly as on iOS.
 *
 * [bestScore] is null until a game has been finished — 0 is a real score (a perfect
 * clear), so it cannot double as "nothing recorded". Turn counts keep 0 for "none",
 * which is safe: a finished game always has at least one turn.
 */
data class OverallStats(
    val gamesPlayed: Int = 0,
    val gamesWon: Int = 0,
    val losses: Int = 0,
    val bestScore: Int? = null,
    val totalScore: Int = 0,
    val perfectClears: Int = 0,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val winningScoreTotal: Int = 0,
    val losingScoreTotal: Int = 0,
    val longestGameTurns: Int = 0,
    val shortestClearTurns: Int = 0,
    /** Tile number → how many times it was left open at the end of a game. */
    val remainingTileCounts: Map<Int, Int> = emptyMap()
)

class StatsRepository(private val context: Context) {

    private fun bestKey(mode: GameMode) = intPreferencesKey("best_${mode.name}")
    private fun playedKey(mode: GameMode) = intPreferencesKey("played_${mode.name}")
    private fun perfectKey(mode: GameMode) = intPreferencesKey("perfect_${mode.name}")

    private companion object {
        val TOTAL_PLAYED = intPreferencesKey("total_played")
        val TOTAL_WON = intPreferencesKey("total_won")
        val TOTAL_LOST = intPreferencesKey("total_lost")
        val TOTAL_PERFECT = intPreferencesKey("total_perfect")
        val BEST_SCORE = intPreferencesKey("best_score")
        val TOTAL_SCORE = intPreferencesKey("total_score")
        val STREAK_CURRENT = intPreferencesKey("streak_current")
        val STREAK_BEST = intPreferencesKey("streak_best")
        val WIN_SCORE_TOTAL = intPreferencesKey("win_score_total")
        val LOSS_SCORE_TOTAL = intPreferencesKey("loss_score_total")
        val LONGEST_TURNS = intPreferencesKey("longest_turns")
        val SHORTEST_CLEAR_TURNS = intPreferencesKey("shortest_clear_turns")
        val REMAINING_TILES = stringPreferencesKey("remaining_tiles")
    }

    fun statsFor(mode: GameMode): Flow<ModeStats> = context.statsStore.data.map { prefs ->
        ModeStats(
            bestScore = prefs[bestKey(mode)],
            gamesPlayed = prefs[playedKey(mode)] ?: 0,
            perfectGames = prefs[perfectKey(mode)] ?: 0
        )
    }

    val overall: Flow<OverallStats> = context.statsStore.data.map { prefs ->
        OverallStats(
            gamesPlayed        = prefs[TOTAL_PLAYED] ?: 0,
            gamesWon           = prefs[TOTAL_WON] ?: 0,
            losses             = prefs[TOTAL_LOST] ?: 0,
            bestScore          = prefs[BEST_SCORE],
            totalScore         = prefs[TOTAL_SCORE] ?: 0,
            perfectClears      = prefs[TOTAL_PERFECT] ?: 0,
            currentStreak      = prefs[STREAK_CURRENT] ?: 0,
            bestStreak         = prefs[STREAK_BEST] ?: 0,
            winningScoreTotal  = prefs[WIN_SCORE_TOTAL] ?: 0,
            losingScoreTotal   = prefs[LOSS_SCORE_TOTAL] ?: 0,
            longestGameTurns   = prefs[LONGEST_TURNS] ?: 0,
            shortestClearTurns = prefs[SHORTEST_CLEAR_TURNS] ?: 0,
            remainingTileCounts = parseTileCounts(prefs[REMAINING_TILES])
        )
    }

    suspend fun recordResult(result: GameResult) {
        context.statsStore.edit { prefs ->
            val won = result.isPerfect

            // Per-mode
            val modeBest = prefs[bestKey(result.mode)]
            if (modeBest == null || result.score < modeBest) prefs[bestKey(result.mode)] = result.score
            prefs[playedKey(result.mode)] = (prefs[playedKey(result.mode)] ?: 0) + 1

            // Overall
            prefs[TOTAL_PLAYED] = (prefs[TOTAL_PLAYED] ?: 0) + 1
            prefs[TOTAL_SCORE] = (prefs[TOTAL_SCORE] ?: 0) + result.score
            prefs[BEST_SCORE] = minOf(prefs[BEST_SCORE] ?: result.score, result.score)
            prefs[LONGEST_TURNS] = maxOf(prefs[LONGEST_TURNS] ?: 0, result.turns)

            val counts = parseTileCounts(prefs[REMAINING_TILES]).toMutableMap()
            result.remainingTiles.forEach { tile -> counts[tile] = (counts[tile] ?: 0) + 1 }
            prefs[REMAINING_TILES] = formatTileCounts(counts)

            if (won) {
                prefs[TOTAL_WON] = (prefs[TOTAL_WON] ?: 0) + 1
                prefs[WIN_SCORE_TOTAL] = (prefs[WIN_SCORE_TOTAL] ?: 0) + result.score
                if (result.tileScore == 0) {
                    prefs[perfectKey(result.mode)] = (prefs[perfectKey(result.mode)] ?: 0) + 1
                    prefs[TOTAL_PERFECT] = (prefs[TOTAL_PERFECT] ?: 0) + 1
                }
                val streak = (prefs[STREAK_CURRENT] ?: 0) + 1
                prefs[STREAK_CURRENT] = streak
                prefs[STREAK_BEST] = maxOf(prefs[STREAK_BEST] ?: 0, streak)
                val shortest = prefs[SHORTEST_CLEAR_TURNS] ?: 0
                prefs[SHORTEST_CLEAR_TURNS] =
                    if (shortest == 0) result.turns else minOf(shortest, result.turns)
            } else {
                prefs[TOTAL_LOST] = (prefs[TOTAL_LOST] ?: 0) + 1
                prefs[LOSS_SCORE_TOTAL] = (prefs[LOSS_SCORE_TOTAL] ?: 0) + result.score
                prefs[STREAK_CURRENT] = 0
            }
        }
    }

    /** iOS `resetStats()` — clears every counter, including the per-mode bests. */
    suspend fun reset() {
        context.statsStore.edit { it.clear() }
    }

    // iOS stores the histogram as "tile:count,tile:count"; the same shape here keeps the
    // two apps' saved data readable in the same way.
    private fun parseTileCounts(raw: String?): Map<Int, Int> =
        raw.orEmpty().split(',').mapNotNull { pair ->
            val parts = pair.split(':')
            val tile = parts.getOrNull(0)?.toIntOrNull()
            val count = parts.getOrNull(1)?.toIntOrNull()
            if (tile != null && count != null) tile to count else null
        }.toMap()

    private fun formatTileCounts(counts: Map<Int, Int>): String =
        counts.toSortedMap().entries.joinToString(",") { "${it.key}:${it.value}" }
}
