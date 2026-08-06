package com.example.boxofdice.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp

/**
 * The iOS `play.fill` symbol: a right-pointing triangle with softly rounded corners.
 *
 * The "▶" character this replaces is drawn by whatever font the system falls back to —
 * usually sharp-cornered, sometimes an emoji, and never sized to sit on the text
 * baseline the way the label beside it expects.
 *
 * Rounding comes from stroking the same path with a round join on top of the fill: the
 * stroke rides half outside the outline, so the corners come back as arcs while the
 * edges stay straight.
 */
@Composable
fun PlayFillIcon(tint: Color, size: Dp) {
    Canvas(modifier = Modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val round = w * 0.26f
        // Inset by the stroke so the rounded shape still fits the requested box, and
        // nudge right: a triangle's visual centre sits behind its geometric one.
        val left = round * 0.5f + w * 0.06f
        val right = w - round * 0.5f
        val top = round * 0.5f + h * 0.04f
        val bottom = h - round * 0.5f - h * 0.04f

        val triangle = Path().apply {
            moveTo(left, top)
            lineTo(right, (top + bottom) / 2f)
            lineTo(left, bottom)
            close()
        }
        drawPath(triangle, tint)
        drawPath(
            path = triangle,
            color = tint,
            style = Stroke(width = round, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )
    }
}
