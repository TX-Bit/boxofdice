package com.example.boxofdice.ui

import android.content.Intent
import android.content.res.Configuration
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.lerp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import com.example.boxofdice.R
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.GamePhase
import com.example.boxofdice.model.GameResult
import com.example.boxofdice.model.GameState
import com.example.boxofdice.ui.components.BoardView
import com.example.boxofdice.ui.components.Dice3DView
import com.example.boxofdice.ui.components.DiceFillIcon
import com.example.boxofdice.ui.components.DiceSurface
import com.example.boxofdice.ui.components.DiceView
import com.example.boxofdice.ui.components.GameActionButton
import com.example.boxofdice.ui.theme.AppFont
import com.example.boxofdice.ui.theme.DesignTokens
import com.example.boxofdice.ui.theme.DisplayFont
import com.example.boxofdice.ui.theme.LabelFont
import com.example.boxofdice.ui.theme.LocalBoardTheme
import com.example.boxofdice.ui.theme.TitleFont
import com.example.boxofdice.viewmodel.GameViewModel

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

/** iOS: celebration 0.45s after a won game, result card 0.7s / 1.5s after game over. */
private const val CELEBRATION_DELAY_MS = 450L
private const val PERFECT_RESULT_DELAY_MS = 700L
private const val RESULT_DELAY_MS = 1_500L

