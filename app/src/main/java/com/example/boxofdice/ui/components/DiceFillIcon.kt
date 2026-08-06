package com.example.boxofdice.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.unit.Dp

/**
 * The iOS `dice.fill` symbol: a die peeking out behind a second one that sits forward
 * and to the bottom-right, carrying the readable five-pip face. A single rounded square
 * — which is what this used to be — reads as a crossed box at the 10dp the mode pill
 * uses, and looks nothing like the icon in the same places on the iOS build.
 *
 * Drawn rather than shipped as a glyph: the die-face characters (⚄) render as a system
 * emoji on some Android builds and as a hollow box on others.
 *
 * The two bodies are separated by a transparent gap punched with [BlendMode.Clear], so
 * the back die stays legible over the amber button and the dark pill alike — a gap
 * filled with any fixed colour would only work on one of them.
 */
@Composable
fun DiceFillIcon(tint: Color, size: Dp) {
    Canvas(modifier = Modifier.size(size)) {
        val s = this.size.width
        val die = s * 0.74f              // both bodies are the same size
        val offset = s - die             // how far the front one is pushed down-right
        val radius = CornerRadius(die * 0.26f)
        val gap = s * 0.07f
        // Pips punch through to the background, as they do in the SF Symbol.
        val hole = Color.Black.copy(alpha = 0.75f)

        drawIntoCanvas { canvas ->
            canvas.saveLayer(Rect(Offset.Zero, this.size), Paint())

            drawRoundRect(
                color = tint,
                topLeft = Offset.Zero,
                size = Size(die, die),
                cornerRadius = radius
            )
            // Clear a slightly inflated silhouette of the front die, then draw it into
            // the hole — that leaves an even gap along the seam.
            drawRoundRect(
                color = Color.Black,
                topLeft = Offset(offset - gap, offset - gap),
                size = Size(die + gap * 2, die + gap * 2),
                cornerRadius = CornerRadius(radius.x + gap),
                blendMode = BlendMode.Clear
            )
            drawRoundRect(
                color = tint,
                topLeft = Offset(offset, offset),
                size = Size(die, die),
                cornerRadius = radius
            )

            val pipR = die * 0.105f
            listOf(0.30f to 0.30f, 0.70f to 0.30f, 0.50f to 0.50f, 0.30f to 0.70f, 0.70f to 0.70f)
                .forEach { (fx, fy) ->
                    drawCircle(
                        color = hole,
                        radius = pipR,
                        center = Offset(offset + die * fx, offset + die * fy)
                    )
                }

            canvas.restore()
        }
    }
}
