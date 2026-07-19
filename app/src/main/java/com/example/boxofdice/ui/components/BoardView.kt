package com.example.boxofdice.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.example.boxofdice.model.TileState
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.LocalBoardTheme

/**
 * The wooden tray, redrawn to match the iOS board: a walnut frame with a per-theme
 * tint, a deeply recessed felt-dark playfield, a 7° forward rake (so the tray reads
 * as a physical object on the table), and the exact iOS grid geometry — 6 columns
 * (5 for ≤10 tiles), 8dp tile gaps, 11dp row gaps, 2:3 tiles capped at 68dp (104dp
 * on tablets). The board scales proportionally to the width it is given.
 */
@Composable
fun BoardView(
    tiles:       List<TileState>,
    onTileClick: (Int) -> Unit,
    modifier:    Modifier = Modifier
) {
    val theme = LocalBoardTheme.current

    BoxWithConstraints(modifier = modifier, contentAlignment = Alignment.TopCenter) {
        val cols      = DesignTokens.columnsFor(tiles.size)
        val maxTile   = if (maxWidth >= 600.dp) 104.dp else 68.dp
        val frame     = DesignTokens.boardPadding          // 16
        val padH      = DesignTokens.recessPaddingH        // 10
        val padV      = DesignTokens.recessPaddingV        // 16
        val tileGap   = DesignTokens.tileSpacing           // 8
        val rowGap    = DesignTokens.gridSpacing           // 11

        val fixedH = frame * 2 + padH * 2 + tileGap * (cols - 1)
        val rawTile = (maxWidth - fixedH) / cols
        val tileW   = rawTile.coerceIn(28.dp, maxTile)
        val gridW   = tileW * cols + tileGap * (cols - 1)
        val trayW   = gridW + padH * 2 + frame * 2

        Box(
            modifier = Modifier
                .width(trayW)
                .padding(vertical = 5.dp)
                .graphicsLayer {
                    rotationX = DesignTokens.TILE_TILT_DEGREES
                    scaleY = 0.96f
                    cameraDistance = 16f * density
                    transformOrigin = TransformOrigin(0.5f, 0.5f)
                }
                .shadow(22.dp, RoundedCornerShape(DesignTokens.trayCornerRadius), clip = false)
                .clip(RoundedCornerShape(DesignTokens.trayCornerRadius))
        ) {
            // Walnut frame.
            Canvas(Modifier.matchParentSize()) { drawTrayFrame(theme.board) }

            // Recessed playfield + tiles.
            Box(
                modifier = Modifier
                    .padding(frame)
                    .clip(RoundedCornerShape(DesignTokens.recessCornerRadius))
            ) {
                Canvas(Modifier.matchParentSize()) { drawRecess() }

                Column(
                    modifier = Modifier.padding(horizontal = padH, vertical = padV),
                    verticalArrangement = Arrangement.spacedBy(rowGap)
                ) {
                    tiles.chunked(cols).forEach { rowTiles ->
                        Row(horizontalArrangement = Arrangement.spacedBy(tileGap)) {
                            rowTiles.forEach { tile ->
                                TileView(
                                    tile     = tile,
                                    onClick  = { onTileClick(tile.number) },
                                    modifier = Modifier.width(tileW)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// ── Walnut tray frame ───────────────────────────────────────────────────────────

private fun DrawScope.drawTrayFrame(boardColors: List<Color>) {
    val w = size.width
    val h = size.height
    val rad = CornerRadius(28.dp.toPx())

    // Base walnut diagonal gradient.
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(DesignTokens.trayFrame1, DesignTokens.trayFrame2, DesignTokens.trayFrame3, DesignTokens.trayFrame4),
            start = Offset(0f, 0f), end = Offset(w, h)
        ),
        cornerRadius = rad
    )
    // Per-theme board tint.
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf((boardColors.firstOrNull() ?: Color.Transparent).copy(alpha = 0.18f),
                   Color.Transparent, Color.Black.copy(alpha = 0.20f)),
            start = Offset(0f, 0f), end = Offset(w, h)
        ),
        cornerRadius = rad
    )
    // Horizontal woodgrain.
    val grain = Color.Black.copy(alpha = 0.12f)
    var y = h * 0.05f
    while (y < h) {
        drawLine(grain, Offset(w * 0.02f, y), Offset(w * 0.98f, y), strokeWidth = 1f)
        y += h * 0.06f
    }
    // Dark structural rim.
    drawRoundRect(color = DesignTokens.trayRim.copy(alpha = 0.92f), cornerRadius = rad, style = Stroke(width = 7f))
    // Lit bevel rim (top-left bright → bottom-right dark).
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(
                DesignTokens.trayRimHi.copy(alpha = 0.52f),
                Color(red = 0.62f, green = 0.30f, blue = 0.12f).copy(alpha = 0.20f),
                Color.Black.copy(alpha = 0.42f),
                Color.Black.copy(alpha = 0.78f)
            ),
            start = Offset(0f, 0f), end = Offset(w, h)
        ),
        cornerRadius = rad, style = Stroke(width = 4f)
    )
    // Top-left sheen.
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(Color.White.copy(alpha = 0.12f), Color.Transparent),
            start = Offset(0f, 0f), end = Offset(w * 0.42f, h * 0.34f)
        ),
        cornerRadius = rad
    )
    // Bottom-right shadow pool.
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(Color.Transparent, Color.Black.copy(alpha = 0.34f)),
            start = Offset(w * 0.58f, h * 0.58f), end = Offset(w, h)
        ),
        cornerRadius = rad
    )
}

// ── Recessed playfield ──────────────────────────────────────────────────────────

private fun DrawScope.drawRecess() {
    val w = size.width
    val h = size.height
    val rad = CornerRadius(15.dp.toPx())

    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(DesignTokens.recess1, DesignTokens.recess2, DesignTokens.recess3),
            start = Offset(0f, 0f), end = Offset(w, h)
        ),
        cornerRadius = rad
    )
    // Black inset border.
    drawRoundRect(color = Color.Black.copy(alpha = 0.88f), cornerRadius = rad, style = Stroke(width = 5f))
    // Top inner shadow.
    drawRoundRect(
        brush = Brush.verticalGradient(
            colors = listOf(Color.Black.copy(alpha = 0.58f), Color.Transparent),
            startY = 0f, endY = h * 0.30f
        ),
        size = Size(w, h * 0.34f), cornerRadius = rad
    )
    // Bottom-right deep corner.
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(Color.Transparent, Color.Black.copy(alpha = 0.42f)),
            start = Offset(w * 0.55f, h * 0.52f), end = Offset(w, h)
        ),
        cornerRadius = rad
    )
}
