package com.example.boxofdice.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.MoveRule
import com.example.boxofdice.ui.theme.AppTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.settingsStore by preferencesDataStore(name = "settings")

/** User-configurable game and presentation settings. */
data class AppSettings(
    val theme: AppTheme = AppTheme.GREEN_FELT,
    val diceMode: DiceMode = DiceMode.ALWAYS_ALL,
    val moveRule: MoveRule = MoveRule.ANY_COMBINATION,
    val soundEnabled: Boolean = true,
    val hapticsEnabled: Boolean = true
)

class SettingsRepository(private val context: Context) {

    companion object {
        private val KEY_DEFAULT_MODE = intPreferencesKey("default_mode")
        private val KEY_THEME = stringPreferencesKey("theme")
        private val KEY_DICE_MODE = stringPreferencesKey("dice_mode")
        private val KEY_MOVE_RULE = stringPreferencesKey("move_rule")
        private val KEY_SOUND = booleanPreferencesKey("sound_enabled")
        private val KEY_HAPTICS = booleanPreferencesKey("haptics_enabled")
    }

    val defaultModeIndex: Flow<Int> = context.settingsStore.data.map { prefs ->
        prefs[KEY_DEFAULT_MODE] ?: 0
    }

    val settings: Flow<AppSettings> = context.settingsStore.data.map { prefs ->
        AppSettings(
            theme    = prefs[KEY_THEME]?.let { runCatching { AppTheme.valueOf(it) }.getOrNull() } ?: AppTheme.GREEN_FELT,
            diceMode = prefs[KEY_DICE_MODE]?.let { runCatching { DiceMode.valueOf(it) }.getOrNull() } ?: DiceMode.ALWAYS_ALL,
            moveRule = prefs[KEY_MOVE_RULE]?.let { runCatching { MoveRule.valueOf(it) }.getOrNull() } ?: MoveRule.ANY_COMBINATION,
            soundEnabled   = prefs[KEY_SOUND] ?: true,
            hapticsEnabled = prefs[KEY_HAPTICS] ?: true
        )
    }

    suspend fun setDefaultMode(modeIndex: Int) {
        context.settingsStore.edit { it[KEY_DEFAULT_MODE] = modeIndex }
    }

    suspend fun setTheme(theme: AppTheme) {
        context.settingsStore.edit { it[KEY_THEME] = theme.name }
    }

    suspend fun setDiceMode(mode: DiceMode) {
        context.settingsStore.edit { it[KEY_DICE_MODE] = mode.name }
    }

    suspend fun setMoveRule(rule: MoveRule) {
        context.settingsStore.edit { it[KEY_MOVE_RULE] = rule.name }
    }

    suspend fun setSoundEnabled(enabled: Boolean) {
        context.settingsStore.edit { it[KEY_SOUND] = enabled }
    }

    suspend fun setHapticsEnabled(enabled: Boolean) {
        context.settingsStore.edit { it[KEY_HAPTICS] = enabled }
    }
}
