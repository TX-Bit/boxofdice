package com.example.boxofdice.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.googlefonts.Font
import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.unit.sp
import com.example.boxofdice.R

// ── Felt table background ──────────────────────────────────────
val FeltGlow   = Color(0xFF235C3B)   // warm spotlight behind board
val FeltGreen  = Color(0xFF123E27)   // main felt
val FeltMid    = Color(0xFF0C2D1B)
val FeltDark   = Color(0xFF06190E)   // edges / vignette

// ── Wooden tray ────────────────────────────────────────────────
val DarkWalnut = Color(0xFF2C1A0E)
val WalnutHi   = Color(0xFF7A5128)   // top-left highlight
val WalnutMid  = Color(0xFF43280F)
val WalnutLow  = Color(0xFF2A1809)
val WalnutDark = Color(0xFF160A03)   // bottom-right shadow
val TrayWellTop = Color(0xFF09190F)  // recessed inner area
val TrayWellBot = Color(0xFF030B06)
val WoodBrown  = Color(0xFF5D3A1A)
val WoodLight  = Color(0xFF8B5E3C)
val WoodDark   = Color(0xFF1E0E05)

// ── Tiles (raised ivory/gold) ──────────────────────────────────
val TileHi       = Color(0xFFF7E7BA)  // top highlight edge
val TileTop      = Color(0xFFE8C982)
val TileBot      = Color(0xFFC79A4C)
val TileEdge     = Color(0xFF9C7330)  // darker bottom edge
val TileNumber   = Color(0xFF3A2206)
val TileSelTop   = Color(0xFFFFE490)
val TileSelBot   = Color(0xFFF0B23C)
val TileSelGlow  = Color(0xFFFFD24A)
val ClosedTop    = Color(0xFF2B1709)
val ClosedBot    = Color(0xFF150A03)
val ClosedNumber = Color(0xFF5E3E1E)
val BrassPin     = Color(0xFFD8BA78)
val BrassPinDk   = Color(0xFF8A6A36)
// legacy aliases (still referenced in places)
val TileIvory    = TileTop
val TileIvoryDim = TileBot
val TileClosed   = ClosedTop
val TileClosedDk = ClosedBot
val TileSelected = TileSelTop
val TileSelDark  = TileSelBot
val TileTextDark = TileNumber

// ── Text ───────────────────────────────────────────────────────
val TextLight = Color(0xFFF3E9D2)   // warm ivory
val TextMuted = Color(0xFF9FB5A3)   // muted sage green-grey
val TextGold  = Color(0xFFFFD24A)

// ── Buttons & accents ─────────────────────────────────────────
val GoldPrimary  = Color(0xFFFFB23E)
val BtnGoldTop   = Color(0xFFFFC862)
val BtnGoldBot   = Color(0xFFE8881A)
val BtnText      = Color(0xFF3A1E04)
val GoldDark     = Color(0xFFE07814)
val GoldLight    = Color(0xFFFFCE70)
val ConfirmGreen = Color(0xFF3DA85B)
val ConfirmLight = Color(0xFF6FD389)

// ── Dice ───────────────────────────────────────────────────────
val DiceWhite  = Color(0xFFFFFDF6)
val DiceShadow = Color(0xFFDED2B4)
val DicePip    = Color(0xFF1A1A22)

private val GameColors = darkColorScheme(
    primary          = GoldPrimary,
    onPrimary        = Color.Black,
    secondary        = GoldLight,
    onSecondary      = Color.Black,
    background       = FeltGreen,
    onBackground     = TextLight,
    surface          = WalnutMid,
    onSurface        = TextLight,
    surfaceVariant   = Color(0xFF3E2A18),
    onSurfaceVariant = TextMuted
)

/**
 * Font roles mirroring the iOS `GameTypography`. The iOS faces are Apple-proprietary
 * and can't ship in an Android APK, so each role maps to the closest OFL Google Font,
 * loaded as a downloadable font at runtime via Google Play Services — no bundled
 * `.ttf` files:
 *
 *  - iOS `title`  = AmericanTypewriter-Bold      → [TitleFont]  = Special Elite
 *  - iOS `display`= Georgia-Bold                 → [DisplayFont]= Gelasio (metric-compatible Georgia)
 *  - iOS `button`/`label`/`value`/`section`
 *          = AvenirNextCondensed DemiBold/Heavy  → [LabelFont]  = Archivo Narrow
 *  - iOS `tileNumber` = SF Rounded heavy         → [AppFont]    = Fredoka
 *
 * The certificate array `com_google_android_gms_fonts_certs` lives in
 * res/values/font_certs.xml. Before a font finishes downloading the system falls
 * back to a sans-serif so text is never invisible.
 */
private val googleFontProvider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage   = "com.google.android.gms",
    certificates      = R.array.com_google_android_gms_fonts_certs
)

private val fredoka       = GoogleFont("Fredoka")
private val specialElite  = GoogleFont("Special Elite")
private val gelasio       = GoogleFont("Gelasio")
private val archivoNarrow = GoogleFont("Archivo Narrow")

/** Rounded face for tile numerals and general playful text (iOS SF Rounded). */
val AppFont: FontFamily = FontFamily(
    Font(googleFont = fredoka, fontProvider = googleFontProvider, weight = FontWeight.Normal),
    Font(googleFont = fredoka, fontProvider = googleFontProvider, weight = FontWeight.Medium),
    Font(googleFont = fredoka, fontProvider = googleFontProvider, weight = FontWeight.SemiBold),
    Font(googleFont = fredoka, fontProvider = googleFontProvider, weight = FontWeight.Bold)
)

/** Typewriter display face for big result/menu titles (iOS American Typewriter). */
val TitleFont: FontFamily = FontFamily(
    Font(googleFont = specialElite, fontProvider = googleFontProvider, weight = FontWeight.Normal)
)

/** Serif numeral face for the huge final-score figure (iOS Georgia-Bold). */
val DisplayFont: FontFamily = FontFamily(
    Font(googleFont = gelasio, fontProvider = googleFontProvider, weight = FontWeight.Bold)
)

/** Condensed grotesque for buttons, labels, captions and the score row
 *  (iOS Avenir Next Condensed DemiBold/Heavy). */
val LabelFont: FontFamily = FontFamily(
    Font(googleFont = archivoNarrow, fontProvider = googleFontProvider, weight = FontWeight.Medium),
    Font(googleFont = archivoNarrow, fontProvider = googleFontProvider, weight = FontWeight.SemiBold),
    Font(googleFont = archivoNarrow, fontProvider = googleFontProvider, weight = FontWeight.Bold)
)

private val GameTypography = Typography(
    headlineLarge = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Black,
        fontSize = 30.sp,
        letterSpacing = 0.5.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Black,
        fontSize = 23.sp
    ),
    titleLarge = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Bold,
        fontSize = 18.sp
    ),
    titleMedium = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Bold,
        fontSize = 15.sp
    ),
    bodyLarge = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Normal,
        fontSize = 15.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Medium,
        fontSize = 13.sp
    ),
    labelLarge = TextStyle(
        fontFamily = AppFont,
        fontWeight = FontWeight.Bold,
        fontSize = 15.sp,
        letterSpacing = 0.5.sp
    )
)

@Composable
fun GameTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = GameColors,
        typography  = GameTypography,
        content     = content
    )
}
