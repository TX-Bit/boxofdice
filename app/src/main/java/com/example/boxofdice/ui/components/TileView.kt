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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
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
    tile:       TileState,
    onClick:    () -> Unit,
    numberSize: Dp,
    modifier:   Modifier = Modifier
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
        // iOS passes one fixed numeral size (27pt × layout scale) down from the layout
        // rather than deriving it from the tile, which is why its numerals fill a
        // narrow phone's tile so much more than a proportional size would. The cap only
        // bites on screens narrower than an iPhone, where 27dp would overflow "12".
        val tileDensity = LocalDensity.current
        val numberDp = minOf(numberSize, maxWidth * NUMERAL_MAX_TILE_FRACTION)
        val numberPx = with(tileDensity) { numberDp.toPx() }
        val numberFontSize = with(tileDensity) { numberPx.toSp() }
        // The engraving below (outline stroke + hard highlight) is an absolute-pixel
        // effect, not a scale-invariant one: on a 720p phone the numeral lands at
        // ~40px, where a full-strength stroke fills in the counters of 4/6/8/9 and the
        // highlight smears into the fill, so the glyph reads fat and smudged. Both
        // taper below [NUMERAL_FULL_WEIGHT_PX]; larger screens keep the tuned look.
        val engraveScale = (numberPx / NUMERAL_FULL_WEIGHT_PX).coerceIn(0.5f, 1f)
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
                EngravedNumeral(
                    text       = tile.number.toString(),
                    fontSize   = numberFontSize,
                    strokeWidth = numberPx * OPEN_NUMERAL_STROKE * engraveScale,
                    fill       = Brush.verticalGradient(
                        listOf(DesignTokens.tileNumberTop, DesignTokens.tileNumberBottom)
                    ),
                    // iOS carves the numeral with a hard white highlight one point below
                    // — one *point*, so the drop scales with the numeral rather than
                    // sitting at a fixed 2px that swamps a small glyph.
                    shadow     = Shadow(
                        color  = Color.White.copy(alpha = 0.55f * engraveScale),
                        offset = Offset(0f, numberPx * NUMERAL_HIGHLIGHT_OFFSET),
                        blurRadius = 0f
                    ),
                    modifier = Modifier.graphicsLayer {
                        alpha  = numberAlpha.coerceIn(0f, 1f)
                        scaleX = 0.86f + 0.14f * numberAlpha.coerceIn(0f, 1f)
                        scaleY = 0.86f + 0.14f * numberAlpha.coerceIn(0f, 1f)
                    }
                )
            } else {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    EngravedNumeral(
                        text        = tile.number.toString(),
                        fontSize    = numberFontSize * 0.74f,
                        strokeWidth = numberPx * 0.74f * CLOSED_NUMERAL_STROKE * engraveScale,
                        fill        = SolidColor(DesignTokens.closedTileNumber.copy(alpha = 0.45f)),
                        modifier    = Modifier.graphicsLayer { translationY = size.height * 0.16f }
                    )
                }
            }
        }
    }
}

/**
 * iOS draws the numeral in SF Rounded **Heavy** (w800). The closest OFL rounded face
 * we can download — Fredoka — tops out at Bold (w700), and Compose only synthesizes
 * bolding when the resolved font is lighter than w600, so `FontWeight.Black` alone
 * silently renders at 700 and the tiles read thin next to the iOS build. Stroking the
 * glyph outline underneath the fill adds the missing optical weight: half the stroke
 * lands outside the contour, so a stroke of [OPEN_NUMERAL_STROKE] × font size widens
 * each stem by about the step from Bold to Heavy.
 */
@Composable
private fun EngravedNumeral(
    text:        String,
    fontSize:    TextUnit,
    strokeWidth: Float,
    fill:        Brush,
    modifier:    Modifier = Modifier,
    shadow:      Shadow? = null
) {
    val base = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Black,
        fontSize   = fontSize,
        brush      = fill
    )
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Text(
            text  = text,
            style = base.copy(
                drawStyle = Stroke(width = strokeWidth, join = StrokeJoin.Round, cap = StrokeCap.Round),
                shadow    = shadow
            )
        )
        Text(text = text, style = base)
    }
}

/**
 * Stroke width ÷ font size for the open-tile numeral (Bold → Heavy).
 *
 * Half of it lands outside the contour, so this widens each stem by ~2% of the em —
 * about one weight step. The earlier 0.085 was closer to five, which on a phone-sized
 * tile pushed the glyph past Heavy into a blob.
 */
private const val OPEN_NUMERAL_STROKE = 0.055f

/** The closed-tile engraving is faint, so it takes a lighter share of the same trick. */
private const val CLOSED_NUMERAL_STROKE = 0.03f

/**
 * Numeral height in device pixels at which the engraving is drawn at full strength.
 * Roughly what a 68dp tile gives on a 3x phone — the size the effect was tuned at.
 */
