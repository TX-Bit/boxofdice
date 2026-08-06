package com.example.boxofdice.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Fixed design tokens sampled directly from the iOS "Box of Dice" SwiftUI source
 * (github.com/TX-Bit/boxofdice). Every colour is written with the same
 * `Color(red, green, blue)` float literals SwiftUI uses so the Android port is a
 * byte-for-byte match of the original art direction rather than a re-interpretation.
 *
 * Structural chrome (walnut tray, ivory tiles, amber buttons, dice) is
 * theme-independent on iOS, so those tokens live here as constants. The handful of
 * surfaces that recolour per theme (felt background, title, accent, primary text)
 * are still driven by [BoardTheme]; the single-value tokens below capture the
 * canonical Green-Felt default for spec compliance.
 *
 * NB: these are raw values. Nothing here pulls from `MaterialTheme` — the whole UI
 * is drawn from `Box`, `Canvas`, `Image`, `Text` and these tokens.
 */
object DesignTokens {

    // ── Required named colour tokens (spec) ────────────────────────────────────

    /** Canonical felt table fill (Green-Felt default, mid stop). */
    val backgroundColor       = Color(red = 0.08f, green = 0.36f, blue = 0.20f)

    /** Walnut tray surface — the "board". */
    val boardColor            = Color(red = 0.48f, green = 0.25f, blue = 0.10f)

    /** Open ivory tile base. */
    val tileColor             = Color(red = 1.00f, green = 0.95f, blue = 0.78f)

    /** Selected ivory tile base (warmer gold). */
    val tileSelectedColor     = Color(red = 1.00f, green = 0.97f, blue = 0.62f)

    /** Closed / disabled tile (dark walnut backside). */
    val tileDisabledColor     = Color(red = 0.28f, green = 0.13f, blue = 0.045f)

    /** Primary readable text on themed surfaces (warm ivory). */
    val primaryTextColor      = Color(red = 0.95f, green = 0.91f, blue = 0.80f)

    /** Primary action button gradient — top. */
    val buttonGradientTop     = Color(red = 1.00f, green = 0.82f, blue = 0.37f)

    /** Primary action button gradient — bottom. */
    val buttonGradientBottom  = Color(red = 0.88f, green = 0.50f, blue = 0.12f)

    /** Base drop-shadow colour (alpha applied per use site). */
    val shadowColor           = Color(red = 0f, green = 0f, blue = 0f)

    // ── Required dimension tokens (spec) ───────────────────────────────────────

    val cornerRadiusSmall  = 11.dp   // tiles, dice-pip chips, status cards
    val cornerRadiusMedium = 16.dp   // action buttons, mode cards, list groups
    val cornerRadiusLarge  = 26.dp   // overlay / result cards

    val boardPadding   = 16.dp       // iOS frameThickness — tray frame thickness
    val tileSpacing    = 8.dp        // horizontal gap between tiles
    val diceSize       = 108.dp      // default die edge (phone portrait)
    val mainButtonHeight = 58.dp     // Roll / Confirm button height
    // The action zone changes height as the turn moves from Roll → select → Confirm
    // (instruction line, status card, last-move recap, hint pill). iOS can let it
    // grow because its portrait stack is top-aligned; the Android stack is centred,
    // so the slot is held at the tallest state or the board would bob every turn:
    // instruction 20 + 7 + card 58 + 6 + hint pill 36 + 6 + last-move 18.
    val actionZoneHeight = 152.dp

    // ── Supporting structural tokens (drawn chrome) ────────────────────────────

    // Text colour carved into the open ivory tiles (engraved numeral gradient).
    val tileNumberTop     = Color(red = 0.30f, green = 0.13f, blue = 0.035f)
    val tileNumberBottom  = Color(red = 0.12f, green = 0.045f, blue = 0.012f)
    val tileBaseBottom    = Color(red = 0.84f, green = 0.57f, blue = 0.22f)
    val tileSelectedBottom = Color(red = 0.98f, green = 0.74f, blue = 0.18f)

