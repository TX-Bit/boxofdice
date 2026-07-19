package com.example.boxofdice.feedback

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Lightweight haptics + sound for game events, mirroring the iOS `GameFeedback`. Sounds use the
 * built-in [ToneGenerator] so no audio assets are required; haptics use the system [Vibrator].
 * Both channels are gated by the caller (settings), so this class always plays when asked.
 */
class GameFeedback(context: Context) {

    private val appContext = context.applicationContext

    private val vibrator: Vibrator? = runCatching {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val mgr = appContext.getSystemService(VibratorManager::class.java)
            mgr?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }.getOrNull()

    private val tones: ToneGenerator? =
        runCatching { ToneGenerator(AudioManager.STREAM_MUSIC, 70) }.getOrNull()

    // ── Haptics ──────────────────────────────────────────────────────────────

    fun tileSelected() = vibrate(12)
    fun moveConfirmed() = vibrate(22)
    fun invalidAction() = vibrate(40)
    fun boardCleared() = vibratePattern(longArrayOf(0, 30, 60, 30, 60, 60))

    // ── Sounds ───────────────────────────────────────────────────────────────

    fun playDiceRoll() = tone(ToneGenerator.TONE_PROP_BEEP, 80)
    fun playTileFlip() = tone(ToneGenerator.TONE_PROP_ACK, 60)
    fun playVictory() {
        tone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 120)
    }
    fun playGameOver() = tone(ToneGenerator.TONE_SUP_ERROR, 150)

    fun release() {
        runCatching { tones?.release() }
    }

    // ── Internals ──────────────────────────────────────────────────────────────

    private fun vibrate(ms: Long) {
        val v = vibrator ?: return
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION") v.vibrate(ms)
            }
        }
    }

    private fun vibratePattern(pattern: LongArray) {
        val v = vibrator ?: return
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION") v.vibrate(pattern, -1)
            }
        }
    }

    private fun tone(type: Int, durationMs: Int) {
        runCatching { tones?.startTone(type, durationMs) }
    }
}
