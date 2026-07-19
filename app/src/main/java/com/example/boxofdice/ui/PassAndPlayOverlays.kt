package com.example.boxofdice.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxofdice.R
import com.example.boxofdice.model.PassAndPlayState
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.BtnGoldBot
import com.example.boxofdice.ui.theme.BtnGoldTop
import com.example.boxofdice.ui.theme.BtnText
import com.example.boxofdice.ui.theme.GoldPrimary
import com.example.boxofdice.ui.theme.TextGold
import com.example.boxofdice.ui.theme.TextLight
import com.example.boxofdice.ui.theme.TextMuted

// ─────────────────────────────────────────────────────────────────────────────
// Player-count chooser (shown when the Pass & Play card is tapped)
// ─────────────────────────────────────────────────────────────────────────────

@Composable
fun PlayerCountDialog(
    onSelect:  (Int) -> Unit,
    onDismiss: () -> Unit
) {
    ScrimBox(onDismiss = onDismiss) {
        OverlayCard {
            Text(
                text       = stringResource(R.string.pass_title),
                color      = GoldPrimary,
                fontFamily = AppFont, fontWeight = FontWeight.Black, fontSize = 23.sp,
                textAlign  = TextAlign.Center
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text      = stringResource(R.string.pass_how_many),
                color     = TextMuted,
                fontFamily = AppFont,
                fontSize  = 14.sp,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(20.dp))
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                (2..4).forEach { count ->
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(58.dp)
                            .clip(RoundedCornerShape(14.dp))
                            .background(Color(0xFF0C2417).copy(alpha = 0.8f))
                            .border(1.dp, GoldPrimary.copy(alpha = 0.25f), RoundedCornerShape(14.dp))
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication        = null,
                                onClick           = { onSelect(count) }
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text       = "$count",
                            color      = TextGold,
                            fontFamily = AppFont,
                            fontWeight = FontWeight.Bold,
                            fontSize   = 24.sp
                        )
                    }
                }
            }
            Spacer(Modifier.height(16.dp))
            OverlayGhostButton(text = stringResource(R.string.pass_cancel), onClick = onDismiss)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hand-off overlay shown after each player's round
// ─────────────────────────────────────────────────────────────────────────────

