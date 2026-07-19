package com.example.boxofdice.ui.theme

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * A selectable visual palette for the game surface, mirroring the iOS `GameTheme`.
 * Only the dominant surfaces (table background, title, accent, action button) are driven
 * by this so a theme change is immediately visible while the carved tiles stay readable.
 */
enum class AppTheme(val displayName: String) {
    CLASSIC_WOOD("Classic Wood"),
    GREEN_FELT("Green Felt"),
    MIDNIGHT("Midnight"),
    HIGH_CONTRAST("High Contrast"),
    MINIMAL_LIGHT("Minimal Light"),
    DARK_WALNUT("Dark Walnut");
}

/**
 * @param background Three-stop vertical gradient for the table (top, middle, bottom).
 * @param board      Three-stop gradient that tints the wooden tray per theme (iOS parity).
 * @param glow       Warm spotlight behind the board.
 * @param title      Two-stop gradient for large titles.
 * @param text       Primary readable text colour on this background.
 * @param accent     Accent for pills, icons and highlights.
 * @param button     Two-stop gradient for the primary action button.
 * @param onButton   Text colour drawn on [button].
 * @param lightSurface True for light themes so overlays/text flip to dark-on-light.
 */
data class BoardTheme(
    val theme: AppTheme,
    val background: List<Color>,
    val board: List<Color>,
    val glow: Color,
    val title: List<Color>,
    val text: Color,
    val accent: Color,
    val button: List<Color>,
    val onButton: Color,
    val lightSurface: Boolean = false
) {
    companion object {
        fun palette(theme: AppTheme): BoardTheme = when (theme) {
            AppTheme.CLASSIC_WOOD -> BoardTheme(
                theme = theme,
                background = listOf(Color(0.17f, 0.075f, 0.03f), Color(0.36f, 0.18f, 0.07f), Color(0.12f, 0.05f, 0.02f)),
                board = listOf(Color(0.47f, 0.25f, 0.10f), Color(0.72f, 0.43f, 0.20f), Color(0.42f, 0.20f, 0.08f)),
                glow = Color(0.55f, 0.32f, 0.14f),
                title = listOf(Color(1.0f, 0.91f, 0.68f), Color(0.86f, 0.56f, 0.24f)),
                text = Color(1.0f, 0.88f, 0.62f),
                accent = Color(1.0f, 0.82f, 0.37f),
                button = listOf(Color(1.0f, 0.82f, 0.37f), Color(0.88f, 0.50f, 0.12f)),
                onButton = Color(0.22f, 0.11f, 0.02f)
            )
            AppTheme.GREEN_FELT -> BoardTheme(
                theme = theme,
                background = listOf(Color(0.02f, 0.16f, 0.09f), Color(0.08f, 0.36f, 0.20f), Color(0.02f, 0.13f, 0.08f)),
                board = listOf(Color(0.08f, 0.30f, 0.18f), Color(0.13f, 0.46f, 0.27f), Color(0.04f, 0.20f, 0.12f)),
                glow = Color(0.14f, 0.46f, 0.27f),
                title = listOf(Color(0.90f, 1.0f, 0.72f), Color(0.46f, 0.86f, 0.40f)),
                text = Color(0.88f, 1.0f, 0.76f),
                accent = Color(0.86f, 0.74f, 0.34f),
                button = listOf(Color(0.94f, 0.82f, 0.40f), Color(0.64f, 0.46f, 0.14f)),
                onButton = Color(0.10f, 0.20f, 0.06f)
            )
            AppTheme.MIDNIGHT -> BoardTheme(
                theme = theme,
                background = listOf(Color(0.03f, 0.05f, 0.11f), Color(0.10f, 0.12f, 0.24f), Color(0.02f, 0.03f, 0.08f)),
                board = listOf(Color(0.10f, 0.12f, 0.22f), Color(0.20f, 0.23f, 0.42f), Color(0.06f, 0.07f, 0.16f)),
                glow = Color(0.20f, 0.23f, 0.45f),
                title = listOf(Color(0.78f, 0.88f, 1.0f), Color(0.48f, 0.62f, 0.95f)),
                text = Color(0.82f, 0.88f, 1.0f),
                accent = Color(0.55f, 0.70f, 1.0f),
                button = listOf(Color(0.60f, 0.74f, 1.0f), Color(0.32f, 0.42f, 0.84f)),
                onButton = Color(0.04f, 0.06f, 0.16f)
            )
            AppTheme.HIGH_CONTRAST -> BoardTheme(
                theme = theme,
                background = listOf(Color.Black, Color(0.05f, 0.05f, 0.05f), Color.Black),
                board = listOf(Color(0.12f, 0.12f, 0.12f), Color(0.24f, 0.24f, 0.24f), Color(0.06f, 0.06f, 0.06f)),
                glow = Color(0.18f, 0.18f, 0.10f),
                title = listOf(Color.White, Color(1.0f, 0.86f, 0.20f)),
                text = Color.White,
                accent = Color(1.0f, 0.92f, 0.10f),
                button = listOf(Color(1.0f, 0.92f, 0.10f), Color(0.85f, 0.62f, 0.0f)),
                onButton = Color.Black
            )
            AppTheme.MINIMAL_LIGHT -> BoardTheme(
                theme = theme,
                background = listOf(Color(0.92f, 0.91f, 0.88f), Color(0.98f, 0.97f, 0.94f), Color(0.88f, 0.87f, 0.84f)),
                board = listOf(Color(0.70f, 0.62f, 0.50f), Color(0.86f, 0.78f, 0.64f), Color(0.60f, 0.53f, 0.43f)),
                glow = Color(0.86f, 0.78f, 0.64f),
                title = listOf(Color(0.16f, 0.12f, 0.08f), Color(0.46f, 0.32f, 0.14f)),
                text = Color(0.20f, 0.14f, 0.08f),
                accent = Color(0.68f, 0.42f, 0.14f),
                button = listOf(Color(0.95f, 0.70f, 0.32f), Color(0.72f, 0.42f, 0.12f)),
                onButton = Color(0.16f, 0.08f, 0.02f),
                lightSurface = true
            )
            AppTheme.DARK_WALNUT -> BoardTheme(
                theme = theme,
                background = listOf(Color(0.04f, 0.05f, 0.10f), Color(0.08f, 0.10f, 0.18f), Color(0.03f, 0.04f, 0.07f)),
                board = listOf(Color(0.36f, 0.18f, 0.08f), Color(0.54f, 0.30f, 0.13f), Color(0.28f, 0.13f, 0.05f)),
                glow = Color(0.14f, 0.36f, 0.23f),
                title = listOf(Color(0.96f, 0.92f, 0.84f), Color(0.90f, 0.70f, 0.38f)),
                text = Color(0.92f, 0.88f, 0.80f),
                accent = Color(0.42f, 0.68f, 0.94f),
                button = listOf(Color(0.94f, 0.68f, 0.22f), Color(0.76f, 0.40f, 0.10f)),
                onButton = Color(0.16f, 0.09f, 0.02f)
            )
        }
    }
}

/** The active board theme, defaulting to the iOS Green-Felt look. */
val LocalBoardTheme = staticCompositionLocalOf { BoardTheme.palette(AppTheme.GREEN_FELT) }
