package com.example.boxofdice.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.boxofdice.ui.components.PlayFillIcon
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.LabelFont
import com.example.boxofdice.ui.theme.LocalBoardTheme

// ─────────────────────────────────────────────────────────────────────────────
// Shared iOS "sheet" chrome — full-screen themed menus with grouped cards.
// Mirrors ThemedSheetBackground / settingsCard / section() from the iOS app.
// Nothing here uses a Material toolbar, list, AlertDialog, FAB or default accent.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * A full-screen menu sheet painted with the active theme's background gradient and
 * the same warm top-light → dark-edge radial wash the iOS sheets use, with a custom
 * header (centered title + optional leading/trailing text actions) and a scrolling
 * content column. This replaces the old floating dark-green card so every menu
 * carries the exact visual identity of the game table.
 */
@Composable
fun ThemedSheet(
    title:        String,
    onClose:      () -> Unit,
    /** Trailing action label; null leaves the slot empty (iOS mode sheet: Cancel only). */
    closeLabel:   String?,
    leadingLabel: String? = null,
    onLeading:    (() -> Unit)? = null,
    leadingDanger: Boolean = false,
    content:      @Composable ColumnScope.() -> Unit
) {
    val theme = LocalBoardTheme.current
    Box(modifier = Modifier.fillMaxSize()) {
        // Themed background (linear theme gradient + radial spotlight).
        Canvas(Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height
            drawRect(
                brush = Brush.linearGradient(
                    colors = theme.background,
                    start  = Offset(0f, 0f),
                    end    = Offset(w, h)
                )
            )
            drawRect(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0.0f to Color.White.copy(alpha = if (theme.lightSurface) 0.10f else 0.18f),
                        0.7f to Color.Transparent,
                        1.0f to Color.Black.copy(alpha = if (theme.lightSurface) 0.12f else 0.30f)
                    ),
                    center = Offset(w * 0.5f, 0f),
                    radius = maxOf(w, h)
                )
            )
        }

        // The painted background stays full-bleed; only the chrome is inset, so the
        // sheet header clears the status bar the way the iOS sheets do.
        Column(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing)) {
            SheetHeader(
                title         = title,
                closeLabel    = closeLabel,
                onClose       = onClose,
                leadingLabel  = leadingLabel,
                onLeading     = onLeading,
                leadingDanger = leadingDanger
            )
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 18.dp)
                    .padding(top = 8.dp, bottom = 36.dp),
                content = content
            )
        }
    }
}

@Composable
private fun SheetHeader(
    title:         String,
    closeLabel:    String?,
    onClose:       () -> Unit,
    leadingLabel:  String?,
    onLeading:     (() -> Unit)?,
    leadingDanger: Boolean
) {
    val theme = LocalBoardTheme.current
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .padding(horizontal = 16.dp)
    ) {
        if (leadingLabel != null && onLeading != null) {
            TextAction(
                text     = leadingLabel,
                color    = if (leadingDanger) Color(0.90f, 0.30f, 0.26f) else theme.accent,
                onClick  = onLeading,
                modifier = Modifier.align(Alignment.CenterStart)
            )
        }
        Text(
            text       = title,
            color      = theme.text,
            fontFamily = AppFont,
            fontWeight = FontWeight.Black,
            fontSize   = 17.sp,
            modifier   = Modifier.align(Alignment.Center)
        )
        if (closeLabel != null) {
            TextAction(
                text     = closeLabel,
                color    = theme.accent,
                bold     = true,
                onClick  = onClose,
                modifier = Modifier.align(Alignment.CenterEnd)
            )
        }
    }
}

@Composable
fun TextAction(
    text:     String,
    color:    Color,
    onClick:  () -> Unit,
    modifier: Modifier = Modifier,
    bold:     Boolean = false
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            )
            .padding(horizontal = 6.dp, vertical = 6.dp)
    ) {
        Text(
            text       = text,
            color      = color,
            fontFamily = AppFont,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Medium,
            fontSize   = 16.sp
        )
    }
}

/**
 * Uppercase section label sitting above a [GroupCard], matching iOS `section()` —
 * AvenirNextCondensed-Heavy, which is [LabelFont] here, not the rounded tile face.
 */
@Composable
fun SectionLabel(text: String) {
    val theme = LocalBoardTheme.current
    Text(
        text          = text.uppercase(),
        color         = theme.text.copy(alpha = 0.58f),
        fontFamily    = LabelFont,
        fontWeight    = FontWeight.Bold,
        fontSize      = 12.sp,
        letterSpacing = 1.3.sp,
        modifier      = Modifier.padding(start = 4.dp, top = 18.dp, bottom = 8.dp)
    )
}

/** Grouped rounded card (black 22% fill, hairline white border). */
@Composable
fun GroupCard(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(DesignTokens.cornerRadiusMedium))
            .background(Color.Black.copy(alpha = 0.22f))
            .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(DesignTokens.cornerRadiusMedium)),
        content = content
    )
}

/** Hairline divider used between rows inside a [GroupCard]. */
@Composable
fun GroupDivider() {
    Box(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(1.dp)
            .background(Color.White.copy(alpha = 0.08f))
    )
}