@Composable
fun PassAndPlayRoundEndOverlay(
    state:      PassAndPlayState,
    onNext:     () -> Unit,
    onResults:  () -> Unit
) {
    ScrimBox {
        OverlayCard {
            Text(
                text       = stringResource(R.string.pass_player_done, state.currentPlayer),
                color      = GoldPrimary,
                fontFamily = AppFont, fontWeight = FontWeight.Black, fontSize = 23.sp,
                textAlign  = TextAlign.Center
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text      = if (state.isLastPlayer) stringResource(R.string.pass_all_done)
                            else stringResource(R.string.pass_handoff),
                color     = TextMuted,
                fontFamily = AppFont,
                fontSize  = 14.sp,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(20.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.Black.copy(alpha = 0.22f))
                    .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(16.dp))
                    .padding(vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text          = stringResource(R.string.pass_score),
                    color         = TextGold.copy(alpha = 0.72f),
                    fontFamily    = AppFont,
                    fontWeight    = FontWeight.Bold,
                    fontSize      = 12.sp,
                    letterSpacing = 1.8.sp
                )
                Text(
                    text       = "${state.lastScore}",
                    color      = TextLight,
                    fontFamily = AppFont,
                    fontWeight = FontWeight.Black,
                    fontSize   = 56.sp
                )
                Text(
                    text       = stringResource(R.string.pass_lower_better),
                    color      = TextMuted.copy(alpha = 0.7f),
                    fontFamily = AppFont,
                    fontSize   = 12.sp
                )
            }
            Spacer(Modifier.height(20.dp))
            OverlayGoldButton(
                text    = if (state.isLastPlayer) stringResource(R.string.pass_see_results)
                          else stringResource(R.string.pass_next_player),
                onClick = if (state.isLastPlayer) onResults else onNext
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Final ranking overlay
// ─────────────────────────────────────────────────────────────────────────────

@Composable
fun PassAndPlayResultsOverlay(
    state:      PassAndPlayState,
    onNewGame:  () -> Unit,
    onMenu:     () -> Unit
) {
    val ranking = state.ranking
    val winnerScore = ranking.firstOrNull()?.second ?: 0

    ScrimBox {
        OverlayCard {
            Text(
                text       = stringResource(R.string.pass_results),
                color      = GoldPrimary,
                fontFamily = AppFont, fontWeight = FontWeight.Black, fontSize = 30.sp,
                textAlign  = TextAlign.Center
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text      = stringResource(R.string.pass_lowest_wins),
                color     = TextMuted,
                fontFamily = AppFont,
                fontSize  = 14.sp,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(18.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.Black.copy(alpha = 0.22f))
                    .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(16.dp))
            ) {
                ranking.forEachIndexed { index, (player, score) ->
                    val isWinner = index == 0 && score == winnerScore
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text       = "${index + 1}.",
                            color      = if (isWinner) TextGold else TextMuted,
                            fontFamily = AppFont,
                            fontWeight = FontWeight.Bold,
                            fontSize   = 16.sp
                        )
                        Spacer(Modifier.size(12.dp))
                        Text(
                            text       = stringResource(R.string.pass_player_n, player),
                            color      = if (isWinner) TextLight else TextMuted,
                            fontFamily = AppFont,
                            fontWeight = FontWeight.Medium,
                            fontSize   = 16.sp
                        )
                        Spacer(Modifier.weight(1f))
                        Text(
                            text       = stringResource(R.string.pass_points, score),
                            color      = if (isWinner) TextLight else TextMuted,
                            fontFamily = AppFont,
                            fontWeight = FontWeight.Bold,
                            fontSize   = 16.sp
                        )
                        if (isWinner) {
                            Spacer(Modifier.size(8.dp))
                            Text(text = "🏆", fontSize = 16.sp)
                        }
                    }
                }
            }
            Spacer(Modifier.height(22.dp))
            OverlayGoldButton(text = stringResource(R.string.btn_new_game), onClick = onNewGame)
            Spacer(Modifier.height(10.dp))
            OverlayGhostButton(text = stringResource(R.string.btn_menu), onClick = onMenu)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared overlay building blocks
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun ScrimBox(
    onDismiss: (() -> Unit)? = null,
    content:   @Composable () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.75f))
            .then(
                if (onDismiss != null) Modifier.clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication        = null,
                    onClick           = onDismiss
                ) else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}

@Composable
private fun OverlayCard(content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .widthIn(max = 360.dp)
            .fillMaxWidth()
            .padding(horizontal = 28.dp)
            .shadow(24.dp, RoundedCornerShape(24.dp))
            .clip(RoundedCornerShape(24.dp))
            .background(
                Brush.verticalGradient(listOf(Color(0xFF3A2008), Color(0xFF160A03)))
            )
            .border(1.5.dp, GoldPrimary.copy(alpha = 0.30f), RoundedCornerShape(24.dp))
            .padding(26.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        content = content
    )
}

@Composable
private fun OverlayGoldButton(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .shadow(8.dp, RoundedCornerShape(14.dp), spotColor = BtnGoldBot)
            .clip(RoundedCornerShape(14.dp))
            .background(Brush.verticalGradient(listOf(BtnGoldTop, BtnGoldBot)))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text       = text,
            color      = BtnText,
            fontFamily = AppFont,
            fontWeight = FontWeight.Bold,
            fontSize   = 17.sp
        )
    }
}

@Composable
private fun OverlayGhostButton(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(46.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color(0xFF0C2417).copy(alpha = 0.5f))
            .border(1.dp, TextMuted.copy(alpha = 0.30f), RoundedCornerShape(12.dp))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text       = text,
            color      = TextMuted,
            fontFamily = AppFont,
            fontWeight = FontWeight.Medium,
            fontSize   = 15.sp
        )
    }
}
