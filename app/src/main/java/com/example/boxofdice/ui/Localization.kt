package com.example.boxofdice.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.example.boxofdice.R
import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.MoveRule
import com.example.boxofdice.ui.theme.AppTheme

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