@Composable
fun GameScreen(viewModel: GameViewModel) {
    val gameState   by viewModel.gameState.collectAsStateWithLifecycle()
    val gameResult  by viewModel.gameResult.collectAsStateWithLifecycle()
    val passAndPlay by viewModel.passAndPlay.collectAsStateWithLifecycle()
    val settings    by viewModel.settings.collectAsStateWithLifecycle()
    val overall     by viewModel.overallStats.collectAsStateWithLifecycle()
    val modeBests   by viewModel.modeBestScores.collectAsStateWithLifecycle()

    var showSettings    by remember { mutableStateOf(false) }
    var showStats       by remember { mutableStateOf(false) }
    var showModeSelect  by remember { mutableStateOf(false) }

    val lastResult = remember { mutableStateOf<GameResult?>(null) }
    gameResult?.let { lastResult.value = it }

    // Snapshot the still-open tiles for the result card (iOS "Remaining Open
    // Tiles" chips). Read from the live GameState — no game-logic change needed —
    // and remembered so the card keeps its content during the exit animation.
    val lastRemaining = remember { mutableStateOf<List<Int>>(emptyList()) }
    if (gameResult != null) {
        gameState?.let { s ->
            lastRemaining.value = s.tiles.filter { it.isOpen }.map { it.number }
        }
    }

    val pap = passAndPlay
    val playerLabel = pap?.let { "PLAYER ${it.currentPlayer} OF ${it.playerCount}" }

    // iOS `presentEndOfGame` holds the result card back so the final board — the last
    // tile going down, the dice that ended it — is still on screen for a beat before
    // anything covers it: 0.7s after a perfect clear (the celebration is already
    // running by then) and 1.5s after an ordinary game over.
    var showGameOver    by remember { mutableStateOf(false) }
    var showCelebration by remember { mutableStateOf(false) }
    LaunchedEffect(gameResult) {
        val result = gameResult
        if (result == null) {
            showGameOver = false
            showCelebration = false
            return@LaunchedEffect
        }
        if (result.isPerfect) {
            delay(CELEBRATION_DELAY_MS)
            showCelebration = true
            delay(PERFECT_RESULT_DELAY_MS - CELEBRATION_DELAY_MS)
        } else {
            delay(RESULT_DELAY_MS)
        }
        showGameOver = true
    }

    FeltBackground {
        if (gameState == null) {
            MenuScreen(
                onStartGame = { mode, players ->
                    if (mode.isMultiplayer) viewModel.startPassAndPlay(players)
                    else viewModel.startGame(mode)
                },
                onOpenSettings = { showSettings = true },
                onOpenStats    = { showStats = true }
            )
        } else {
            gameState?.let { state ->
                // The GL dice now composite in normal z-order, so this is no longer a
                // correctness workaround — it just retires the render thread while a
                // full-screen overlay hides the dice anyway.
                val overlayActive = showGameOver || showSettings || showStats ||
                    showModeSelect ||
                    pap?.showRoundEnd == true || pap?.showResults == true
                ActiveGameScreen(
                    state          = state,
                    playerLabel    = playerLabel,
                    overlayActive  = overlayActive,
                    showHints      = settings.showHints,
                    showDiceTotal  = settings.showDiceTotal,
                    // iOS shows the score onboarding line only on the very first game,
                    // and only until that game's first roll.
                    showScoreHint  = overall.gamesPlayed == 0 && !state.hasRolled,
                    onToggle       = viewModel::toggleTile,
                    onRoll         = viewModel::rollDice,
                    onConfirm      = viewModel::confirmSelection,
                    onModeSelect   = { showModeSelect = true },
                    onHint         = viewModel::hint,
                    onUndo         = viewModel::clearSelection,
                    onUndoMove     = viewModel::undoLastMove,
                    onOpenSettings = { showSettings = true },
                    onOpenStats    = { showStats = true }
                )
            }
        }

        AnimatedVisibility(
            visible  = showGameOver,
            enter    = fadeIn() + scaleIn(initialScale = 0.9f),
            exit     = fadeOut() + scaleOut(targetScale = 0.9f),
            modifier = Modifier.fillMaxSize()
        ) {
            lastResult.value?.let { result ->
                GameOverOverlay(
                    result         = result,
                    remainingTiles = lastRemaining.value,
                    onPlayAgain    = { viewModel.startGame(result.mode) },
                    onStats        = { showStats = true },
                    onSettings     = { showSettings = true }
                )
            }
        }

        if (pap != null) {
            when {
                pap.showResults -> PassAndPlayResultsOverlay(
                    state     = pap,
                    onNewGame = { viewModel.startPassAndPlay(pap.playerCount) },
                    onMenu    = viewModel::exitGame
                )
                pap.showRoundEnd -> PassAndPlayRoundEndOverlay(
                    state     = pap,
                    onNext    = viewModel::nextPassAndPlayer,
                    onResults = viewModel::showPassAndPlayResults
                )
            }
        }

        if (showCelebration || pap?.showResults == true) {
            CelebrationOverlay()
        }

        if (showSettings) {
            SettingsOverlay(
                settings        = settings,
                onTheme         = viewModel::setTheme,
                onLanguage      = viewModel::setLanguage,
                onAnimSpeed     = viewModel::setDiceAnimationSpeed,
                onSound         = viewModel::setSoundEnabled,
                onHaptics       = viewModel::setHapticsEnabled,
                onShowHints     = viewModel::setShowHints,
                onShowDiceTotal = viewModel::setShowDiceTotal,
                onClose         = { showSettings = false }
            )
        }

        if (showStats) {
            StatsOverlay(
                overall   = overall,
                modeBests = modeBests,
                onReset   = viewModel::resetStats,
                onClose   = { showStats = false }
            )
        }

        // iOS-style mode selection sheet over the running game: picking a mode
        // starts it; cancelling just closes the sheet and play continues.
        if (showModeSelect) {
            ModeSelectOverlay(
                currentMode    = gameState?.mode ?: GameMode.CLASSIC,
                currentPlayers = pap?.playerCount ?: 2,
                onStart = { mode, players ->
                    showModeSelect = false
                    if (mode.isMultiplayer) viewModel.startPassAndPlay(players)
                    else viewModel.startGame(mode)
                },
                onClose = { showModeSelect = false }
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Felt / wood table background (iOS WoodBackground)
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun FeltBackground(content: @Composable BoxScope.() -> Unit) {
    val theme = LocalBoardTheme.current
    Box(modifier = Modifier.fillMaxSize()) {
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                // The felt is three full-screen gradients and a hundred-odd grain lines,
                // and it never changes — but every frame the GL dice publish damages the
                // whole window, so without a compositing layer the GPU re-shades all of
                // it at the dice's frame rate. Offscreen renders it into a texture once
                // and blits that instead, which is what a weak GPU can actually afford.
                .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
        ) {
            val w = size.width
            val h = size.height

            // Diagonal theme gradient.
            drawRect(
                brush = Brush.linearGradient(
                    colors = theme.background,
                    start  = Offset(0f, 0f),
                    end    = Offset(w, h)
                )
            )
            // Warm pool of light up top, falling to deep shadow at the edges.
            drawRect(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0.0f to Color.White.copy(alpha = if (theme.lightSurface) 0.06f else 0.12f),
                        0.5f to Color.Transparent,
                        1.0f to Color.Black.copy(alpha = if (theme.lightSurface) 0.18f else 0.48f)
                    ),
                    center = Offset(w * 0.5f, h * 0.32f),
                    radius = maxOf(w, h) * 0.9f
                )
            )
            // Bottom darkening.
            drawRect(
                brush = Brush.verticalGradient(
                    colors = listOf(Color.Transparent, Color.Black.copy(alpha = if (theme.lightSurface) 0.10f else 0.30f)),
                    startY = h * 0.5f, endY = h
                )
            )
            // Faint horizontal felt grain (iOS WoodGrain overlay).
            val grain = (if (theme.lightSurface) Color.Black else Color.White).copy(alpha = 0.03f)
            var gy = 0f
            val step = 10f * density
            while (gy < h) {
                drawLine(grain, Offset(0f, gy), Offset(w, gy), strokeWidth = 1f)
                gy += step
            }
        }
        content()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu (mode chooser) — styled like the iOS GameModeSelectionView list
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun MenuScreen(
    onStartGame:    (GameMode, Int) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenStats:    () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp, vertical = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // No app title or kicker: iOS reaches mode selection as a sheet over the board
        // and never shows one, and dropping them here leaves the chooser itself — the
        // only thing this screen is for — sitting where the eye lands first.
        Spacer(Modifier.height(20.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MenuPillButton(stringResource(R.string.menu_settings), onOpenSettings)
            MenuPillButton(stringResource(R.string.menu_stats), onOpenStats)
        }
        Spacer(Modifier.height(8.dp))

        ModeChooser(
            modifier = Modifier.widthIn(max = 420.dp).fillMaxWidth(),
            onStart  = onStartGame
        )
    }
}

/**
 * The iOS `GameModeSelectionView` body: three labelled groups of radio rows, a player
 * count that unfolds under Pass & Play, and the amber Start Game button. Picking a row
 * only selects it — nothing starts until Start Game, exactly as on iOS.
 *
 * Shared by the launch menu and the in-game mode sheet so the two cannot drift apart.
 */
@Composable
private fun ModeChooser(
    onStart:        (GameMode, Int) -> Unit,
    modifier:       Modifier = Modifier,
    initialMode:    GameMode = GameMode.CLASSIC,
    initialPlayers: Int = 2
) {
    // iOS binds the selection to @AppStorage, so the sheet opens on the mode that is
    // actually being played; the launch menu has no running game and starts on Classic.
    var selected    by rememberSaveable(initialMode) { mutableStateOf(initialMode) }
    var playerCount by rememberSaveable(initialPlayers) { mutableIntStateOf(initialPlayers) }

    Column(modifier = modifier) {
        ModeGroup(
            title    = stringResource(R.string.mode_group_classic),
            modes    = listOf(GameMode.CLASSIC, GameMode.SPEED_RUN),
            selected = selected,
            onSelect = { selected = it }
        )
        ModeGroup(
            title    = stringResource(R.string.mode_group_bigbox),
            modes    = listOf(GameMode.BIG_BOX, GameMode.BIG_BOX_SPEED),
            selected = selected,
            onSelect = { selected = it }
        )
        ModeGroup(
            title    = stringResource(R.string.mode_group_multiplayer),
            modes    = listOf(GameMode.PASS_AND_PLAY),
            selected = selected,
            onSelect = { selected = it }
        )
        // iOS animates the section in with .spring(response: 0.3, dampingFraction: 0.8).
        AnimatedVisibility(
            visible = selected.isMultiplayer,
            enter   = fadeIn() + expandVertically(),
            exit    = fadeOut() + shrinkVertically()
        ) {
            PlayerCountGroup(count = playerCount, onSelect = { playerCount = it })
        }
        Spacer(Modifier.height(24.dp))
        SheetPrimaryButton(
            text        = stringResource(R.string.mode_start_game),
            leadingPlay = true,
            onClick     = { onStart(selected, playerCount) }
        )
    }
}

@Composable
private fun ModeGroup(
    title:    String,
    modes:    List<GameMode>,
    selected: GameMode,
    onSelect: (GameMode) -> Unit
) {
    SectionLabel(title)
    GroupCard {
        modes.forEachIndexed { i, mode ->
            if (i > 0) GroupDivider()
            ModeRow(
                mode       = mode,
                isSelected = mode == selected,
                onClick    = { onSelect(mode) }
            )
        }
    }
}

@Composable
private fun ModeRow(mode: GameMode, isSelected: Boolean, onClick: () -> Unit) {
    val theme = LocalBoardTheme.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            )
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            // iOS: label(17) / caption(13), both AvenirNextCondensed-DemiBold.
            Text(
                text = mode.label(),
                // iOS dims the unpicked titles rather than badging the picked one.
                color = if (isSelected) theme.text else theme.text.copy(alpha = 0.70f),
                fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = 17.sp
            )
            Spacer(Modifier.height(3.dp))
            Text(
                text = mode.descriptionLabel(),
                color = theme.text.copy(alpha = 0.5f),
                fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = 13.sp
            )
        }
        Spacer(Modifier.width(14.dp))
        ModeRadio(isSelected)
    }
}

