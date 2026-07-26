package com.example.boxofdice.ui.components

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.boxofdice.model.TileState
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.DesignTokens.TILE_ASPECT

/**
 * A single physical Shut-the-Box flip tile, redrawn to match the iOS `TileView`
 * pixel-for-pixel: a 2:3 ivory tile with hinge pins, a sharp upper-left bevel, an
 * engraved numeral, a dark bottom thickness strip, and — when selected — a cyan
 * selection ring while the whole tile lifts and grows slightly. Closed tiles flip
 * to a flatter dark-walnut backside that fills the lower 58% of the slot.
 *
 * Everything is drawn from [Canvas] + a single engraved [Text]; no Material chrome,
 * and the click has no ripple so it never reads as an Android button.
 */
@Composable
fun TileView(
    tile:    TileState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Selection lifts (-8dp on iOS) and grows the tile (1.09). Spring matches the
    // iOS `.spring(response: 0.24, dampingFraction: 0.62)`.
    val selScale by animateFloatAsState(
        targetValue   = if (tile.isSelected) 1.09f else 1f,
        animationSpec = spring(dampingRatio = 0.62f, stiffness = Spring.StiffnessMediumLow),
        label         = "tileScale"
    )
    // Physical flap, matching the iOS two-phase animation:
    //  - closing: the numeral fades fast (easeOut 0.07s) while the tile pivots
    //    forward at its bottom hinge with `.spring(response: 0.22, damping: 0.70)`;
    //  - opening: `.interpolatingSpring(stiffness: 270, damping: 20)` stands the
    //    tile back up, then the numeral fades in after a 130ms beat.
    val openT by animateFloatAsState(
        targetValue   = if (tile.isOpen) 1f else 0f,
        animationSpec = if (tile.isOpen) spring(dampingRatio = 0.61f, stiffness = 270f)
                        else spring(dampingRatio = 0.70f, stiffness = 815f),
        label         = "tileOpen"
    )
    val numberAlpha by animateFloatAsState(
        targetValue   = if (tile.isOpen) 1f else 0f,
        animationSpec = if (tile.isOpen) tween(durationMillis = 140, delayMillis = 130)
                        else tween(durationMillis = 70),
        label         = "tileNumber"
    )

    BoxWithConstraints(
        modifier = modifier
            .aspectRatio(1f / TILE_ASPECT)
            .graphicsLayer {
                scaleX = selScale
                scaleY = selScale
                translationY = if (tile.isSelected) -8.dp.toPx() else 0f
            }
            .then(
                if (tile.isOpen) Modifier.clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication        = null,
                    onClick           = onClick
                ) else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        // Numeral size tracks the tile so 1–9 and 10–18 stay visually balanced.
        val numberSize = with(androidx.compose.ui.platform.LocalDensity.current) {
            (maxWidth.toPx() * 0.42f).toSp()
        }
        val showOpenFace = openT > 0.5f

        // The face pivots at its bottom edge (iOS rotation3DEffect, anchor .bottom,
        // -8° when down) and rides the iOS vertical offsets: -3 open, +4 closed.
        Box(
            Modifier
                .fillMaxSize()
                .graphicsLayer {
                    rotationX       = -8f * (1f - openT.coerceIn(0f, 1f))
                    transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 1f)
                    cameraDistance  = 8f * density
                    translationY    = (4.dp.toPx() - 7.dp.toPx() * openT.coerceIn(0f, 1f))
                },
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                if (showOpenFace) drawOpenTile(tile.isSelected)
                else drawClosedTile()
            }

            if (showOpenFace) {
                Text(
                    text  = tile.number.toString(),
                    style = TextStyle(
                        fontFamily = AppFont,
                        fontWeight = FontWeight.Black,
                        fontSize   = numberSize,
                        color      = DesignTokens.tileNumberTop,
                        shadow     = Shadow(
                            color  = Color.White.copy(alpha = 0.55f),
                            offset = Offset(0f, 2f),
                            blurRadius = 0f
                        )
                    ),
                    modifier = Modifier.graphicsLayer {
                        alpha  = numberAlpha.coerceIn(0f, 1f)
                        scaleX = 0.86f + 0.14f * numberAlpha.coerceIn(0f, 1f)
                        scaleY = 0.86f + 0.14f * numberAlpha.coerceIn(0f, 1f)
                    }
                )
            } else {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text  = tile.number.toString(),
                        style = TextStyle(
                            fontFamily = AppFont,
                            fontWeight = FontWeight.Black,
                            fontSize   = numberSize * 0.74f,
                            color      = DesignTokens.closedTileNumber.copy(alpha = 0.45f)
                        ),
                        modifier = Modifier.graphicsLayer { translationY = size.height * 0.16f }
                    )
                }
            }
        }
    }
}

// ── Open ivory tile ───────────────────────────────────────────────────────────