    // Closed-tile walnut backside gradient.
    val closedTileTop     = Color(red = 0.28f, green = 0.13f, blue = 0.045f)
    val closedTileMid     = Color(red = 0.18f, green = 0.08f, blue = 0.025f)
    val closedTileBottom  = Color(red = 0.10f, green = 0.04f, blue = 0.012f)
    val closedTileNumber  = Color(red = 0.86f, green = 0.68f, blue = 0.46f)

    // Cyan selection ring on a selected tile.
    val selectionRingTop    = Color(red = 0.30f, green = 0.95f, blue = 1.00f)
    val selectionRingBottom = Color(red = 0.08f, green = 0.68f, blue = 0.96f)
    val selectionGlow       = Color(red = 0.18f, green = 0.88f, blue = 1.00f)

    // Walnut tray frame diagonal gradient (top-leading → bottom-trailing).
    val trayFrame1 = Color(red = 0.24f, green = 0.10f, blue = 0.035f)
    val trayFrame2 = Color(red = 0.48f, green = 0.25f, blue = 0.10f)
    val trayFrame3 = Color(red = 0.34f, green = 0.15f, blue = 0.055f)
    val trayFrame4 = Color(red = 0.16f, green = 0.065f, blue = 0.022f)
    val trayRim    = Color(red = 0.13f, green = 0.06f, blue = 0.02f)
    val trayRimHi  = Color(red = 1.00f, green = 0.78f, blue = 0.45f)

    // Recessed inner playfield gradient.
    val recess1 = Color(red = 0.035f, green = 0.030f, blue = 0.026f)
    val recess2 = Color(red = 0.080f, green = 0.055f, blue = 0.035f)
    val recess3 = Color(red = 0.040f, green = 0.032f, blue = 0.028f)

    // Primary button label / amber gradient (carved dark-walnut text).
    val buttonLabel        = Color(red = 0.16f, green = 0.08f, blue = 0.03f)
    val buttonDisabledTop  = Color(red = 0.30f, green = 0.23f, blue = 0.16f)
    val buttonDisabledBot  = Color(red = 0.19f, green = 0.14f, blue = 0.09f)
    val buttonDisabledText = Color(red = 0.92f, green = 0.86f, blue = 0.74f)
    val confirmHaloOuter   = Color(red = 1.00f, green = 0.74f, blue = 0.24f)
    val confirmHaloInner   = Color(red = 1.00f, green = 0.56f, blue = 0.12f)

    // Header corner-icon tint.
    val headerIconTint = Color(red = 1.00f, green = 0.86f, blue = 0.58f)

    // White die body + pip pit.
    val dieBody       = Color(red = 0.99f, green = 0.98f, blue = 0.955f)
    val diePitTop     = Color(red = 0.08f, green = 0.04f, blue = 0.01f)
    val diePitBottom  = Color(red = 0.18f, green = 0.10f, blue = 0.04f)
    val dieInactive   = Color(red = 0.54f, green = 0.40f, blue = 0.20f)

    // ── Board proportions (iOS exact) ──────────────────────────────────────────

    const val TILE_ASPECT          = 1.5f   // height = width * 1.5
    const val TILE_TILT_DEGREES    = 7f     // board 3D rake

    /**
     * iOS `numberFontSize: 27 * scale`, passed into every tile regardless of how wide
     * the tile came out — so a narrow phone gets a numeral filling ~0.58 of the tile
     * where a proportional size would leave it looking undersized.
     */
    const val TILE_NUMBER_SIZE     = 27f
    val gridSpacing      = 11.dp            // vertical gap between tile rows
    val recessPaddingH   = 10.dp           // tile grid → recess wall, horizontal
    val recessPaddingV   = 16.dp           // tile grid → recess wall, vertical
    val trayCornerRadius = 28.dp
    val recessCornerRadius = 15.dp

    /** iOS uses 5 columns for ≤10 tiles, 6 columns otherwise. */
    fun columnsFor(tileCount: Int): Int = if (tileCount > 10) 6 else 5

    // ── Type sizes (iOS pt → sp) ───────────────────────────────────────────────

    val kickerSize    = 10.sp   // "BOX OF DICE"
    val scoreSize     = 23.sp
    val tileNumberSize = 27.sp
    val buttonTextSize = 19.sp
    val displaySize   = 64.sp   // final-score numeral
}
