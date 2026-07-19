package com.example.boxofdice.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxofdice.R
import com.example.boxofdice.data.AppSettings
import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.MoveRule
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.AppTheme
import com.example.boxofdice.ui.theme.BoardTheme
import com.example.boxofdice.ui.theme.LocalBoardTheme

/**
 * Settings, rebuilt as a full-screen iOS-style themed sheet (matching the iOS
 * `SettingsView`): the active table gradient as the background, a custom header
 * with a centered title and an accent "Done" action, then grouped rounded cards
 * with uppercase section labels. No Material toolbar, list rows, Switch, dialog or
 * default accent — every control is custom-drawn and shares the game's identity.
 */
@Composable
fun SettingsOverlay(
    settings:   AppSettings,
    onTheme:    (AppTheme) -> Unit,
    onDiceMode: (DiceMode) -> Unit,
    onMoveRule: (MoveRule) -> Unit,
    onSound:    (Boolean) -> Unit,
    onHaptics:  (Boolean) -> Unit,
    onClose:    () -> Unit
) {
    ThemedSheet(
        title      = stringResource(R.string.settings_title),
        onClose    = onClose,
        closeLabel = stringResource(R.string.settings_done)
    ) {
        SectionLabel(stringResource(R.string.settings_section_theme))
        GroupCard {
            AppTheme.entries.forEachIndexed { i, theme ->
                if (i > 0) GroupDivider()
                ChoiceRow(
                    label    = theme.label(),
                    selected = settings.theme == theme,
                    swatch   = BoardTheme.palette(theme).accent,
                    onClick  = { onTheme(theme) }
                )
            }
        }

        SectionLabel(stringResource(R.string.settings_section_dice))
        GroupCard {
            DiceMode.entries.forEachIndexed { i, mode ->
                if (i > 0) GroupDivider()
                ChoiceRow(mode.label(), settings.diceMode == mode, onClick = { onDiceMode(mode) })
            }
        }

        SectionLabel(stringResource(R.string.settings_section_moves))
        GroupCard {
            MoveRule.entries.forEachIndexed { i, rule ->
                if (i > 0) GroupDivider()
                ChoiceRow(rule.label(), settings.moveRule == rule, onClick = { onMoveRule(rule) })
            }
        }

        SectionLabel(stringResource(R.string.settings_section_feedback))
        GroupCard {
            ToggleRow(stringResource(R.string.settings_sound), settings.soundEnabled, onSound)
            GroupDivider()
            ToggleRow(stringResource(R.string.settings_haptics), settings.hapticsEnabled, onHaptics)
        }
    }
}

@Composable
private fun ChoiceRow(
    label:    String,
    selected: Boolean,
    swatch:   Color? = null,
    onClick:  () -> Unit
) {
    val theme = LocalBoardTheme.current
    Row(
        modifier = Modifier
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            )
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (swatch != null) {
            Box(
                modifier = Modifier
                    .size(16.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(swatch)
                    .border(1.dp, Color.White.copy(alpha = 0.25f), RoundedCornerShape(4.dp))
            )
            Spacer(Modifier.width(12.dp))
        }
        Text(
            text       = label,
            color      = if (selected) theme.text else theme.text.copy(alpha = 0.70f),
            fontFamily = AppFont,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
            fontSize   = 16.sp,
            modifier   = Modifier.weight(1f)
        )
        if (selected) {
            CheckCircle()
        } else {
            Box(
                Modifier
                    .size(20.dp)
                    .clip(RoundedCornerShape(50))
                    .border(1.5.dp, theme.text.copy(alpha = 0.22f), RoundedCornerShape(50))
            )
        }
    }
}

@Composable
private fun CheckCircle() {
    val theme = LocalBoardTheme.current
    Box(
        modifier = Modifier
            .size(20.dp)
            .clip(RoundedCornerShape(50))
            .background(theme.accent),
        contentAlignment = Alignment.Center
    ) {
        Text("✓", color = Color.Black.copy(alpha = 0.85f), fontSize = 13.sp, fontWeight = FontWeight.Black)
    }
}

@Composable
private fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    val theme = LocalBoardTheme.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text       = label,
            color      = theme.text.copy(alpha = 0.85f),
            fontFamily = AppFont,
            fontWeight = FontWeight.Medium,
            fontSize   = 16.sp,
            modifier   = Modifier.weight(1f)
        )
        IosToggle(checked = checked, onChange = onChange)
    }
}
