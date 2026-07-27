package com.example.boxofdice.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.boxofdice.R
import com.example.boxofdice.data.AppSettings
import com.example.boxofdice.model.AppLanguage
import com.example.boxofdice.model.DiceAnimationSpeed
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.AppTheme
import com.example.boxofdice.ui.theme.LabelFont
import com.example.boxofdice.ui.theme.LocalBoardTheme

// ─────────────────────────────────────────────────────────────────────────────
// Settings — a 1:1 port of the iOS `SettingsView` sheet: a large rounded
// full-screen sheet over a dim scrim, a centered title with a big "Done"
// capsule, then two grouped sections (LOOK & FEEL / GAME FLOW). Language,
// Theme and Dice Animation are closed picker rows (value + up/down chevron)
// that open a themed selection dialog; the rest are compact iOS switches.
// ─────────────────────────────────────────────────────────────────────────────

// Dimensions measured from the iOS settings sheet screenshot (pt ≈ dp).
private val SheetCornerRadius   = 28.dp
private val SectionMarginH      = 16.dp
private val CardCornerRadius    = 18.dp
private val RowPaddingH         = 16.dp
private val RowHeight           = 58.dp
private val HeaderHeight        = 84.dp

private enum class SettingsPicker { LANGUAGE, THEME, DICE_ANIMATION }

@Composable
fun SettingsOverlay(
    settings:        AppSettings,
    onTheme:         (AppTheme) -> Unit,
    onLanguage:      (AppLanguage) -> Unit,
    onAnimSpeed:     (DiceAnimationSpeed) -> Unit,
    onSound:         (Boolean) -> Unit,
    onHaptics:       (Boolean) -> Unit,
    onShowHints:     (Boolean) -> Unit,
    onShowDiceTotal: (Boolean) -> Unit,
    onClose:         () -> Unit
) {
    val theme = LocalBoardTheme.current
    var openPicker by remember { mutableStateOf<SettingsPicker?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        // Dim scrim behind the sheet (iOS sheet presentation).
        Box(
            Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.50f))
        )

        // The rounded full-screen sheet, inset inside the system bars.
        Column(
            modifier = Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.systemBars)
                .padding(horizontal = 3.dp)
                .padding(top = 2.dp, bottom = 4.dp)
                .shadow(24.dp, RoundedCornerShape(SheetCornerRadius))
                .clip(RoundedCornerShape(SheetCornerRadius))
                .background(Brush.linearGradient(theme.background))
                .background(
                    Brush.radialGradient(
                        colorStops = arrayOf(
                            0.0f to Color.White.copy(alpha = if (theme.lightSurface) 0.10f else 0.18f),
                            0.7f to Color.Transparent,
                            1.0f to Color.Black.copy(alpha = if (theme.lightSurface) 0.12f else 0.26f)
                        ),
                        center = Offset(0.5f, 0f),
                        radius = 1600f
                    )
                )
        ) {
            SettingsHeader(onClose)

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = SectionMarginH)
                    .padding(bottom = 30.dp)
            ) {
                // ── LOOK & FEEL ────────────────────────────────────────────
                SettingsSectionLabel(stringResource(R.string.settings_section_look))
                SettingsCard {
                    PickerRow(
                        label   = stringResource(R.string.settings_language),
                        value   = settings.language.label(),
                        onClick = { openPicker = SettingsPicker.LANGUAGE }
                    )
                    SettingsDivider()
                    PickerRow(
                        label   = stringResource(R.string.settings_theme),
                        value   = settings.theme.label(),
                        onClick = { openPicker = SettingsPicker.THEME }
                    )
                    SettingsDivider()
                    SwitchRow(stringResource(R.string.settings_haptics), settings.hapticsEnabled, onHaptics)
                    SettingsDivider()
                    SwitchRow(stringResource(R.string.settings_sound), settings.soundEnabled, onSound)
                    SettingsDivider()
                    PickerRow(
                        label   = stringResource(R.string.settings_dice_animation),
                        value   = settings.diceAnimationSpeed.label(),
                        onClick = { openPicker = SettingsPicker.DICE_ANIMATION }
                    )
                }

                Spacer(Modifier.height(32.dp))

                // ── GAME FLOW ──────────────────────────────────────────────
                SettingsSectionLabel(stringResource(R.string.settings_section_flow))
                SettingsCard {
                    SwitchRow(stringResource(R.string.settings_show_hints), settings.showHints, onShowHints)
                    SettingsDivider()
                    SwitchRow(stringResource(R.string.settings_show_dice_total), settings.showDiceTotal, onShowDiceTotal)
                }
            }
        }

        when (openPicker) {
            SettingsPicker.LANGUAGE -> SelectionDialog(
                title     = stringResource(R.string.settings_language),
                options   = AppLanguage.entries,
                selected  = settings.language,
                labelOf   = { it.label() },
                onSelect  = { onLanguage(it); openPicker = null },
                onDismiss = { openPicker = null }
            )
            SettingsPicker.THEME -> SelectionDialog(
                title     = stringResource(R.string.settings_theme),
                options   = AppTheme.entries,
                selected  = settings.theme,
                labelOf   = { it.label() },
                onSelect  = { onTheme(it); openPicker = null },
                onDismiss = { openPicker = null }
            )
            SettingsPicker.DICE_ANIMATION -> SelectionDialog(
                title     = stringResource(R.string.settings_dice_animation),
                options   = DiceAnimationSpeed.entries,
                selected  = settings.diceAnimationSpeed,
                labelOf   = { it.label() },
                onSelect  = { onAnimSpeed(it); openPicker = null },
                onDismiss = { openPicker = null }
            )
            null -> Unit
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: centered title + large "Done" capsule on the trailing edge.
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun SettingsHeader(onClose: () -> Unit) {
    val theme = LocalBoardTheme.current
    // iOS renders the nav title in system ink (black in light appearance); keep
    // that on themes whose sheet top is light enough, fall back to theme text on
    // the truly dark ones where black would vanish.
    val darkSheet = theme.theme == AppTheme.HIGH_CONTRAST ||
        theme.theme == AppTheme.MIDNIGHT ||
        theme.theme == AppTheme.DARK_WALNUT
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(HeaderHeight)
            .padding(horizontal = 16.dp)
    ) {
        Text(
            text       = stringResource(R.string.settings_title),
            color      = if (darkSheet) theme.text else Color.Black.copy(alpha = 0.88f),
            fontFamily = AppFont,
            fontWeight = FontWeight.Bold,
            fontSize   = 22.sp,
            modifier   = Modifier.align(Alignment.Center)
        )
        DoneCapsule(
            label    = stringResource(R.string.settings_done),
            onClick  = onClose,
            modifier = Modifier.align(Alignment.CenterEnd)
        )
    }
}