/** iOS `checkmark.circle.fill` / empty `Circle().strokeBorder`, drawn from Canvas. */
@Composable
private fun ModeRadio(isSelected: Boolean) {
    val theme = LocalBoardTheme.current
    Canvas(Modifier.size(20.dp)) {
        val r = size.minDimension / 2f
        if (isSelected) {
            drawCircle(theme.accent, r, center)
            val tick = Path().apply {
                moveTo(size.width * 0.27f, size.height * 0.52f)
                lineTo(size.width * 0.43f, size.height * 0.68f)
                lineTo(size.width * 0.74f, size.height * 0.33f)
            }
            drawPath(
                path  = tick,
                color = DesignTokens.buttonLabel,
                style = Stroke(
                    width = size.width * 0.12f,
                    cap   = StrokeCap.Round,
                    join  = StrokeJoin.Round
                )
            )
        } else {
            val stroke = 1.5.dp.toPx()
            drawCircle(
                color  = theme.text.copy(alpha = 0.22f),
                radius = r - stroke / 2f,
                center = center,
                style  = Stroke(width = stroke)
            )
        }
    }
}

/** iOS `playerCountSection` — only shown while Pass & Play is the selected mode. */
@Composable
private fun PlayerCountGroup(count: Int, onSelect: (Int) -> Unit) {
    Column {
        SectionLabel(stringResource(R.string.mode_players))
        GroupCard {
            Row(
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                (2..4).forEach { n ->
                    PlayerCountButton(
                        count      = n,
                        isSelected = n == count,
                        onClick    = { onSelect(n) },
                        modifier   = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
private fun PlayerCountButton(
    count:      Int,
    isSelected: Boolean,
    onClick:    () -> Unit,
    modifier:   Modifier = Modifier
) {
    val theme = LocalBoardTheme.current
    val shape = RoundedCornerShape(11.dp)
    Box(
        modifier = modifier
            .clip(shape)
            .then(
                if (isSelected) Modifier.background(
                    Brush.verticalGradient(
                        listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)
                    )
                ) else Modifier.background(Color.White.copy(alpha = 0.06f))
            )
            .border(
                1.dp,
                Color.White.copy(alpha = if (isSelected) 0.40f else 0.08f),
                shape
            )
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            )
            .padding(vertical = 11.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text  = stringResource(R.string.mode_player_count, count),
            color = if (isSelected) DesignTokens.buttonLabel else theme.text.copy(alpha = 0.60f),
            fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = 16.sp
        )
    }
}

@Composable
private fun MenuPillButton(label: String, onClick: () -> Unit) {
    val theme = LocalBoardTheme.current
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(Color.Black.copy(alpha = 0.28f))
            .border(1.dp, Color.White.copy(alpha = 0.14f), RoundedCornerShape(50))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            )
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(label, color = theme.text.copy(alpha = 0.9f), fontFamily = AppFont,
            fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode selection sheet (iOS GameModeSelectionView) — shown over a running game;
// Cancel dismisses and play continues.
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun ModeSelectOverlay(
    currentMode:    GameMode,
    currentPlayers: Int,
    onStart:        (GameMode, Int) -> Unit,
    onClose:        () -> Unit
) {
    ThemedSheet(
        title        = stringResource(R.string.menu_choose_mode),
        // iOS puts the only action — Cancel — in the top *leading* slot.
        leadingLabel = stringResource(R.string.pass_cancel),
        onLeading    = onClose,
        onClose      = onClose,
        closeLabel   = null
    ) {
        ModeChooser(
            onStart        = onStart,
            initialMode    = currentMode,
            initialPlayers = currentPlayers
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active game
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun ActiveGameScreen(
    state:          GameState,
    playerLabel:    String?,
    overlayActive:  Boolean,
    showHints:      Boolean,
    showDiceTotal:  Boolean,
    showScoreHint:  Boolean,
    onToggle:       (Int) -> Unit,
    onRoll:         () -> Unit,
    onConfirm:      () -> Unit,
    onModeSelect:   () -> Unit,
    onHint:         () -> Unit,
    onUndo:         () -> Unit,
    onUndoMove:     () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenStats:    () -> Unit
) {
    val config      = LocalConfiguration.current
    val isLandscape = config.orientation == Configuration.ORIENTATION_LANDSCAPE
    val smallestW   = config.smallestScreenWidthDp
    val isPhone     = smallestW < 600
    // iOS picks one of three layoutScales straight from the size class: 1.0 portrait,
    // 0.9 phone landscape, 1.5 iPad. Android screen sizes are a continuum, and the
    // plain `>= 600dp` step meant a 480dp device rendered at pure iPhone scale with
    // all the slack pooling as empty felt — so the iPad end is blended in from 400dp
    // up instead of switching on in one jump.
    val sizeFraction = ((smallestW - 400f) / 200f).coerceIn(0f, 1f)
    val scale        = (1f + 0.5f * sizeFraction) * (if (isLandscape && isPhone) 0.9f else 1f)
    // iOS desired die: 108 phone portrait, 88 phone landscape, 156 iPad portrait.
    val desired      = if (isLandscape && isPhone) 88.dp
                       else lerp(DesignTokens.diceSize, 156.dp, sizeFraction)

    // iOS fittingDieSize: `available / (count + (count-1) * diceSpacingFactor)`, so a
    // die is only shrunk when the row genuinely would not fit. iOS portrait never
    // shrinks (a 3-dice Big Box row is 350pt on a 369pt column), so this only bites
    // on Android screens narrower than an iPhone.
    val screenW     = config.screenWidthDp.dp
    val diceAvail   = if (isLandscape && isPhone) screenW / 2 - 36.dp else screenW - 24.dp
    val rowFactor   = DiceSurface.widthFactor(state.mode.diceCount.coerceAtLeast(1))
    val dieSize     = minOf(desired, diceAvail / rowFactor).coerceAtLeast(40.dp)

    // iOS hands the board an explicit column width and tile cap (68 iPhone / 104 iPad);
    // both now ride the same blended fraction as the rest of the layout.
    val boardMaxWidth = minOf(lerp(430.dp, 900.dp, sizeFraction), screenW) -
                        lerp(24.dp, 64.dp, sizeFraction)
    val maxTileWidth  = lerp(68.dp, 104.dp, sizeFraction)

    // iOS game flow: only the opening throw is manual. After a confirmed move the
    // state returns to IDLE (dice cleared, a move in history) — roll the next
    // throw automatically after a short beat. Purely UI-driven: this calls the
    // same rollDice() the button does, so game logic is untouched.
    LaunchedEffect(state.phase, state.canUndo) {
        if (state.phase == GamePhase.IDLE && state.canUndo) {
            kotlinx.coroutines.delay(650L)
            onRoll()
        }
    }

    if (isLandscape && isPhone) {
        LandscapeGameLayout(state, playerLabel, dieSize, scale, maxTileWidth, overlayActive, showHints, showDiceTotal, showScoreHint, onToggle, onRoll, onConfirm, onModeSelect, onHint, onUndo, onUndoMove, onOpenSettings, onOpenStats)
    } else {
        PortraitGameLayout(state, playerLabel, dieSize, scale, boardMaxWidth, maxTileWidth, overlayActive, showHints, showDiceTotal, showScoreHint, onToggle, onRoll, onConfirm, onModeSelect, onHint, onUndo, onUndoMove, onOpenSettings, onOpenStats)
    }
}

@Composable
private fun PortraitGameLayout(
    state:       GameState,
    playerLabel: String?,
    dieSize:      Dp,
    scale:        Float,
    boardMaxWidth: Dp,
    maxTileWidth:  Dp,
    overlayActive: Boolean,
    showHints:     Boolean,
    showDiceTotal: Boolean,
    showScoreHint: Boolean,
    onToggle:    (Int) -> Unit,
    onRoll:      () -> Unit,
    onConfirm:   () -> Unit,
    onModeSelect: () -> Unit,
    onHint:         () -> Unit,
    onUndo:         () -> Unit,
    onUndoMove:     () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenStats:    () -> Unit
) {
    // iOS keeps a fixed 8pt (short screens) / 12pt gap between every section.
    val screenH = LocalConfiguration.current.screenHeightDp
    val gap = if (screenH < 700) 8.dp else 12.dp
    // iOS portrait is a ScrollView whose content very nearly fills an iPhone. Android
    // viewports are taller (and in dp often much larger), so the header, dice and
    // action rows are laid out at their natural height and the tray takes everything
    // left over — the same trade iOS makes in its landscape and iPad layouts. Once the
    // tray hits its tile cap the remaining slack is split evenly above and below.
    Column(
        modifier = Modifier
            .fillMaxSize()
            // iOS honours the safe area; enableEdgeToEdge() means we must ask for
            // the same insets or the header rides up under the status bar and the
            // controls sit behind the navigation bar.
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .padding(horizontal = 12.dp, vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        GameHeader(state, playerLabel, scale, showScoreHint, onOpenStats, onOpenSettings, onModeSelect)
        Spacer(Modifier.height(gap))
        // fill = false: the weight hands the tray the leftover height as a *ceiling*,
        // not a demand, so a tray already at its cap stays centred instead of stretching.
        Box(
            modifier         = Modifier.weight(1f, fill = false),
            contentAlignment = Alignment.Center
        ) {
            BoardView(
                tiles        = state.tiles,
                onTileClick  = onToggle,
                // widthIn must precede fillMaxWidth or the cap is ignored: fillMaxWidth
                // pins min = max = the parent width first.
                modifier     = Modifier.widthIn(max = boardMaxWidth).fillMaxWidth(),
                maxTileWidth = maxTileWidth,
                numberSize   = (DesignTokens.TILE_NUMBER_SIZE * scale).dp
            )
        }
        Spacer(Modifier.height(gap))
        DiceArea(state, dieSize, overlayActive, showDiceTotal)
        Spacer(Modifier.height(gap))
        // Fixed slot: the zone's own height swings by ~90dp across the turn, and
        // in a centred stack that would drag the tray up and down with it.
        Box(
            modifier         = Modifier.fillMaxWidth().height(DesignTokens.actionZoneHeight),
            contentAlignment = Alignment.TopCenter
        ) {
            GameActionButton(
                state, onRoll, onConfirm, onHint, onUndo, onUndoMove,
                showHint = showHints,
                modifier = Modifier.widthIn(max = 360.dp)
            )
        }
    }
}

@Composable
private fun LandscapeGameLayout(
    state:       GameState,
    playerLabel: String?,
    dieSize:      Dp,
    scale:        Float,
    maxTileWidth: Dp,
    overlayActive: Boolean,
    showHints:     Boolean,
    showDiceTotal: Boolean,
    showScoreHint: Boolean,
    onToggle:    (Int) -> Unit,
    onRoll:      () -> Unit,
    onConfirm:   () -> Unit,
    onModeSelect: () -> Unit,
    onHint:         () -> Unit,
    onUndo:         () -> Unit,
    onUndoMove:     () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenStats:    () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(20.dp),
        verticalAlignment     = Alignment.CenterVertically
    ) {
        // The Row bounds the height, so the tray already fits itself to the shorter of
        // the two axes here — the same iOS `boardSizing` rule the portrait layout uses.
        BoardView(state.tiles, onToggle, Modifier.weight(1f), maxTileWidth, (DesignTokens.TILE_NUMBER_SIZE * scale).dp)
        Column(
            modifier            = Modifier.weight(1f).fillMaxHeight().padding(vertical = 4.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceEvenly
        ) {
            ScoreModeBlock(state, playerLabel, scale, showScoreHint, onModeSelect)
            DiceArea(state, dieSize, overlayActive, showDiceTotal)
            GameActionButton(state, onRoll, onConfirm, onHint, onUndo, onUndoMove, showHint = showHints)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun GameHeader(
    state:       GameState,
    playerLabel: String?,
    scale:       Float,
    showScoreHint: Boolean,
    onStats:     () -> Unit,
    onSettings:  () -> Unit,
    onModeSelect: () -> Unit = {}
) {
    // iOS portraitHeader is a bare ZStack(alignment: .top) — all of the top offset
    // lives in the caller's padding, so no extra nudge here.
    Box(Modifier.fillMaxWidth()) {
        ScoreModeBlock(state, playerLabel, scale, showScoreHint, onModeSelect)
        Row(
            Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            // iOS headerIconButton: a 17×scale glyph in a 40×scale circle.
            CircleIconButton(scale, onClick = onStats) { StatsBarsIcon(size = (17 * scale).dp) }
            Spacer(Modifier.weight(1f))
            CircleIconButton(scale, onClick = onSettings) { GearIcon(size = (17 * scale).dp) }
        }
    }
}

@Composable
private fun ScoreModeBlock(
    state: GameState,
    playerLabel: String?,
    scale: Float,
    showScoreHint: Boolean,
    onModeSelect: () -> Unit = {}
) {
    val theme = LocalBoardTheme.current
    Column(
        modifier            = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text          = playerLabel ?: stringResource(R.string.menu_kicker),
            color         = if (playerLabel != null) theme.accent.copy(alpha = 0.85f) else theme.text.copy(alpha = 0.42f),
            fontSize      = (10 * scale).sp,
            fontFamily    = LabelFont, fontWeight = FontWeight.Bold,
            letterSpacing = (3 * scale).sp
        )
        Spacer(Modifier.height(4.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(R.string.score_label, state.remainingScore),
                color = theme.text,
                fontFamily = LabelFont, fontWeight = FontWeight.Bold,
                fontSize = (DesignTokens.scoreSize.value * scale).sp
            )
            if (state.mode.hasTimer && state.hasRolled) {
                Text("  ·  ", color = theme.text.copy(alpha = 0.35f), fontSize = (18 * scale).sp)
                Text(
                    text = stringResource(R.string.timer_label, state.elapsedSeconds),
                    color = theme.text,
                    fontFamily = LabelFont, fontWeight = FontWeight.Bold,
                    fontSize = (18 * scale).sp
                )
            }
        }
        // iOS onboarding line under the score: shown only on a player's very first
        // game, and only until they roll (`gamesPlayed == 0 && !hasRolled`). The timed
        // modes replace the score row entirely, so they never carry it.
        if (showScoreHint && !state.mode.hasTimer) {
            Spacer(Modifier.height((3 * scale).dp))
            Text(
                text       = stringResource(R.string.score_hint),
                color      = theme.text.copy(alpha = 0.66f),
                fontFamily = LabelFont, fontWeight = FontWeight.SemiBold,
                fontSize   = (12 * scale).sp,
                textAlign  = TextAlign.Center
            )
        }
        Spacer(Modifier.height(5.dp))
        ModePill(state.mode.label(), scale, onModeSelect)
    }
}

@Composable
private fun ModePill(label: String, scale: Float, onClick: () -> Unit = {}) {
    val theme = LocalBoardTheme.current
    val tint = theme.text.copy(alpha = 0.82f)
    // Tappable like the iOS mode pill (a plain Button opening mode selection):
    // returns to the game-mode menu so a new mode can be picked mid-game.
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(
                Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.30f), Color.Black.copy(alpha = 0.16f)))
            )
            .border(1.dp, Color.White.copy(alpha = 0.18f), RoundedCornerShape(50))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            )
            .padding(horizontal = (12 * scale).dp, vertical = (5 * scale).dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy((5 * scale).dp)
        ) {
            DiceFillIcon(tint = tint, size = (10 * scale).dp)
            Text(
                text = label,
                color = tint,
                fontFamily = LabelFont, fontWeight = FontWeight.SemiBold, fontSize = (12 * scale).sp
            )
            Text(
                text = "›",
                color = tint.copy(alpha = tint.alpha * 0.7f),
                fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = (11 * scale).sp
            )
        }
    }
}

@Composable
private fun CircleIconButton(scale: Float = 1f, onClick: () -> Unit, content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .size((40 * scale).dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.18f))
            .border(1.dp, Color.White.copy(alpha = 0.12f), CircleShape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) { content() }
}

/** Three bars (chart.bar.fill). */
@Composable
private fun StatsBarsIcon(tint: Color = DesignTokens.headerIconTint, size: Dp = 17.dp) {
    Canvas(modifier = Modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val barW = w * 0.22f
        val gap = (w - barW * 3f) / 2f
        listOf(0.45f, 0.75f, 1.0f).forEachIndexed { i, frac ->
            val x = i * (barW + gap)
            val barH = h * frac
            drawRoundRect(
                color = tint,
                topLeft = Offset(x, h - barH),
                size = Size(barW, barH),
                cornerRadius = CornerRadius(barW * 0.4f)
            )
        }
    }
}

/** Gold gear (gearshape.fill) drawn from Canvas — the ⚙ glyph renders as an emoji
 *  on many devices, which broke the iOS look. */
@Composable
private fun GearIcon(tint: Color = DesignTokens.headerIconTint, size: Dp = 17.dp) {
    Canvas(modifier = Modifier.size(size)) {
        val w = this.size.width
        val c = Offset(w / 2f, this.size.height / 2f)
        val outerR = w * 0.36f
        val toothLen = w * 0.14f
        val toothW = w * 0.16f
        // Eight teeth around the rim.
        for (i in 0 until 8) {
            rotate(degrees = i * 45f, pivot = c) {
                drawRoundRect(
                    color = tint,
                    topLeft = Offset(c.x - toothW / 2f, c.y - outerR - toothLen),
                    size = Size(toothW, toothLen + outerR * 0.5f),
                    cornerRadius = CornerRadius(toothW * 0.35f)
                )
            }
        }
        // Body ring: solid disc with a punched-out hub.
        drawCircle(color = tint, radius = outerR, center = c)
        drawCircle(
            color = Color.Black.copy(alpha = 0.55f),
            radius = w * 0.15f,
            center = c
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dice area
// ─────────────────────────────────────────────────────────────────────────────

private val decorativeFaces = listOf(5, 2, 4)

@Composable
private fun DiceArea(state: GameState, dieSize: Dp, overlayActive: Boolean, showTotal: Boolean = false) {
    val theme = LocalBoardTheme.current
    val showDecorative = !state.hasRolled && !state.isRolling
    val diceToShow = when {
        showDecorative -> decorativeFaces.take(state.mode.diceCount)
        state.isRolling && state.dice.isEmpty() -> List(state.mode.diceCount) { 1 }
        else -> state.dice
    }

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        // No instruction text under the dice — on iOS the roll/rolling status lives in
        // the action-button slot, which the Android layout already mirrors.
        if (overlayActive) {
            // A full-screen overlay is up and the dice are hidden behind it, so drop to
            // the flat Compose dice and let the GL thread go.
            DiceView(dice = diceToShow, isRolling = state.isRolling, dieSize = dieSize)
        } else {
            val n = diceToShow.size.coerceAtLeast(1)
            // iOS lays out n `dieSize` frames with dieSize × 13/108 between them; the
            // GL surface reproduces that pitch and apparent die size (see DiceSurface).
            // No contact shadow under the dice — they sit on the felt unshadowed.
            Dice3DView(
                dice      = diceToShow,
                isRolling = state.isRolling,
                dieSize   = dieSize,
                modifier  = Modifier
                    .height(dieSize * DiceSurface.HEIGHT_FACTOR)
                    .width(dieSize * DiceSurface.widthFactor(n))
            )
        }
        // iOS: dice total readout under the dice when the setting is on.
        if (showTotal && state.hasRolled && !state.isRolling) {
            // iOS diceSection is a VStack(spacing: 8).
            Spacer(Modifier.height(8.dp))
            Text(
                text = stringResource(R.string.dice_total, state.diceTotal),
                color = theme.text.copy(alpha = 0.86f),
                fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 16.sp
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game-over overlay (iOS GameOverView)
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun GameOverOverlay(
    result:         GameResult,
    remainingTiles: List<Int>,
    onPlayAgain:    () -> Unit,
    onStats:        () -> Unit,
    onSettings:     () -> Unit
) {
    val theme = LocalBoardTheme.current
    val context = LocalContext.current

    // iOS result-title gradients are fixed (not theme-driven): warm gold for a
    // plain Game Over, celebratory gold for a Perfect Clear.
    val titleColors =
        if (result.isPerfect) listOf(Color(1.0f, 0.91f, 0.68f), Color(0.86f, 0.56f, 0.24f))
        else listOf(Color(1.0f, 0.88f, 0.60f), Color(0.96f, 0.56f, 0.22f))

    Box(
        modifier         = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.55f)),
        contentAlignment = Alignment.Center
    ) {
        BoxWithConstraints {
            val cardW = if (maxWidth > 430.dp) 350.dp else maxWidth - 56.dp
            Column(
                modifier = Modifier
                    .widthIn(max = cardW)
                    .fillMaxWidth()
                    .shadow(28.dp, RoundedCornerShape(DesignTokens.cornerRadiusLarge))
                    .clip(RoundedCornerShape(DesignTokens.cornerRadiusLarge))
                    .background(
                        Brush.linearGradient(theme.background.map { it.copy(alpha = 0.97f) })
                    )
                    // iOS card border: white → accent → black vertical gradient.
                    .border(
                        1.5.dp,
                        Brush.verticalGradient(
                            listOf(
                                Color.White.copy(alpha = 0.28f),
                                theme.accent.copy(alpha = 0.25f),
                                Color.Black.copy(alpha = 0.30f)
                            )
                        ),
                        RoundedCornerShape(DesignTokens.cornerRadiusLarge)
                    )
                    .padding(horizontal = 26.dp, vertical = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // iOS iconBar: stats on the left, settings on the right.
                Row(Modifier.fillMaxWidth()) {
                    CardIconButton(onClick = onStats) { StatsBarsIcon(theme.text.copy(alpha = 0.70f)) }
                    Spacer(Modifier.weight(1f))
                    CardIconButton(onClick = onSettings) { GearIcon(theme.text.copy(alpha = 0.70f)) }
                }
                Spacer(Modifier.height(14.dp))
                GradientText(
                    text = if (result.isPerfect) stringResource(R.string.result_perfect)
                           else stringResource(R.string.result_gameover),
                    colors = titleColors,
                    fontSize = if (result.isPerfect) 31.sp else 34.sp
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    text = if (result.isPerfect) stringResource(R.string.result_sub_perfect)
                           else stringResource(R.string.result_sub_gameover),
                    color = theme.text.copy(alpha = 0.72f),
                    fontFamily = LabelFont, fontWeight = FontWeight.Medium, fontSize = 16.sp,
                    textAlign = TextAlign.Center
                )
                Spacer(Modifier.height(10.dp))
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(Color.Black.copy(alpha = 0.22f))
                        .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(50))
                        .padding(horizontal = 12.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = result.mode.label(),
                        color = theme.text.copy(alpha = 0.78f),
                        fontFamily = LabelFont, fontWeight = FontWeight.Medium, fontSize = 12.sp
                    )
                }

                Spacer(Modifier.height(20.dp))

                // Score panel.
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color.Black.copy(alpha = 0.18f))
                        .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(18.dp))
                        .padding(vertical = 16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = stringResource(R.string.result_final_score).uppercase(),
                        color = theme.accent.copy(alpha = 0.82f),
                        fontFamily = LabelFont, fontWeight = FontWeight.Bold,
                        fontSize = 12.sp, letterSpacing = 1.8.sp
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = result.score.toString(),
                        color = theme.text,
                        fontFamily = DisplayFont, fontWeight = FontWeight.Bold,
                        fontSize = DesignTokens.displaySize
                    )
                    if (result.mode.hasTimer) {
                        Spacer(Modifier.height(2.dp))
                        Text(
                            text = stringResource(R.string.result_time) + ": " +
                                   stringResource(R.string.result_time_value, result.timeSeconds),
                            color = theme.accent.copy(alpha = 0.76f),
                            fontFamily = LabelFont, fontWeight = FontWeight.Medium, fontSize = 13.sp
                        )
                    } else {
                        Spacer(Modifier.height(2.dp))
                        Text(
                            text = stringResource(R.string.result_lower_better),
                            color = theme.text.copy(alpha = 0.52f),
                            fontFamily = LabelFont, fontWeight = FontWeight.Medium, fontSize = 12.sp
                        )
                    }
                }

                Spacer(Modifier.height(16.dp))

                // Remaining open tiles — gold chips grid, or a green "None".
                Text(
                    text = stringResource(R.string.result_remaining).uppercase(),
                    color = theme.accent.copy(alpha = 0.78f),
                    fontFamily = LabelFont, fontWeight = FontWeight.Bold,
                    fontSize = 12.sp, letterSpacing = 1.4.sp
                )
                Spacer(Modifier.height(10.dp))
                if (remainingTiles.isEmpty()) {
                    Text(
                        text = stringResource(R.string.result_none),
                        color = Color(0.58f, 1.0f, 0.50f),
                        fontFamily = LabelFont, fontWeight = FontWeight.Bold, fontSize = 18.sp,
                        modifier = Modifier.padding(vertical = 4.dp)
                    )
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        remainingTiles.chunked(6).forEach { rowTiles ->
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                rowTiles.forEach { n -> RemainingTileChip(n, theme.button) }
                            }
                        }
                    }
                }

                Spacer(Modifier.height(20.dp))

                GoldOverlayButton(stringResource(R.string.btn_new_game), onPlayAgain)
                Spacer(Modifier.height(10.dp))
                // iOS: a single full-width Share secondary with the share glyph.
                val modeName = result.mode.label()
                ShareButton(stringResource(R.string.btn_share)) {
                    val msg = buildString {
                        append(context.getString(R.string.share_subject, modeName)).append("\n")
                        append(context.getString(R.string.share_score, result.score))
                        if (result.isPerfect) append(context.getString(R.string.share_perfect))
                    }
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, msg)
                    }
                    runCatching {
                        context.startActivity(Intent.createChooser(send, context.getString(R.string.share_chooser)))
                    }
                }
            }
        }
    }
}

/** 36 dp circle icon button on the result card (iOS `iconButtonLabel`). */
@Composable
private fun CardIconButton(onClick: () -> Unit, content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.20f))
            .border(1.dp, Color.White.copy(alpha = 0.14f), CircleShape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) { content() }
}

