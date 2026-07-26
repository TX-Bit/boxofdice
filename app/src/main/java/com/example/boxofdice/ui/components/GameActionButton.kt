package com.example.boxofdice.ui.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxofdice.R
import com.example.boxofdice.model.GamePhase
import com.example.boxofdice.model.GameState
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.LabelFont
import com.example.boxofdice.ui.theme.LocalBoardTheme

/**
 * The primary action zone, redrawn to match the iOS `BoardGameButtonStyle`: a tall
 * amber gradient button (radius 16, white hairline border, carved dark-walnut
 * label). The Confirm state is the same amber but wears a warm gold halo so it
 * reads as the single most important action; an unmatched selection collapses to a
 * flat, non-tappable "Selected N" status card. Hint/Undo sit below as quiet pills.
 * No ripple, no Material button chrome.
 */
@Composable
fun GameActionButton(
    state:      GameState,
    onRoll:     () -> Unit,
    onConfirm:  () -> Unit,
    onHint:     () -> Unit,
    onUndo:     () -> Unit,
    onUndoMove: () -> Unit = {},
    modifier:   Modifier = Modifier
) {
    val theme = LocalBoardTheme.current
    val isSelectionValid = state.selectedTiles.isNotEmpty() && state.selectedSum == state.diceTotal

    val pulse = rememberInfiniteTransition(label = "pulse")
    val pulseAlpha by pulse.animateFloat(
        initialValue = 0.6f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(550), RepeatMode.Reverse),
        label = "pulseAlpha"
    )

    Column(
        modifier            = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(7.dp)
    ) {
        when (state.phase) {
            GamePhase.IDLE -> {
                AmberButton(
                    text     = if (state.hasRolled) stringResource(R.string.btn_roll_again)
                               else stringResource(R.string.btn_roll),
                    leading  = "⚄",
                    maxWidth = 260.dp,
                    onClick  = onRoll
                )
                if (state.canUndo) {
                    QuietPill(text = stringResource(R.string.btn_undo_move), onClick = onUndoMove)
                }
            }

            GamePhase.ROLLING -> {
                Box(
                    modifier = Modifier.height(DesignTokens.mainButtonHeight).alpha(pulseAlpha),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "⚄  " + stringResource(R.string.btn_rolling),
                        color = theme.text.copy(alpha = 0.70f),
                        fontFamily = LabelFont, fontWeight = FontWeight.Bold,
                        fontSize = DesignTokens.buttonTextSize
                    )
                }
            }

            GamePhase.SELECTING -> {
                if (state.selectedTiles.isEmpty()) {
                    Text(
                        text = stringResource(R.string.instr_select),
                        color = theme.text.copy(alpha = 0.80f),
                        fontFamily = LabelFont, fontWeight = FontWeight.Medium, fontSize = 15.sp
                    )
                }
                if (isSelectionValid) {
                    AmberButton(
                        text     = stringResource(R.string.btn_confirm),
                        leading  = null,
                        halo     = true,
                        maxWidth = 280.dp,
                        onClick  = onConfirm
                    )
                } else {
                    SelectedStatusCard(
                        text = stringResource(R.string.btn_selected, state.selectedSum),
                        textColor = theme.text
                    )
                }
                Row(
                    modifier = Modifier.widthIn(max = 280.dp).fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    QuietPill(
                        text = stringResource(R.string.btn_undo),
                        onClick = onUndo,
                        enabled = state.selectedTiles.isNotEmpty(),
                        modifier = Modifier.weight(1f)
                    )
                    QuietPill(
                        text = stringResource(R.string.btn_hint),
                        onClick = onHint,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            GamePhase.GAME_OVER -> { /* overlay handles interaction */ }
        }
    }
}

@Composable
private fun AmberButton(
    text:     String,
    leading:  String?,
    halo:     Boolean = false,
    maxWidth: Dp = 280.dp,
    onClick:  () -> Unit
) {
    val shape = RoundedCornerShape(DesignTokens.cornerRadiusMedium)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .widthIn(max = maxWidth)
            .height(DesignTokens.mainButtonHeight)
            .then(
                if (halo) Modifier
                    .shadow(18.dp, shape, spotColor = DesignTokens.confirmHaloOuter, ambientColor = DesignTokens.confirmHaloOuter)
                    .shadow(7.dp, shape, spotColor = DesignTokens.confirmHaloInner, ambientColor = DesignTokens.confirmHaloInner)
                else Modifier.shadow(11.dp, shape, spotColor = Color.Black.copy(alpha = 0.5f))
            )
            .clip(shape)
            .drawBehind {
                drawRoundRect(
                    brush = Brush.verticalGradient(
                        listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)
                    ),
                    cornerRadius = CornerRadius(DesignTokens.cornerRadiusMedium.toPx())
                )
                drawRoundRect(
                    brush = Brush.verticalGradient(
                        colors = listOf(Color.White.copy(alpha = 0.30f), Color.Transparent),
                        startY = 0f, endY = size.height * 0.5f
                    ),
                    size = Size(size.width, size.height * 0.5f),
                    cornerRadius = CornerRadius(DesignTokens.cornerRadiusMedium.toPx())
                )
            }
            .border(1.dp, Color.White.copy(alpha = 0.34f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (leading != null) {
                Text(leading, color = DesignTokens.buttonLabel, fontWeight = FontWeight.Black, fontSize = 18.sp)
                Text("  ", fontSize = 18.sp)
            }
            Text(
                text = text,
                color = DesignTokens.buttonLabel,
                fontFamily = LabelFont, fontWeight = FontWeight.Black,
                fontSize = DesignTokens.buttonTextSize
            )
        }
    }
}

@Composable
private fun SelectedStatusCard(text: String, textColor: Color) {
    val shape = RoundedCornerShape(13.dp)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(DesignTokens.mainButtonHeight),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .widthIn(max = 280.dp)
                .height(49.dp)
                .clip(shape)
                .background(Color.Black.copy(alpha = 0.18f))
                .border(1.dp, Color.White.copy(alpha = 0.10f), shape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                color = textColor.copy(alpha = 0.72f),
                fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 17.sp
            )
        }
    }
}

@Composable
private fun QuietPill(
    text:     String,
    onClick:  () -> Unit,
    modifier: Modifier = Modifier,
    enabled:  Boolean = true
) {
    val theme = LocalBoardTheme.current
    val shape = RoundedCornerShape(50)
    Box(
        modifier = modifier
            .heightIn(min = 36.dp)
            .clip(shape)
            .background(Color.Black.copy(alpha = 0.06f))
            .border(1.dp, Color.White.copy(alpha = 0.03f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                enabled           = enabled,
                onClick           = onClick
            )
            .padding(horizontal = 15.dp, vertical = 7.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = theme.text.copy(alpha = if (enabled) 0.56f else 0.22f),
            fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 14.sp
        )
    }
}
