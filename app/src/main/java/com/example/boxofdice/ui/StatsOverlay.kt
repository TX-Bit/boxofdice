package com.example.boxofdice.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxofdice.R
import com.example.boxofdice.data.OverallStats
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.DisplayFont
import com.example.boxofdice.ui.theme.LabelFont
import com.example.boxofdice.ui.theme.LocalBoardTheme

/**
 * Statistics, laid out like the iOS `StatsView`: a 2×2 grid of amber summary cards over
 * four grouped sections — scores, best score per mode, streaks and length, and a bar
 * chart of the tiles most often left open — with a destructive Reset in the leading
 * toolbar slot.
 *
 * Values follow the iOS conventions, except that a best score of 0 — a perfect clear —
 * reads as 0 rather than as "nothing recorded". The iOS side was fixed to match.
 */
@Composable
fun StatsOverlay(
    overall:   OverallStats,
    modeBests: Map<GameMode, Int?>,
    onReset:   () -> Unit,
    onClose:   () -> Unit
) {
    var confirmReset by remember { mutableStateOf(false) }
    val dash = "-"

    ThemedSheet(
        title         = stringResource(R.string.stats_title),
        onClose       = onClose,
        closeLabel    = stringResource(R.string.settings_done),
        leadingLabel  = stringResource(R.string.stats_reset),
        onLeading     = { confirmReset = true },
        leadingDanger = true
    ) {
        Spacer(Modifier.height(8.dp))

        // iOS summaryGrid: two flexible columns, 12pt apart.
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SummaryCard(stringResource(R.string.stats_played), overall.gamesPlayed.toString(), Modifier.weight(1f))
            SummaryCard(stringResource(R.string.stats_won), overall.gamesWon.toString(), Modifier.weight(1f))
        }
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            SummaryCard(stringResource(R.string.stats_lost), overall.losses.toString(), Modifier.weight(1f))
            SummaryCard(
                label = stringResource(R.string.stats_best_score),
                value = overall.bestScore?.toString() ?: dash,
                modifier = Modifier.weight(1f)
            )
        }

        SectionLabel(stringResource(R.string.stats_section_scores))
        GroupCard {
            StatRow(stringResource(R.string.stats_avg_score), average(overall.totalScore, overall.gamesPlayed, dash))
            GroupDivider()
            StatRow(stringResource(R.string.stats_avg_win), average(overall.winningScoreTotal, overall.gamesWon, dash))
            GroupDivider()
            StatRow(stringResource(R.string.stats_avg_loss), average(overall.losingScoreTotal, overall.losses, dash))
            GroupDivider()
            StatRow(stringResource(R.string.stats_perfect_clears), overall.perfectClears.toString())
        }

        SectionLabel(stringResource(R.string.stats_section_by_mode))
        GroupCard {
            val modes = GameMode.entries.filterNot { it.isMultiplayer }
            modes.forEachIndexed { i, mode ->
                if (i > 0) GroupDivider()
                StatRow(mode.label(), modeBests[mode]?.toString() ?: dash)
            }
        }

        SectionLabel(stringResource(R.string.stats_section_streaks))
        GroupCard {
            StatRow(stringResource(R.string.stats_current_streak), overall.currentStreak.toString())
            GroupDivider()
            StatRow(stringResource(R.string.stats_best_streak_row), overall.bestStreak.toString())
            GroupDivider()
            StatRow(stringResource(R.string.stats_longest_game), turnsText(overall.longestGameTurns, dash))
            GroupDivider()
            StatRow(stringResource(R.string.stats_shortest_clear), turnsText(overall.shortestClearTurns, dash))
        }

        SectionLabel(stringResource(R.string.stats_section_remaining))
        GroupCard {
            // iOS keeps the five most common, ties broken by the lower tile number.
            val top = overall.remainingTileCounts.entries
                .sortedWith(compareByDescending<Map.Entry<Int, Int>> { it.value }.thenBy { it.key })
                .take(5)
            if (top.isEmpty()) {
                Text(
                    text = stringResource(R.string.stats_no_data),
                    color = LocalBoardTheme.current.text.copy(alpha = 0.52f),
                    fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = 16.sp,
                    modifier = Modifier.fillMaxWidth().padding(16.dp)
                )
            } else {
                val maxCount = top.first().value
                top.forEachIndexed { i, entry ->
                    if (i > 0) GroupDivider()
                    TileBarRow(tile = entry.key, count = entry.value, maxCount = maxCount)
                }
            }
        }
        Spacer(Modifier.height(8.dp))
    }

    if (confirmReset) {
        ConfirmDialog(
            title      = stringResource(R.string.stats_reset_confirm),
            confirm    = stringResource(R.string.stats_reset),
            cancel     = stringResource(R.string.pass_cancel),
            onConfirm  = { confirmReset = false; onReset() },
            onDismiss  = { confirmReset = false }
        )
    }
}

/** iOS StatCard: the value in the Georgia-ish display face over a small caps label. */
@Composable
private fun SummaryCard(label: String, value: String, modifier: Modifier = Modifier) {
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
            color = Color(red = 0.18f, green = 0.09f, blue = 0.03f),
            fontFamily = DisplayFont, fontWeight = FontWeight.Bold, fontSize = 31.sp,
            maxLines = 1
        )
        Spacer(Modifier.height(5.dp))
        Text(
            text = label.uppercase(),
            color = Color(red = 0.30f, green = 0.14f, blue = 0.04f).copy(alpha = 0.75f),
            fontFamily = LabelFont, fontWeight = FontWeight.Bold,
            fontSize = 10.sp, letterSpacing = 1.1.sp
        )
    }
}

/** iOS TileBarRow: a gold tile chip, a proportional bar and the count. */
@Composable
private fun TileBarRow(tile: Int, count: Int, maxCount: Int) {
    val theme = LocalBoardTheme.current
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(width = 30.dp, height = 26.dp)
                .clip(RoundedCornerShape(7.dp))
                .background(Brush.verticalGradient(listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)))
                .border(0.75.dp, Color.White.copy(alpha = 0.35f), RoundedCornerShape(7.dp)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = tile.toString(),
                color = Color(red = 0.16f, green = 0.07f, blue = 0.02f),
                fontFamily = com.example.boxofdice.ui.theme.AppFont,
                fontWeight = FontWeight.Black, fontSize = 15.sp
            )
        }
        Box(
            modifier = Modifier
                .weight(1f)
                .height(10.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(Color.White.copy(alpha = 0.08f))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction = (count.toFloat() / maxCount.coerceAtLeast(1)).coerceIn(0.06f, 1f))
                    .height(10.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(
                        Brush.horizontalGradient(
                            listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)
                        )
                    )
            )
        }
        Text(
            text = stringResource(R.string.stats_times, count),
            color = theme.text.copy(alpha = 0.72f),
            fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 13.sp,
            textAlign = TextAlign.End,
            modifier = Modifier.width(32.dp)
        )
    }
}

/** iOS `formattedAverage`: one decimal, or a dash when nothing has been recorded. */
private fun average(total: Int, count: Int, dash: String): String =
    if (count <= 0) dash else String.format("%.1f", total.toDouble() / count)

@Composable
private fun turnsText(turns: Int, dash: String): String =
    if (turns == 0) dash else stringResource(R.string.stats_turns, turns)