/** One "still open" tile chip on the result card — iOS remainingTilesSection. */
@Composable
private fun RemainingTileChip(number: Int, buttonColors: List<Color>) {
    val shape = RoundedCornerShape(8.dp)
    Box(
        modifier = Modifier
            .width(36.dp)
            .height(34.dp)
            .clip(shape)
            .background(Brush.verticalGradient(buttonColors))
            .border(1.dp, Color.White.copy(alpha = 0.42f), shape),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = number.toString(),
            color = DesignTokens.buttonLabel,
            fontFamily = AppFont, fontWeight = FontWeight.Black, fontSize = 15.sp
        )
    }
}

@Composable
private fun GoldOverlayButton(text: String, onClick: () -> Unit) {
    val shape = RoundedCornerShape(15.dp)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .shadow(8.dp, shape, spotColor = DesignTokens.buttonGradientBottom)
            .clip(shape)
            .background(Brush.verticalGradient(listOf(DesignTokens.buttonGradientTop, DesignTokens.buttonGradientBottom)))
            .border(1.dp, Color.White.copy(alpha = 0.34f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = DesignTokens.buttonLabel, fontFamily = LabelFont,
            fontWeight = FontWeight.Bold, fontSize = 18.sp)
    }
}

@Composable
private fun ShareButton(text: String, onClick: () -> Unit) {
    val theme = LocalBoardTheme.current
    val shape = RoundedCornerShape(13.dp)
    val tint = theme.text.copy(alpha = 0.82f)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(46.dp)
            .clip(shape)
            .background(Color.Black.copy(alpha = 0.20f))
            .border(1.dp, Color.White.copy(alpha = 0.12f), shape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication        = null,
                onClick           = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(7.dp)
        ) {
            ShareIcon(tint)
            Text(text, color = tint, fontFamily = LabelFont,
                fontWeight = FontWeight.Bold, fontSize = 16.sp)
        }
    }
}

