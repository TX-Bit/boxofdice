package com.example.boxofdice.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
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

/** Aggregate statistics across every mode. */
data class OverallStats(
    val gamesPlayed: Int = 0,
    val perfectClears: Int = 0,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0
)

class StatsRepository(private val context: Context) {

    private fun bestKey(mode: GameMode) = intPreferencesKey("best_${mode.name}")
    private fun playedKey(mode: GameMode) = intPreferencesKey("played_${mode.name}")
    private fun perfectKey(mode: GameMode) = intPreferencesKey("perfect_${mode.name}")

    private companion object {
        val TOTAL_PLAYED = intPreferencesKey("total_played")
        val TOTAL_PERFECT = intPreferencesKey("total_perfect")
        val STREAK_CURRENT = intPreferencesKey("streak_current")
        val STREAK_BEST = intPreferencesKey("streak_best")
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
            gamesPlayed   = prefs[TOTAL_PLAYED] ?: 0,
            perfectClears = prefs[TOTAL_PERFECT] ?: 0,
            currentStreak = prefs[STREAK_CURRENT] ?: 0,
            bestStreak    = prefs[STREAK_BEST] ?: 0
        )
    }

    suspend fun recordResult(result: GameResult) {
        context.statsStore.edit { prefs ->
            val current = prefs[bestKey(result.mode)]
            if (current == null || result.score < current) {
                prefs[bestKey(result.mode)] = result.score
            }
            prefs[playedKey(result.mode)] = (prefs[playedKey(result.mode)] ?: 0) + 1
            prefs[TOTAL_PLAYED] = (prefs[TOTAL_PLAYED] ?: 0) + 1

            if (result.isPerfect) {
                prefs[perfectKey(result.mode)] = (prefs[perfectKey(result.mode)] ?: 0) + 1
                prefs[TOTAL_PERFECT] = (prefs[TOTAL_PERFECT] ?: 0) + 1
                val streak = (prefs[STREAK_CURRENT] ?: 0) + 1
                prefs[STREAK_CURRENT] = streak
                if (streak > (prefs[STREAK_BEST] ?: 0)) prefs[STREAK_BEST] = streak
            } else {
                prefs[STREAK_CURRENT] = 0
            }
        }
    }
}
