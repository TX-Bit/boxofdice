package com.example.boxofdice.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.boxofdice.data.AppSettings
import com.example.boxofdice.data.OverallStats
import com.example.boxofdice.data.SettingsRepository
import com.example.boxofdice.data.StatsRepository
import com.example.boxofdice.engine.GameEngine
import com.example.boxofdice.engine.SeededRandom
import com.example.boxofdice.feedback.GameFeedback
import com.example.boxofdice.model.ChallengeMode
import com.example.boxofdice.model.DiceMode
import com.example.boxofdice.model.GameMode
import com.example.boxofdice.model.GamePhase
import com.example.boxofdice.model.GameResult
import com.example.boxofdice.model.GameState
import com.example.boxofdice.model.MoveRule
import com.example.boxofdice.model.PassAndPlayState
import com.example.boxofdice.model.TileState
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class GameViewModel(application: Application) : AndroidViewModel(application) {

    private val stats = StatsRepository(application)
    private val settingsRepo = SettingsRepository(application)
    private val feedback = GameFeedback(application)

    private val _settings = MutableStateFlow(AppSettings())
    val settings: StateFlow<AppSettings> = _settings.asStateFlow()

    val overallStats: StateFlow<OverallStats> = stats.overall
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), OverallStats())

    /** Best (lowest) recorded score per mode; null where a mode has not been finished yet. */
    val modeBestScores: StateFlow<Map<GameMode, Int?>> =
        combine(GameMode.entries.map { mode -> stats.statsFor(mode).map { mode to it.bestScore } }) { pairs ->
            pairs.toMap()
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    private var engine: GameEngine? = null

    private val _gameState = MutableStateFlow<GameState?>(null)
    val gameState: StateFlow<GameState?> = _gameState.asStateFlow()

    private val _gameResult = MutableStateFlow<GameResult?>(null)
    val gameResult: StateFlow<GameResult?> = _gameResult.asStateFlow()

    private val _passAndPlay = MutableStateFlow<PassAndPlayState?>(null)
    val passAndPlay: StateFlow<PassAndPlayState?> = _passAndPlay.asStateFlow()

    private var timerJob: Job? = null
    private var timerStartMillis: Long = 0L

    // Rules in effect for the current game (carried so "play again" reuses them).
    private var diceMode: DiceMode = DiceMode.ALWAYS_ALL
    private var moveRule: MoveRule = MoveRule.ANY_COMBINATION
    private var challengeMode: ChallengeMode = ChallengeMode.NORMAL
    private var customSeed: Long = 0L

    init {
        viewModelScope.launch {
            settingsRepo.settings.collect { _settings.value = it }
        }
    }

    // ── Settings ──────────────────────────────────────────────────────────────

    fun setTheme(theme: com.example.boxofdice.ui.theme.AppTheme) {
        viewModelScope.launch { settingsRepo.setTheme(theme) }
    }

    fun setDiceMode(mode: DiceMode) {
        viewModelScope.launch { settingsRepo.setDiceMode(mode) }
    }

    fun setMoveRule(rule: MoveRule) {
        viewModelScope.launch { settingsRepo.setMoveRule(rule) }
    }

    fun setSoundEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsRepo.setSoundEnabled(enabled) }
    }

    fun setHapticsEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsRepo.setHapticsEnabled(enabled) }
    }

    fun setLanguage(language: com.example.boxofdice.model.AppLanguage) {
        viewModelScope.launch { settingsRepo.setLanguage(language) }
    }

    fun setDiceAnimationSpeed(speed: com.example.boxofdice.model.DiceAnimationSpeed) {
        viewModelScope.launch { settingsRepo.setDiceAnimationSpeed(speed) }
    }

    fun setShowHints(show: Boolean) {
        viewModelScope.launch { settingsRepo.setShowHints(show) }
    }

    fun setShowDiceTotal(show: Boolean) {
        viewModelScope.launch { settingsRepo.setShowDiceTotal(show) }
    }

    // ── Public actions ────────────────────────────────────────────────────────

    fun startGame(
        mode: GameMode,
        diceMode: DiceMode = _settings.value.diceMode,
        moveRule: MoveRule = _settings.value.moveRule,
        challengeMode: ChallengeMode = ChallengeMode.NORMAL,
        customSeed: Long = this.customSeed
    ) {
        timerJob?.cancel()
        timerJob = null
        timerStartMillis = 0L
        _gameResult.value = null

        this.diceMode = diceMode
        this.moveRule = moveRule
        this.challengeMode = challengeMode
        this.customSeed = customSeed

        engine = GameEngine(
            currentGameMode = mode,
            diceRoller = rollerFor(challengeMode, customSeed),
            diceMode = diceMode,
            moveRule = moveRule
        )
        syncState()
    }

    // ── Pass & Play ─────────────────────────────────────────────────────────

    /** Begin a Pass & Play session: [playerCount] players each play one Classic round. */
    fun startPassAndPlay(playerCount: Int) {
        val count = playerCount.coerceIn(2, 4)
        _passAndPlay.value = PassAndPlayState(
            playerCount = count,
            currentPlayer = 1,
            scores = List(count) { null }
        )
        startPassAndPlayRound()
    }

    /** Advance from the hand-off overlay to the next player's round, or to the results. */
    fun nextPassAndPlayer() {
        val pap = _passAndPlay.value ?: return
        if (pap.isLastPlayer) {
            _passAndPlay.value = pap.copy(showRoundEnd = false, showResults = true)
            return
        }
        _passAndPlay.value = pap.copy(
            currentPlayer = pap.currentPlayer + 1,
            showRoundEnd = false
        )
        startPassAndPlayRound()
    }

    /** Jump straight to the final ranking (last player's "See Results"). */
    fun showPassAndPlayResults() {
        val pap = _passAndPlay.value ?: return
        _passAndPlay.value = pap.copy(showRoundEnd = false, showResults = true)
    }

    private fun startPassAndPlayRound() {
        timerJob?.cancel()
        timerJob = null
        timerStartMillis = 0L
        diceMode = DiceMode.ALWAYS_ALL
        moveRule = MoveRule.ANY_COMBINATION
        engine = GameEngine(
            currentGameMode = GameMode.PASS_AND_PLAY,
            diceMode = diceMode,
            moveRule = moveRule
        )
        syncState()
    }

    /**
     * Builds the dice source. Normal games use the system RNG; Daily and custom-seed
     * challenges use a deterministic [SeededRandom] so the same seed plays identically.
     */
    private fun rollerFor(challenge: ChallengeMode, seed: Long): (Int) -> List<Int> {
        val resolvedSeed = when (challenge) {
            ChallengeMode.NORMAL -> return { n -> List(n) { (1..6).random() } }
            ChallengeMode.DAILY -> SeededRandom.dailySeed(System.currentTimeMillis() / 86_400_000L)
            ChallengeMode.CUSTOM_SEED -> seed
        }
        val rng = SeededRandom(resolvedSeed)
        return { n -> List(n) { rng.nextDie() } }
    }

    fun rollDice() {
        val e = engine ?: return
        val current = _gameState.value ?: return
        if (current.phase != GamePhase.IDLE) return

        // Show rolling animation immediately
        _gameState.value = current.copy(phase = GamePhase.ROLLING, isRolling = true)
        sound { playDiceRoll() }

        viewModelScope.launch {
            // Start timer on the very first roll for speed modes
            if (e.currentGameMode.hasTimer && timerStartMillis == 0L) {
                timerStartMillis = System.currentTimeMillis()
                startTimer()
            }

            delay(_settings.value.diceAnimationSpeed.rollDelayMillis) // animation window

            e.rollDice()
            syncState()
            if (e.isGameOver()) finishGame()
        }
    }

    fun toggleTile(tileNumber: Int) {
        val e = engine ?: return
        if (_gameState.value?.phase != GamePhase.SELECTING) return
        runCatching { e.toggleTileSelection(tileNumber) }
            .onSuccess { haptic { tileSelected() }; syncState() }
            .onFailure { haptic { invalidAction() } }
    }

    fun confirmSelection() {
        val e = engine ?: return
        if (!e.canConfirmMove()) {
            haptic { invalidAction() }
            return
        }
        e.confirmMove()
        haptic { moveConfirmed() }
        sound { playTileFlip() }
        syncState()
        if (e.isGameOver()) finishGame()
    }

    fun exitGame() {
        timerJob?.cancel()
        timerJob = null
        timerStartMillis = 0L
        engine = null
        _gameResult.value = null
        _gameState.value = null
        _passAndPlay.value = null
    }

    fun clearSelection() {
        val e = engine ?: return
        if (_gameState.value?.phase != GamePhase.SELECTING) return
        e.selectedTiles.toList().forEach { num ->
            runCatching { e.toggleTileSelection(num) }
        }
        syncState()
    }

    fun hint() {
        val e = engine ?: return
        if (_gameState.value?.phase != GamePhase.SELECTING) return
        val move = e.bestHint() ?: return
        e.selectedTiles.toList().forEach { runCatching { e.toggleTileSelection(it) } }
        move.forEach { runCatching { e.toggleTileSelection(it) } }
        syncState()
    }

    /** Reopen the tiles closed by the most recent confirmed move (only between rolls). */
    fun undoLastMove() {
        val e = engine ?: return
        if (!e.canUndo()) return
        e.undoLastMove()
        syncState()
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private inline fun haptic(block: GameFeedback.() -> Unit) {
        if (_settings.value.hapticsEnabled) feedback.block()
    }

    private inline fun sound(block: GameFeedback.() -> Unit) {
        if (_settings.value.soundEnabled) feedback.block()
    }

    /** Push current engine state into the UI StateFlow. */
    private fun syncState(isRolling: Boolean = false) {
        val e = engine ?: return
        val tiles = (1..e.currentGameMode.tileCount).map { num ->
            TileState(
                number     = num,
                isOpen     = num in e.openTiles,
                isSelected = num in e.selectedTiles
            )
        }
        val phase = when {
            isRolling       -> GamePhase.ROLLING
            e.isGameOver()  -> GamePhase.GAME_OVER
            e.diceValues.isEmpty() -> GamePhase.IDLE
            else            -> GamePhase.SELECTING
        }
        _gameState.value = GameState(
            mode          = e.currentGameMode,
            tiles         = tiles,
            dice          = e.diceValues,
            phase         = phase,
            elapsedMillis = _gameState.value?.elapsedMillis ?: 0L,
            isRolling     = isRolling,
            canUndo       = e.canUndo(),
            lastClosedTiles = e.moveHistory.lastOrNull()?.closedTiles?.sorted() ?: emptyList()
        )
    }

    private fun startTimer() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (true) {
                delay(100L)
                val elapsed = System.currentTimeMillis() - timerStartMillis
                _gameState.value = _gameState.value?.copy(elapsedMillis = elapsed)
            }
        }
    }

    private fun finishGame() {
        timerJob?.cancel()
        timerJob = null
        val e = engine ?: return

        if (e.isBoardCleared()) {
            haptic { boardCleared() }
            sound { playVictory() }
        } else {
            haptic { invalidAction() }
            sound { playGameOver() }
        }

        // Pass & Play: record the round's score and show the hand-off overlay instead of
        // the single-player result. Stats are not tracked for multiplayer.
        val pap = _passAndPlay.value
        if (e.currentGameMode.isMultiplayer && pap != null) {
            val tileScore = e.calculateScore()
            val updatedScores = pap.scores.toMutableList().also {
                it[pap.currentPlayer - 1] = tileScore
            }
            _passAndPlay.value = pap.copy(
                scores = updatedScores,
                showRoundEnd = true,
                lastScore = tileScore
            )
            return
        }

        val finalMillis = if (e.currentGameMode.hasTimer && timerStartMillis > 0L)
            System.currentTimeMillis() - timerStartMillis
        else 0L
        val tileScore   = e.calculateScore()
        val timeSeconds = (finalMillis / 1000).toInt()
        val result = GameResult(
            mode        = e.currentGameMode,
            score       = if (e.currentGameMode.hasTimer) tileScore + timeSeconds else tileScore,
            tileScore   = tileScore,
            timeSeconds = timeSeconds,
            isPerfect   = e.isBoardCleared()
        )
        _gameResult.value = result
        viewModelScope.launch { stats.recordResult(result) }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        feedback.release()
    }
}