@Composable
private fun DoneCapsule(label: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val theme = LocalBoardTheme.current
    val shape = RoundedCornerShape(50)
    Box(
        modifier = modifier
            .width(92.dp)
            .height(42.dp)
            .shadow(8.dp, shape, spotColor = Color.Black.copy(alpha = 0.45f))
            .clip(shape)
            // iOS glassy toolbar capsule: light translucent fill, amber label.
            .background(Color.White.copy(alpha = 0.34f))
            .border(1.dp, Color.White.copy(alpha = 0.40f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text       = label,
            color      = theme.accent,
            fontFamily = LabelFont,
            fontWeight = FontWeight.Bold,
            fontSize   = 17.sp
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label / grouped card / divider (iOS `settingsCard`).
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun SettingsSectionLabel(text: String) {
    val theme = LocalBoardTheme.current
    Text(
        text          = text.uppercase(),
        color         = theme.text.copy(alpha = 0.58f),
        fontFamily    = LabelFont,
        fontWeight    = FontWeight.Bold,
        fontSize      = 13.sp,
        letterSpacing = 1.5.sp,
        modifier      = Modifier.padding(start = 6.dp, bottom = 15.dp)
    )
}

@Composable
private fun SettingsCard(content: @Composable ColumnScope.() -> Unit) {
    val shape = RoundedCornerShape(CardCornerRadius)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Color.Black.copy(alpha = 0.22f))
            .border(1.dp, Color.White.copy(alpha = 0.10f), shape),
        content = content
    )
}

@Composable
private fun SettingsDivider() {
    Box(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = RowPaddingH)
            .height(1.dp)
            .background(Color.White.copy(alpha = 0.08f))
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// Rows
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun SettingsRow(
    onClick: (() -> Unit)? = null,
    content: @Composable RowScope.() -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(RowHeight)
            .then(
                if (onClick != null) Modifier.clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication        = null,
                    onClick           = onClick
                ) else Modifier
            )
            .padding(horizontal = RowPaddingH),
        verticalAlignment = Alignment.CenterVertically
    ) { content() }
}

@Composable
private fun RowLabel(text: String, modifier: Modifier = Modifier) {
    val theme = LocalBoardTheme.current
    Text(
        text       = text,
        color      = theme.text.copy(alpha = 0.88f),
        fontFamily = LabelFont,
        fontWeight = FontWeight.SemiBold,
        fontSize   = 18.sp,
        modifier   = modifier
    )
}

/** Closed picker row: label · value · small up/down chevron (iOS menu Picker). */
@Composable
private fun PickerRow(label: String, value: String, onClick: () -> Unit) {
    val theme = LocalBoardTheme.current
    SettingsRow(onClick = onClick) {
        RowLabel(label, Modifier.weight(1f))
        Text(
            text       = value,
            color      = theme.accent,
            fontFamily = LabelFont,
            fontWeight = FontWeight.Bold,
            fontSize   = 18.sp
        )
        Spacer(Modifier.width(6.dp))
        UpDownChevrons(theme.accent)
    }
}

/** The `chevron.up.chevron.down` glyph next to an iOS menu picker's value. */
@Composable
private fun UpDownChevrons(color: Color) {
    Canvas(Modifier.size(width = 11.dp, height = 17.dp)) {
        val w = size.width
        val h = size.height
        val stroke = 1.9.dp.toPx()
        // up chevron
        drawLine(color, Offset(w * 0.08f, h * 0.34f), Offset(w * 0.50f, h * 0.06f), stroke, StrokeCap.Round)
        drawLine(color, Offset(w * 0.50f, h * 0.06f), Offset(w * 0.92f, h * 0.34f), stroke, StrokeCap.Round)
        // down chevron
        drawLine(color, Offset(w * 0.08f, h * 0.66f), Offset(w * 0.50f, h * 0.94f), stroke, StrokeCap.Round)
        drawLine(color, Offset(w * 0.50f, h * 0.94f), Offset(w * 0.92f, h * 0.66f), stroke, StrokeCap.Round)
    }
}

/** Switch row: label + compact iOS-style toggle; the whole row is tappable. */
@Composable
private fun SwitchRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    SettingsRow(onClick = { onChange(!checked) }) {
        RowLabel(label, Modifier.weight(1f))
        IosToggle(checked = checked, onChange = onChange)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker dialog — themed popup listing the options; tapping picks and closes.
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun <T> SelectionDialog(
    title:     String,
    options:   List<T>,
    selected:  T,
    labelOf:   @Composable (T) -> String,
    onSelect:  (T) -> Unit,
    onDismiss: () -> Unit
) {
    val theme = LocalBoardTheme.current
    // Resolve the option labels *before* entering the Dialog: its window root
    // re-provides LocalContext from the activity, which would bypass the
    // AppLocaleProvider language override for anything resolved inside.
    val labels = options.map { labelOf(it) }
    Dialog(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(CardCornerRadius))
                .background(Brush.linearGradient(theme.background.map { it.copy(alpha = 0.98f) }))
                .border(1.5.dp, theme.accent.copy(alpha = 0.25f), RoundedCornerShape(CardCornerRadius))
                .padding(horizontal = 18.dp, vertical = 20.dp)
        ) {
            Text(
                text       = title,
                color      = theme.text,
                fontFamily = AppFont,
                fontWeight = FontWeight.Bold,
                fontSize   = 21.sp,
                modifier   = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(bottom = 14.dp)
            )
            SettingsCard {
                options.forEachIndexed { i, option ->
                    if (i > 0) SettingsDivider()
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp)
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication        = null,
                                onClick           = { onSelect(option) }
                            )
                            .padding(horizontal = 20.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text       = labels[i],
                            color      = if (option == selected) theme.text else theme.text.copy(alpha = 0.72f),
                            fontFamily = LabelFont,
                            fontWeight = if (option == selected) FontWeight.Bold else FontWeight.SemiBold,
                            fontSize   = 19.sp,
                            modifier   = Modifier.weight(1f)
                        )
                        if (option == selected) {
                            Text(
                                text       = "✓",
                                color      = theme.accent,
                                fontWeight = FontWeight.Black,
                                fontSize   = 18.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
