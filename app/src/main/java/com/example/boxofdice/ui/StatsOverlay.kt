package com.example.boxofdice.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxofdice.R
import com.example.boxofdice.data.OverallStats
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.LocalBoardTheme

/**
 * Statistics, rebuilt as a full-screen iOS-style themed sheet (matching the iOS
 * `StatsView`): a 2×2 grid of amber summary cards over grouped stat sections on the
 * active table gradient. No Material list, toolbar or default accent.
 */
@Composable
fun StatsOverlay(
    overall:   OverallStats,
    modeBests: Map<GameMode, Int?>,
    onClose:   () -> Unit
) {
    ThemedSheet(
        title      = stringResource(R.string.stats_title),
        onClose    = onClose,
        closeLabel = stringResource(R.string.settings_done)
    ) {
        Spacer(Modifier.height(8.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard(stringResource(R.string.stats_games), overall.gamesPlayed.toString(), Modifier.weight(1f))
            StatCard(stringResource(R.string.stats_perfect), overall.perfectClears.toString(), Modifier.weight(1f))
        }
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard(stringResource(R.string.stats_streak), overall.currentStreak.toString(), Modifier.weight(1f))
            StatCard(stringResource(R.string.stats_best_streak), overall.bestStreak.toString(), Modifier.weight(1f))
        }

        SectionLabel(stringResource(R.string.stats_best_scores))
        GroupCard {
            val modes = GameMode.entries.filterNot { it.isMultiplayer }
            modes.forEachIndexed { i, mode ->
                if (i > 0) GroupDivider()
                StatRow(
                    label = mode.label(),
                    value = modeBests[mode]?.toString() ?: stringResource(R.string.stats_none)
                )
            }
        }
    }
}

@Composable
private fun StatCard(label: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Brush.verticalGradient(listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)))
            .border(1.dp, Color.White.copy(alpha = 0.40f), RoundedCornerShape(14.dp))
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            color = DesignTokens.buttonLabel,
            fontFamily = AppFont, fontWeight = FontWeight.Black, fontSize = 30.sp
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = label.uppercase(),
            color = DesignTokens.buttonLabel.copy(alpha = 0.75f),
            fontFamily = AppFont, fontWeight = FontWeight.Black,
            fontSize = 10.sp, letterSpacing = 1.1.sp
        )
    }
}
