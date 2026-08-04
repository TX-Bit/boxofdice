package com.example.boxofdice.ui

import android.content.Context
import android.content.ContextWrapper
import android.content.res.AssetManager
import android.content.res.Configuration
import android.content.res.Resources
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.example.boxofdice.R
import com.example.boxofdice.model.AppLanguage
import com.example.boxofdice.model.DiceAnimationSpeed
import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.MoveRule
import com.example.boxofdice.ui.theme.AppTheme
import java.util.Locale

/**
 * Localized display strings for the enums. Enums can't call [stringResource] directly, so the
 * UI maps them here. Keep in sync with the strings.xml resources.
 */

@Composable
fun GameMode.label(): String = stringResource(
    when (this) {
        GameMode.CLASSIC       -> R.string.mode_classic
        GameMode.SPEED_RUN     -> R.string.mode_speed
        GameMode.BIG_BOX       -> R.string.mode_bigbox
        GameMode.BIG_BOX_SPEED -> R.string.mode_bigbox_speed
        GameMode.PASS_AND_PLAY -> R.string.mode_pass
    }
)

@Composable
fun GameMode.descriptionLabel(): String = stringResource(
    when (this) {
        GameMode.CLASSIC       -> R.string.mode_classic_desc
        GameMode.SPEED_RUN     -> R.string.mode_speed_desc
        GameMode.BIG_BOX       -> R.string.mode_bigbox_desc
        GameMode.BIG_BOX_SPEED -> R.string.mode_bigbox_speed_desc
        GameMode.PASS_AND_PLAY -> R.string.mode_pass_desc
    }
)

@Composable
fun DiceMode.label(): String = stringResource(
    when (this) {
        DiceMode.ALWAYS_ALL      -> R.string.dice_always_all
        DiceMode.ONE_DIE_WHEN_LOW -> R.string.dice_one_low
    }
)

@Composable
fun MoveRule.label(): String = stringResource(
    when (this) {
        MoveRule.ANY_COMBINATION  -> R.string.move_any
        MoveRule.ONE_OR_TWO_TILES -> R.string.move_one_two
    }
)

@Composable
fun AppTheme.label(): String = stringResource(
    when (this) {
        AppTheme.CLASSIC_WOOD   -> R.string.theme_classic_wood
        AppTheme.GREEN_FELT     -> R.string.theme_green_felt
        AppTheme.MIDNIGHT       -> R.string.theme_midnight
        AppTheme.HIGH_CONTRAST  -> R.string.theme_high_contrast
        AppTheme.MINIMAL_LIGHT  -> R.string.theme_minimal_light
        AppTheme.DARK_WALNUT    -> R.string.theme_dark_walnut
    }
)

@Composable
fun AppLanguage.label(): String = stringResource(
    when (this) {
        AppLanguage.SYSTEM  -> R.string.lang_system
        AppLanguage.ENGLISH -> R.string.lang_english
        AppLanguage.FINNISH -> R.string.lang_finnish
    }
)

@Composable
fun DiceAnimationSpeed.label(): String = stringResource(
    when (this) {
        DiceAnimationSpeed.SHORT  -> R.string.anim_short
        DiceAnimationSpeed.NORMAL -> R.string.anim_normal
        DiceAnimationSpeed.LONG   -> R.string.anim_long
    }
)

/**
 * Applies the in-app language override (iOS `L10n` / `.environment(\.locale, …)`).
 * [AppLanguage.SYSTEM] leaves the device locale untouched; otherwise every
 * `stringResource` under this provider resolves against the forced locale. The
 * wrapper keeps the activity as the base context so things like `startActivity`
 * still work — only resource lookups are redirected.
 */
@Composable
fun AppLocaleProvider(language: AppLanguage, content: @Composable () -> Unit) {
    val code = language.code
    val base = LocalContext.current
    val baseConfig = LocalConfiguration.current
    // Always wrap in the same provider node (even for SYSTEM) so switching
    // language doesn't change the composition structure and wipe remembered
    // state below (e.g. the open Settings sheet).
    val config = remember(code, baseConfig) {
        if (code == null) baseConfig
        else Configuration(baseConfig).apply { setLocale(Locale.forLanguageTag(code)) }
    }
    val context = remember(code, base, config) {
        if (code == null) base
        else {
            val localized = base.createConfigurationContext(config)
            object : ContextWrapper(base) {
                override fun getResources(): Resources = localized.resources
                override fun getAssets(): AssetManager = localized.assets
            } as Context
        }
    }
    CompositionLocalProvider(
        LocalContext provides context,
        LocalConfiguration provides config,
        content = content
    )
}