private fun DrawScope.drawOpenTile(isSelected: Boolean) {
    val w = size.width
    val h = size.height
    val r = w * 0.16f   // ≈ iOS 11pt on a 68pt tile

    // Contact shadow under the tile.
    drawRoundRect(
        color        = Color.Black.copy(alpha = 0.30f),
        topLeft      = Offset(w * 0.06f, h * 0.10f),
        size         = Size(w * 0.88f, h * 0.90f),
        cornerRadius = CornerRadius(r)
    )

    // Base warm ivory gradient (selected = warmer gold).
    val base = if (isSelected)
        Brush.verticalGradient(listOf(DesignTokens.tileSelectedColor, DesignTokens.tileSelectedBottom))
    else
        Brush.verticalGradient(listOf(DesignTokens.tileColor, DesignTokens.tileBaseBottom))
    drawRoundRect(brush = base, cornerRadius = CornerRadius(r))

    clipRound(Offset.Zero, size, r) {
        // Directional shading toward bottom-right.
        drawRect(
            Brush.linearGradient(
                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.11f)),
                start  = Offset(w * 0.25f, h * 0.25f),
                end    = Offset(w, h)
            )
        )
        // Lower darkening band — visible edge thickness.
        drawRect(
            Brush.verticalGradient(
                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.20f)),
                startY = h * 0.58f, endY = h
            )
        )
        // Top specular highlight.
        drawRoundRect(
            brush        = Brush.verticalGradient(
                colors = listOf(Color.White.copy(alpha = 0.26f), Color.Transparent),
                startY = 0f, endY = h * 0.26f
            ),
            topLeft      = Offset(w * 0.07f, h * 0.02f),
            size         = Size(w * 0.86f, h * 0.30f),
            cornerRadius = CornerRadius(r * 0.8f)
        )
        // Bottom dark thickness strip.
        drawRoundRect(
            brush = Brush.verticalGradient(
                listOf(Color(red = 0.22f, green = 0.10f, blue = 0.03f),
                       Color(red = 0.10f, green = 0.04f, blue = 0.01f))
            ),
            topLeft      = Offset(w * 0.06f, h - h * 0.055f),
            size         = Size(w * 0.88f, h * 0.05f),
            cornerRadius = CornerRadius(r * 0.4f)
        )
    }

    // Hinge pins near the top corners.
    val pinR = w * 0.035f
    val pinY = h * 0.10f
    listOf(w * 0.16f, w * 0.84f).forEach { px ->
        drawCircle(Color.Black.copy(alpha = 0.35f), pinR, Offset(px, pinY + pinR * 0.4f))
        drawCircle(Color(0.50f, 0.50f, 0.50f).copy(alpha = 0.55f), pinR, Offset(px, pinY))
    }

    // Sharp 2px bevel — bright upper-left, dark lower-right.
    drawRoundRect(
        brush = Brush.linearGradient(
            colors = listOf(
                Color.White.copy(alpha = 0.88f),
                Color.White.copy(alpha = 0.16f),
                Color(red = 0.35f, green = 0.18f, blue = 0.06f).copy(alpha = 0.68f),
                Color(red = 0.14f, green = 0.05f, blue = 0.01f).copy(alpha = 0.95f)
            ),
            start = Offset(0f, 0f), end = Offset(w, h)
        ),
        cornerRadius = CornerRadius(r),
        style = Stroke(width = w * 0.03f)
    )

    // Cyan selection ring + glow.
    if (isSelected) {
        drawRoundRect(
            color        = DesignTokens.selectionGlow.copy(alpha = 0.45f),
            topLeft      = Offset(-w * 0.03f, -h * 0.02f),
            size         = Size(w * 1.06f, h * 1.04f),
            cornerRadius = CornerRadius(r * 1.15f),
            style        = Stroke(width = w * 0.07f)
        )
        drawRoundRect(
            brush = Brush.linearGradient(
                listOf(DesignTokens.selectionRingTop, DesignTokens.selectionRingBottom),
                start = Offset(0f, 0f), end = Offset(w, h)
            ),
            cornerRadius = CornerRadius(r),
            style = Stroke(width = w * 0.045f)
        )
    }
}

// ── Closed walnut backside (fills lower 58% of the slot) ─────────────────────────

private fun DrawScope.drawClosedTile() {
    val w = size.width
    val h = size.height
    val faceH = h * 0.58f
    val top = h - faceH
    val r = w * 0.11f

    clipRound(Offset(0f, top), Size(w, faceH), r) {
        drawRect(
            brush = Brush.linearGradient(
                listOf(DesignTokens.closedTileTop, DesignTokens.closedTileMid, DesignTokens.closedTileBottom),
                start = Offset(0f, top), end = Offset(w, h)
            ),
            topLeft = Offset(0f, top), size = Size(w, faceH)
        )
        // Top inner recess shadow.
        drawRect(
            brush = Brush.verticalGradient(
                colors = listOf(Color.Black.copy(alpha = 0.45f), Color.Transparent),
                startY = top, endY = top + faceH * 0.40f
            ),
            topLeft = Offset(0f, top), size = Size(w, faceH * 0.45f)
        )
        // Bottom edge.
        drawRect(
            brush = Brush.verticalGradient(
                listOf(Color(red = 0.24f, green = 0.11f, blue = 0.035f),
                       Color(red = 0.07f, green = 0.025f, blue = 0.006f))
            ),
            topLeft = Offset(0f, h - faceH * 0.13f), size = Size(w, faceH * 0.13f)
        )
    }
    // Border.
    drawRoundRect(
        brush = Brush.linearGradient(
            listOf(
                Color(red = 0.70f, green = 0.44f, blue = 0.22f).copy(alpha = 0.34f),
                Color.Black.copy(alpha = 0.24f),
                Color.Black.copy(alpha = 0.72f)
            ),
            start = Offset(0f, top), end = Offset(w, h)
        ),
        topLeft = Offset(0f, top), size = Size(w, faceH),
        cornerRadius = CornerRadius(r), style = Stroke(width = w * 0.025f)
    )
}

/** Clip drawing to a rounded-rect region. */
private inline fun DrawScope.clipRound(
    topLeft: Offset,
    size: Size,
    radius: Float,
    crossinline block: DrawScope.() -> Unit
) {
    val path = Path().apply {
        addRoundRect(RoundRect(rect = Rect(topLeft, size), cornerRadius = CornerRadius(radius)))
    }
    clipPath(path) { block() }
}