/** iOS `square.and.arrow.up`: an open box with an arrow rising from its centre. */
@Composable
private fun ShareIcon(tint: Color) {
    Canvas(Modifier.size(14.dp)) {
        val w = size.width
        val h = size.height
        val stroke = 1.6.dp.toPx()
        // Box (open at the top where the arrow passes through).
        drawLine(tint, Offset(w * 0.14f, h * 0.42f), Offset(w * 0.14f, h * 0.94f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(tint, Offset(w * 0.86f, h * 0.42f), Offset(w * 0.86f, h * 0.94f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(tint, Offset(w * 0.14f, h * 0.94f), Offset(w * 0.86f, h * 0.94f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(tint, Offset(w * 0.14f, h * 0.42f), Offset(w * 0.30f, h * 0.42f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(tint, Offset(w * 0.70f, h * 0.42f), Offset(w * 0.86f, h * 0.42f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        // Arrow shaft + head.
        drawLine(tint, Offset(w * 0.50f, h * 0.06f), Offset(w * 0.50f, h * 0.62f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(tint, Offset(w * 0.32f, h * 0.24f), Offset(w * 0.50f, h * 0.06f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
        drawLine(tint, Offset(w * 0.68f, h * 0.24f), Offset(w * 0.50f, h * 0.06f), stroke, androidx.compose.ui.graphics.StrokeCap.Round)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: gradient title text
// ─────────────────────────────────────────────────────────────────────────────

@Composable
private fun GradientText(text: String, colors: List<Color>, fontSize: TextUnit) {
    Text(
        text = text,
        // iOS titles use AmericanTypewriter-Bold; TitleFont is the typewriter match.
        fontFamily = TitleFont,
        fontWeight = FontWeight.Bold,
        fontSize = fontSize,
        textAlign = TextAlign.Center,
        style = androidx.compose.ui.text.TextStyle(
            brush = Brush.verticalGradient(colors)
        )
    )
}