private const val NUMERAL_FULL_WEIGHT_PX = 56f

/** Engraved highlight drop ÷ font size — the iOS 1pt offset under a ~28pt numeral. */
private const val NUMERAL_HIGHLIGHT_OFFSET = 0.035f

/**
 * Ceiling on the numeral as a fraction of tile width. iOS lands at ~0.58 on an iPhone,
 * so this only clamps screens narrower than that — where the fixed size would spill a
 * two-digit numeral over the tile edge.
 */
private const val NUMERAL_MAX_TILE_FRACTION = 0.62f

// ── Open ivory tile ───────────────────────────────────────────────────────────

private fun DrawScope.drawOpenTile(isSelected: Boolean) {
    val w = size.width
    val h = size.height
    // iOS hard-codes every one of these in points and never scales them with the tile
    // — an 11pt radius on a 46pt phone tile and on a 104pt iPad tile alike. Deriving
    // them from the tile width instead (0.16 * w and friends) shrank the whole set on
    // a phone, which is what made these tiles read boxier and flatter than the iOS ones.
    val r = 11.dp.toPx()

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
        // Top specular highlight (iOS: 5pt side inset, 2pt from the top, radius 10).
        drawRoundRect(
            brush        = Brush.verticalGradient(
                colors = listOf(Color.White.copy(alpha = 0.26f), Color.Transparent),
                startY = 0f, endY = h * 0.26f
            ),
            topLeft      = Offset(5.dp.toPx(), 2.dp.toPx()),
            size         = Size(w - 10.dp.toPx(), h * 0.30f),
            cornerRadius = CornerRadius(10.dp.toPx())
        )
        // Bottom thickness strip: iOS 5pt tall, 4pt side inset, radius 4, nudged 1 down.
        val stripH = 5.dp.toPx()
        drawRoundRect(
            brush = Brush.verticalGradient(
                listOf(Color(red = 0.22f, green = 0.10f, blue = 0.03f),
                       Color(red = 0.10f, green = 0.04f, blue = 0.01f))
            ),
            topLeft      = Offset(4.dp.toPx(), h - stripH + 1.dp.toPx()),
            size         = Size(w - 8.dp.toPx(), stripH),
            cornerRadius = CornerRadius(4.dp.toPx())
        )
    }

    // Hinge pins: iOS 4pt circles, 5pt in from each side and 4pt down from the top.
    val pinR = 2.dp.toPx()
    val pinY = 4.dp.toPx() + pinR
    val pinInset = 5.dp.toPx() + pinR
    listOf(pinInset, w - pinInset).forEach { px ->
        drawCircle(Color.Black.copy(alpha = 0.35f), pinR, Offset(px, pinY + 1.dp.toPx()))
        drawCircle(Color(0.50f, 0.50f, 0.50f).copy(alpha = 0.55f), pinR, Offset(px, pinY))
    }

    // Sharp 2pt bevel — bright upper-left, dark lower-right. SwiftUI strokeBorder sits
    // wholly inside the shape, so inset by half the width to match.
    val bevel = 2.dp.toPx()
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
        topLeft      = Offset(bevel / 2f, bevel / 2f),
        size         = Size(w - bevel, h - bevel),
        cornerRadius = CornerRadius(r - bevel / 2f),
        style        = Stroke(width = bevel)
    )

    // Cyan selection ring + glow (iOS: 2.5pt border, 9pt cyan shadow).
    if (isSelected) {
        val glow = 9.dp.toPx()
        drawRoundRect(
            color        = DesignTokens.selectionGlow.copy(alpha = 0.45f),
            topLeft      = Offset(-glow / 3f, -glow / 3f),
            size         = Size(w + glow * 2f / 3f, h + glow * 2f / 3f),
            cornerRadius = CornerRadius(r + glow / 3f),
            style        = Stroke(width = glow / 2f)
        )
        val ring = 2.5.dp.toPx()
        drawRoundRect(
            brush = Brush.linearGradient(
                listOf(DesignTokens.selectionRingTop, DesignTokens.selectionRingBottom),
                start = Offset(0f, 0f), end = Offset(w, h)
            ),
            topLeft      = Offset(ring / 2f, ring / 2f),
            size         = Size(w - ring, h - ring),
            cornerRadius = CornerRadius(r - ring / 2f),
            style        = Stroke(width = ring)
        )
    }
}

// ── Closed walnut backside (fills lower 58% of the slot) ─────────────────────────

private fun DrawScope.drawClosedTile() {
    val w = size.width
    val h = size.height
    val faceH = h * 0.58f
    val top = h - faceH
    val r = 7.dp.toPx()   // iOS closedTileFace RoundedRectangle(cornerRadius: 7)

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
        cornerRadius = CornerRadius(r), style = Stroke(width = 1.5.dp.toPx())
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
