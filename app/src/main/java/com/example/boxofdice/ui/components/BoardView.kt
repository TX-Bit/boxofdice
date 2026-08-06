package com.example.boxofdice.ui.components

import android.graphics.BlurMaskFilter
import android.os.Build
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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.boxofdice.model.TileState
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.LocalBoardTheme

/**
 * The wooden tray, redrawn to match the iOS board: a walnut frame with a per-theme
 * tint, a deeply recessed felt-dark playfield, a 7° forward rake (so the tray reads
 * as a physical object on the table), and the exact iOS grid geometry — 6 columns
 * (5 for ≤10 tiles), 8dp tile gaps, 11dp row gaps, 2:3 tiles capped at [maxTileWidth]
 * (iOS passes 68 on iPhone, 104 on iPad). The tray fills whichever of the width and
 * height it is given runs out first.
 */
@Composable
fun BoardView(
    tiles:        List<TileState>,
    onTileClick:  (Int) -> Unit,
    modifier:     Modifier = Modifier,
    maxTileWidth: Dp = 68.dp,
    // iOS `boardView(numberFontSize: 27 * scale)` — one size for every tile, handed
    // down from the layout rather than derived from the tile width.
    numberSize:   Dp = 27.dp
) {
    val theme = LocalBoardTheme.current

    BoxWithConstraints(modifier = modifier, contentAlignment = Alignment.TopCenter) {
        val cols      = DesignTokens.columnsFor(tiles.size)
        val rows      = ((tiles.size + cols - 1) / cols).coerceAtLeast(1)
        val frame     = DesignTokens.boardPadding          // 16
        val padH      = DesignTokens.recessPaddingH        // 10
        val padV      = DesignTokens.recessPaddingV        // 16
        val tileGap   = DesignTokens.tileSpacing           // 8
        val rowGap    = DesignTokens.gridSpacing           // 11

        // iOS `boardSizing(forHeight:width:maxTile:)`: the tile is the smallest of what
        // the width allows, what the height allows and the per-layout cap, so a tray
        // handed spare vertical space grows into it instead of leaving it empty. The
        // trailing 10dp is the tray's own 5dp vertical padding, top and bottom.
        val fixedH = frame * 2 + padH * 2 + tileGap * (cols - 1)
        val fixedV = frame * 2 + padV * 2 + rowGap * (rows - 1) + 10.dp
        val byWidth  = (maxWidth - fixedH) / cols
        // maxHeight is Dp.Infinity when the caller leaves the height unbounded (a
        // scrolling parent), which drops the height term out of the minimum.
        val byHeight = (maxHeight - fixedV) / (rows * DesignTokens.TILE_ASPECT)
        val tileW   = minOf(byWidth, byHeight, maxTileWidth).coerceAtLeast(28.dp)
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
                .trayShadows(DesignTokens.trayCornerRadius)
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
                                    tile       = tile,
                                    onClick    = { onTileClick(tile.number) },
                                    numberSize = numberSize,
                                    modifier   = Modifier.width(tileW)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// ── Tray drop shadows ───────────────────────────────────────────────────────────

/**
 * The tray's two drop shadows, matching the iOS pair exactly:
 *
 *  - `.shadow(black 0.60, radius 22, x 9, y 18)` — the deep pool the tray sits in,
 *    thrown down and to the right by the same light that lifts its top-left bevel;
 *  - `.shadow(black 0.24, radius 5, x 2, y 4)` — a tight contact edge that keeps the
 *    tray from floating above the felt.
 *
 * `Modifier.shadow` cannot express this: it takes a Material elevation rather than a
 * blur radius, and it has no offset at all — which is why the board previously cast a
 * single symmetric shadow. Sitting after `graphicsLayer`, these are drawn inside the
 * tray's 7° rake, so the shadow silhouette is perspective-projected with the tray just
 * as it is on iOS.
 *
 * A hardware-accelerated canvas ignores [BlurMaskFilter] before API 28, where an
 * unblurred offset rectangle would look broken — those devices keep the old elevation
 * shadow instead.
 */
private fun Modifier.trayShadows(cornerRadius: Dp): Modifier =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        drawBehind {
            val radius = cornerRadius.toPx()
            drawBlurredRoundRect(
                shadowColor = Color.Black.copy(alpha = 0.60f),
                cornerRadius = radius,
                sigma = 22.dp.toPx(),
                offsetX = 9.dp.toPx(),
                offsetY = 18.dp.toPx()
            )
            drawBlurredRoundRect(
                shadowColor = Color.Black.copy(alpha = 0.24f),
                cornerRadius = radius,
                sigma = 5.dp.toPx(),
                offsetX = 2.dp.toPx(),
                offsetY = 4.dp.toPx()
            )
        }
    } else {
        shadow(22.dp, RoundedCornerShape(cornerRadius), clip = false)
    }

private fun DrawScope.drawBlurredRoundRect(
    shadowColor:  Color,
    cornerRadius: Float,
    sigma:        Float,
    offsetX:      Float,
    offsetY:      Float
) {
    drawIntoCanvas { canvas ->
        val paint = Paint().asFrameworkPaint()
        paint.isAntiAlias = true
        paint.color = shadowColor.toArgb()
        // A SwiftUI shadow radius *is* the Gaussian sigma, but BlurMaskFilter takes a
        // radius that Skia converts with `sigma = radius * 0.57735 + 0.5` — so invert
        // that instead of passing the iOS number straight through (which would render
        // the shadow far too tight).
        paint.maskFilter = BlurMaskFilter(
            ((sigma - 0.5f) / 0.57735f).coerceAtLeast(0.1f),
            BlurMaskFilter.Blur.NORMAL
        )
        canvas.nativeCanvas.drawRoundRect(
            offsetX,
            offsetY,
            size.width + offsetX,
            size.height + offsetY,
            cornerRadius,
            cornerRadius,
            paint
        )
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
    // Inner bevel line, 8dp in from the rim (iOS inset RoundedRectangle at
    // cornerRadius - 4, lineWidth 2, padding 8).
    val inset8 = 8.dp.toPx()
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(Color.White.copy(alpha = 0.26f), Color.Transparent, Color.Black.copy(alpha = 0.54f)),
            start = Offset(inset8, inset8), end = Offset(w - inset8, h - inset8)
        ),
        topLeft = Offset(inset8, inset8),
        size = Size(w - inset8 * 2f, h - inset8 * 2f),
        cornerRadius = CornerRadius(24.dp.toPx()),
        style = Stroke(width = 2.dp.toPx())
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
    // Front lip along the bottom rail — the tray's near wall catching the light
    // (iOS: an 18pt bar at cornerRadius - 6, inset 10 horizontally, 7 from the base).
    val lipH    = 18.dp.toPx()
    val lipPadH = 10.dp.toPx()
    val lipPadB = 7.dp.toPx()
    drawRoundRect(
        brush = Brush.verticalGradient(
            listOf(
                Color(red = 0.34f, green = 0.14f, blue = 0.045f).copy(alpha = 0.40f),
                Color.Black.copy(alpha = 0.58f)
            )
        ),
        topLeft = Offset(lipPadH, h - lipPadB - lipH),
        size = Size(w - lipPadH * 2f, lipH),
        cornerRadius = CornerRadius(22.dp.toPx())
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
    // Lit rim over it — bright at the top-left, deepening into the far corner, so the
    // playfield reads as carved out of the tray (iOS second strokeBorder, lineWidth 2).
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(
                Color.White.copy(alpha = 0.18f),
                Color.Black.copy(alpha = 0.20f),
                Color.Black.copy(alpha = 0.64f),
                Color.Black.copy(alpha = 0.86f)
            ),
            start = Offset(0f, 0f), end = Offset(w, h)
        ),
        cornerRadius = rad,
        style = Stroke(width = 2.dp.toPx())
    )
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