/** Custom amber on/off toggle drawn from Canvas — no Material Switch, no ripple. */
@Composable
fun IosToggle(checked: Boolean, onChange: (Boolean) -> Unit) {
    val theme = LocalBoardTheme.current
    val t by animateFloatAsState(if (checked) 1f else 0f, label = "toggle")
    Canvas(
        modifier = Modifier
            .size(width = 50.dp, height = 30.dp)
            .clip(RoundedCornerShape(50))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = { onChange(!checked) }
            )
    ) {
        val h = size.height
        val r = h / 2f
        // iOS off-state: a dark grey track. A faint stroke keeps it readable on
        // the equally dark grouped cards without lightening the fill.
        val track = lerp(Color.Black.copy(alpha = 0.34f), theme.accent, t)
        drawRoundRect(color = track, cornerRadius = CornerRadius(r))
        drawRoundRect(
            color = Color.White.copy(alpha = 0.16f * (1f - t)),
            cornerRadius = CornerRadius(r),
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 1.dp.toPx())
        )
        val knobR = r - 3.dp.toPx()
        val cx = r + t * (size.width - h)
        drawCircle(Color.White, knobR, Offset(cx, r))
    }
}

/**
 * Full-width amber sheet button (Start Game / primary), iOS `ModeStartButtonStyle`.
 * [leadingPlay] draws the iOS `play.fill` glyph ahead of the label, 10dp apart.
 */
@Composable
fun SheetPrimaryButton(text: String, leadingPlay: Boolean = false, onClick: () -> Unit) {
    val shape = RoundedCornerShape(DesignTokens.cornerRadiusMedium)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(DesignTokens.mainButtonHeight)
            .clip(shape)
            .background(Brush.verticalGradient(listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)))
            .border(1.dp, Color.White.copy(alpha = 0.32f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        // iOS startButton: HStack(spacing: 10) { play.fill 16pt; label button(19) }.
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(if (leadingPlay) 10.dp else 0.dp)
        ) {
            if (leadingPlay) {
                PlayFillIcon(tint = DesignTokens.buttonLabel, size = 16.dp)
            }
            Text(
                text = text,
                color = DesignTokens.buttonLabel,
                fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = 19.sp
            )
        }
    }
}

/** Centered overlay card (handoff / results) with the iOS walnut card styling. */
@Composable
fun CenteredCard(content: @Composable ColumnScope.() -> Unit) {
    val theme = LocalBoardTheme.current
    Box(
        modifier = Modifier.fillMaxSize().padding(horizontal = 28.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 350.dp)
                .fillMaxWidth()
                .clip(RoundedCornerShape(DesignTokens.cornerRadiusLarge))
                .background(Brush.linearGradient(theme.background.map { it.copy(alpha = 0.97f) }))
                .border(1.5.dp, theme.accent.copy(alpha = 0.25f), RoundedCornerShape(DesignTokens.cornerRadiusLarge))
                .padding(horizontal = 26.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(0.dp),
            content = content
        )
    }
}

/** Section/value row used by the Stats sheet. */
@Composable
fun StatRow(label: String, value: String) {
    val theme = LocalBoardTheme.current
    androidx.compose.foundation.layout.Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            color = theme.text.copy(alpha = 0.82f),
            fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = 16.sp
        )
        androidx.compose.foundation.layout.Spacer(Modifier.weight(1f))
        Text(
            text = value,
            color = theme.text,
            fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 16.sp,
            textAlign = TextAlign.End
        )
    }
}
/**
 * Destructive confirmation, standing in for the iOS `confirmationDialog`: a themed
 * card over a scrim with the dangerous action in red. No Material AlertDialog, whose
 * chrome would be the one Android-looking surface in an otherwise iOS-shaped app.
 */
@Composable
fun ConfirmDialog(
    title:     String,
    confirm:   String,
    cancel:    String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    val theme = LocalBoardTheme.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.62f))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onDismiss
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 320.dp)
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .clip(RoundedCornerShape(DesignTokens.cornerRadiusLarge))
                .background(Brush.verticalGradient(theme.background.map { it.copy(alpha = 0.98f) }))
                .border(1.dp, Color.White.copy(alpha = 0.14f), RoundedCornerShape(DesignTokens.cornerRadiusLarge))
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication        = null,
                    onClick           = {}
                )
                .padding(horizontal = 22.dp, vertical = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text       = title,
                color      = theme.text,
                fontFamily = LabelFont,
                fontWeight = FontWeight.Bold,
                fontSize   = 17.sp,
                textAlign  = TextAlign.Center
            )
            androidx.compose.foundation.layout.Spacer(Modifier.height(18.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                DialogButton(
                    text     = cancel,
                    color    = theme.text.copy(alpha = 0.80f),
                    onClick  = onDismiss,
                    modifier = Modifier.weight(1f)
                )
                DialogButton(
                    text     = confirm,
                    color    = Color(0.90f, 0.30f, 0.26f),
                    onClick  = onConfirm,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun DialogButton(
    text:     String,
    color:    Color,
    onClick:  () -> Unit,
    modifier: Modifier = Modifier
) {
    val shape = RoundedCornerShape(12.dp)
    Box(
        modifier = modifier
            .height(44.dp)
            .clip(shape)
            .background(Color.White.copy(alpha = 0.07f))
            .border(1.dp, Color.White.copy(alpha = 0.10f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = color,
            fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 16.sp
        )
    }
}
