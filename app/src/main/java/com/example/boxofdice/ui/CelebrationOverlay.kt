package com.example.boxofdice.ui

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.updateTransition
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

private data class Confetto(
    val xFraction: Float,   // 0..1 horizontal start
    val delay: Float,       // 0..1 fraction of the run before it starts falling
    val drift: Float,       // horizontal drift in fraction of width
    val rotations: Float,   // total spins
    val size: Float,        // px-ish (scaled by canvas)
    val color: Color
)

private val confettiColors = listOf(
    Color(0xFFFFC107), Color(0xFFFF7043), Color(0xFF66BB6A),
    Color(0xFF42A5F5), Color(0xFFEC407A), Color(0xFFFFD54F)
)

/**
 * A one-shot confetti burst rained from the top of the screen, shown when the player
 * clears the board. Purely decorative and non-interactive (does not block touches).
 */
@Composable
fun CelebrationOverlay(pieceCount: Int = 90) {
    val pieces = remember {
        List(pieceCount) {
            Confetto(
                xFraction = Random.nextFloat(),
                delay     = Random.nextFloat() * 0.35f,
                drift     = (Random.nextFloat() - 0.5f) * 0.25f,
                rotations = 1f + Random.nextFloat() * 4f,
                size      = 7f + Random.nextFloat() * 9f,
                color     = confettiColors[Random.nextInt(confettiColors.size)]
            )
        }
    }

    val started: MutableState<Boolean> = remember { mutableStateOf(false) }
    started.value = true
    val transition = updateTransition(targetState = started.value, label = "confetti")
    val progress by transition.animateFloat(
        transitionSpec = { tween(durationMillis = 2600, easing = LinearEasing) },
        label = "progress"
    ) { if (it) 1f else 0f }

    Canvas(modifier = Modifier.fillMaxSize()) {
        val w = size.width
        val h = size.height
        pieces.forEach { c ->
            val local = ((progress - c.delay) / (1f - c.delay)).coerceIn(0f, 1f)
            if (local <= 0f) return@forEach
            val y = local * (h + 60f) - 30f
            val x = c.xFraction * w + sin(local * 6.28f * c.rotations) * c.drift * w
            val alpha = (1f - local * 0.6f).coerceIn(0f, 1f)
            // Draw a small rotating rectangle as a confetto.
            val angle = local * 6.28f * c.rotations
            val hw = c.size / 2f
            val cosA = cos(angle)
            val sinA = sin(angle)
            val corners = listOf(
                Offset(-hw, -hw), Offset(hw, -hw), Offset(hw, hw), Offset(-hw, hw)
            ).map { p ->
                Offset(x + p.x * cosA - p.y * sinA, y + p.x * sinA + p.y * cosA)
            }
            val path = androidx.compose.ui.graphics.Path().apply {
                moveTo(corners[0].x, corners[0].y)
                lineTo(corners[1].x, corners[1].y)
                lineTo(corners[2].x, corners[2].y)
                lineTo(corners[3].x, corners[3].y)
                close()
            }
            drawPath(path, color = c.color.copy(alpha = alpha))
        }
    }
}
