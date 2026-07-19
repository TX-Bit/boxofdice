package com.example.boxofdice.ui.components

import android.provider.Settings
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.DicePip
import com.example.boxofdice.ui.theme.DiceShadow
import com.example.boxofdice.ui.theme.DiceWhite
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs

// Warm ivory palette for a physical die
private val IvoryTop  = DiceWhite
private val IvoryMid  = DiceShadow
private val IvoryEdge = Color(0xFFC6B78D)   // darker lower edge
private val DieBorder = Color(0xFFBEB18E)

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point — a row of animated dice
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Renders [dice] as physical-feeling animated dice.
 *
 * The animation is purely visual: the final face of each die always comes from
 * [dice] (the real game result). While [isRolling] is true the faces cycle and
 * the dice toss; when it flips to false they settle on the real values.
 *
 * Side-effect hooks fire once per roll at the container level so repeated rolls
 * stay reliable:
 *  - [onRollStart] — when a roll begins (good place to trigger a roll sound).
 *  - [onSettle]    — when the dice land (sound/analytics); a light haptic also
 *                    fires here automatically.
 *
 * Honors the system "remove animations" setting (animator duration scale = 0):
 * in that case the dice snap straight to their values with no motion.
 */
@Composable
fun DiceView(
    dice: List<Int>,
    isRolling: Boolean,
    modifier: Modifier = Modifier,
    dieSize: Dp = 64.dp,
    onRollStart: () -> Unit = {},
    onSettle: () -> Unit = {}
) {
    val reducedMotion = rememberReducedMotion()
    val haptics = LocalHapticFeedback.current

    // Fire sound/haptic hooks once per roll, decoupled from per-die visuals.
    var wasRolling by remember { mutableStateOf(false) }
    LaunchedEffect(isRolling) {
        if (isRolling) {
            wasRolling = true
            onRollStart()
        } else if (wasRolling) {
            wasRolling = false
            // Wait for the dice to visually touch down before the cue.
            if (!reducedMotion) delay(110L)
            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            onSettle()
        }
    }

    Row(
        modifier              = modifier,
        horizontalArrangement = Arrangement.spacedBy(dieSize * (13f / 108f)),
        verticalAlignment     = Alignment.CenterVertically
    ) {
        dice.forEachIndexed { index, value ->
            AnimatedDice(
                value         = value,
                isRolling     = isRolling,
                size          = dieSize,
                index         = index,
                reducedMotion = reducedMotion
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single animated die (reusable, pure visual)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * One physical-feeling die. Animation state ([oy]/[rot]/[sx]/[sy]/[display]) is
 * entirely local and never feeds back into game state — [value] is the source of
 * truth for the final face.
 *
 * @param index Position in the row; used to give the left/right dice slightly
 *              different timing and spin so they never move identically.
 */
@Composable
fun AnimatedDice(
    value: Int,
    isRolling: Boolean,
    size: Dp,
    index: Int,
    reducedMotion: Boolean = false
) {
    val density = LocalDensity.current
    val sizePx  = with(density) { size.toPx() }
    val up      = sizePx * 0.27f          // toss height

    var display by remember { mutableIntStateOf(value) }
    var hasTossed by remember { mutableStateOf(false) }

    // Motion state
    val oy  = remember { Animatable(0f) }                 // vertical offset (px)
    val rot = remember { Animatable(restAngle(value, index)) }
    val sx  = remember { Animatable(1f) }                 // squash/stretch X
    val sy  = remember { Animatable(1f) }                 // squash/stretch Y

    // ── Rapid temporary faces while rolling (visual only) ──
    LaunchedEffect(isRolling, value, reducedMotion) {
        if (isRolling && !reducedMotion) {
            while (true) {
                display = (1..6).random()
                delay(52L + index * 8L)   // slightly different cadence per die
            }
        } else {
            display = value
        }
    }

    // ── Toss / landing motion ──
    LaunchedEffect(isRolling, reducedMotion) {
        if (reducedMotion) {
            // No motion — sit flat at the resting tilt.
            oy.snapTo(0f); sx.snapTo(1f); sy.snapTo(1f)
            rot.snapTo(restAngle(value, index))
            if (isRolling) hasTossed = true
            return@LaunchedEffect
        }

        if (isRolling) {
            hasTossed = true
            coroutineScope {
                // continuous spin (opposite direction per die), cancelled on settle
                launch {
                    rot.animateTo(
                        targetValue   = rot.value + if (index % 2 == 0) 560f else -560f,
                        animationSpec = tween(700, easing = LinearEasing)
                    )
                }
                // bobbing toss, staggered per die so they don't move identically
                launch {
                    delay(index * 55L)
                    while (true) {
                        oy.animateTo(-up, tween(135, easing = FastOutSlowInEasing))
                        oy.animateTo(0f,  tween(135, easing = FastOutSlowInEasing))
                    }
                }
                // subtle squash/stretch during flight
                launch {
                    while (true) {
                        sy.animateTo(0.93f, tween(150)); sx.animateTo(1.05f, tween(150))
                        sy.animateTo(1.05f, tween(150)); sx.animateTo(0.95f, tween(150))
                    }
                }
            }
        } else if (hasTossed) {
            display = value
            coroutineScope {
                // rotation settles to a gentle resting tilt with a little bounce
                launch {
                    rot.animateTo(
                        restAngle(value, index),
                        spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow)
                    )
                }
                // small hop, then a solid bounce down onto the felt
                launch {
                    oy.animateTo(-up * 0.45f, tween(70, easing = FastOutSlowInEasing))
                    oy.animateTo(0f, spring(dampingRatio = 0.42f, stiffness = 620f))
                }
                // impact squash on landing, then recover
                launch {
                    delay(95L)
                    sx.snapTo(1.16f); sy.snapTo(0.84f)
                    launch { sx.animateTo(1f, spring(dampingRatio = 0.4f, stiffness = 480f)) }
                    sy.animateTo(1f, spring(dampingRatio = 0.4f, stiffness = 480f))
                }
            }
        } else {
            // first composition / idle — sit at rest
            oy.snapTo(0f); sx.snapTo(1f); sy.snapTo(1f)
            rot.snapTo(restAngle(value, index))
        }
    }

    // How far off the ground (0 = grounded, 1 = top of toss) — drives the shadow
    val lift = (abs(oy.value) / up).coerceIn(0f, 1f)

    Box(
        modifier         = Modifier.size(size),
        contentAlignment = Alignment.Center
    ) {
        // ── Contact shadow (grounded, reacts to the bounce) ──
        Canvas(modifier = Modifier.size(size)) {
            val w = this.size.width
            val h = this.size.height
            val sScale = 1f - lift * 0.40f
            // Wide soft halo
            val hw = w * 0.92f * sScale
            val hh = h * 0.20f * sScale
            drawOval(
                color   = Color.Black.copy(alpha = 0.22f * (1f - lift * 0.55f)),
                topLeft = Offset((w - hw) / 2f, h * 0.84f),
                size    = Size(hw, hh)
            )
            // Tight darker core
            val cw = w * 0.66f * sScale
            val ch = h * 0.12f * sScale
            drawOval(
                color   = Color.Black.copy(alpha = 0.30f * (1f - lift * 0.5f)),
                topLeft = Offset((w - cw) / 2f, h * 0.88f),
                size    = Size(cw, ch)
            )
        }

        // ── The die itself ──
        Canvas(
            modifier = Modifier
                .size(size)
                .graphicsLayer {
                    translationY    = oy.value
                    rotationZ       = rot.value
                    scaleX          = sx.value
                    scaleY          = sy.value
                    transformOrigin = TransformOrigin(0.5f, 0.92f)
                }
        ) {
            drawDieFace(display)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/** True when the OS "remove animations" accessibility setting is on. */
@Composable
private fun rememberReducedMotion(): Boolean {
    val context = LocalContext.current
    return remember {
        val scale = Settings.Global.getFloat(
            context.contentResolver,
            Settings.Global.ANIMATOR_DURATION_SCALE,
            1f
        )
        scale == 0f
    }
}

/** Draws a glossy white die face with recessed pit pips, matching the iOS `Dice3DView`. */
private fun DrawScope.drawDieFace(value: Int) {
    val w = size.width
    val h = size.height
    val left   = w * 0.07f
    val top    = h * 0.03f
    val right  = w * 0.93f
    val bottom = h * 0.85f
    val dw = right - left
    val dh = bottom - top
    val r  = dw * 0.22f      // iOS 20pt on a 92pt die
    val tl = Offset(left, top)
    val sz = Size(dw, dh)

    // Near-white body.
    drawRoundRect(color = DesignTokens.dieBody, topLeft = tl, size = sz, cornerRadius = CornerRadius(r))
    // Diagonal sheen (bright top-left → faint shadow bottom-right).
    drawRoundRect(
        brush = Brush.linearGradient(
            colors = listOf(Color.White.copy(alpha = 0.66f),
                            Color(red = 0.97f, green = 0.94f, blue = 0.88f).copy(alpha = 0.20f),
                            Color.Black.copy(alpha = 0.16f)),
            start = Offset(left, top), end = Offset(right, bottom)
        ),
        topLeft = tl, size = sz, cornerRadius = CornerRadius(r)
    )
    // Upper-left specular pool.
    drawRoundRect(
        brush = Brush.radialGradient(
            colors = listOf(Color.White.copy(alpha = 0.86f), Color.White.copy(alpha = 0.18f), Color.Transparent),
            center = Offset(left + dw * 0.28f, top + dh * 0.22f),
            radius = dw * 0.5f
        ),
        topLeft = tl, size = sz, cornerRadius = CornerRadius(r)
    )
    // Bevel edge stroke.
    drawRoundRect(
        brush = Brush.linearGradient(
            colors = listOf(Color.White.copy(alpha = 0.96f), Color.White.copy(alpha = 0.30f),
                            Color(0.50f, 0.50f, 0.50f).copy(alpha = 0.68f),
                            Color(0.34f, 0.34f, 0.34f).copy(alpha = 0.82f)),
            start = Offset(left, top), end = Offset(right, bottom)
        ),
        topLeft = tl, size = sz, cornerRadius = CornerRadius(r), style = Stroke(width = w * 0.024f)
    )

    // Recessed pit pips.
    val pipR = dw * 0.095f
    for ((fx, fy) in pipPositions(value)) {
        val px = left + fx * dw
        val py = top + fy * dh
        // Cast shadow on the face.
        drawCircle(Color.Black.copy(alpha = 0.20f), pipR * 1.30f, Offset(px, py + pipR * 0.18f))
        // Pit base gradient.
        drawCircle(
            brush = Brush.verticalGradient(
                listOf(DesignTokens.diePitTop, DesignTokens.diePitBottom),
                startY = py - pipR, endY = py + pipR
            ),
            radius = pipR, center = Offset(px, py)
        )
        // Lower-rim highlight.
        drawCircle(Color.White.copy(alpha = 0.16f), pipR * 0.40f, Offset(px, py + pipR * 0.35f))
    }
}

/** Deterministic gentle resting tilt so each die settles at its own subtle angle. */
private fun restAngle(value: Int, index: Int): Float =
    (((value * 13 + index * 7) % 11) - 5).toFloat()

// iOS DotsView layout: a 0.25 / 0.5 / 0.75 grid, with 2 and 3 on the anti-diagonal.
private fun pipPositions(value: Int): List<Pair<Float, Float>> = when (value) {
    1 -> listOf(0.50f to 0.50f)
    2 -> listOf(0.75f to 0.25f, 0.25f to 0.75f)
    3 -> listOf(0.75f to 0.25f, 0.50f to 0.50f, 0.25f to 0.75f)
    4 -> listOf(0.25f to 0.25f, 0.75f to 0.25f, 0.25f to 0.75f, 0.75f to 0.75f)
    5 -> listOf(0.25f to 0.25f, 0.75f to 0.25f, 0.50f to 0.50f, 0.25f to 0.75f, 0.75f to 0.75f)
    6 -> listOf(0.25f to 0.25f, 0.75f to 0.25f, 0.25f to 0.50f, 0.75f to 0.50f, 0.25f to 0.75f, 0.75f to 0.75f)
    else -> emptyList()
}
