package com.example.boxofdice.feedback

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log
import androidx.annotation.RawRes
import com.example.boxofdice.R

/** `adb logcat -s BoxOfDiceFeedback` to watch haptics and sounds as they are requested. */
private const val TAG = "BoxOfDiceFeedback"

/**
 * Haptics + sound for game events, mirroring the iOS `GameFeedback`.
 *
 * The sounds are the iOS ones: `dice_roll` is the same recording the iOS bundle ships
 * (`dicesound1.aiff`, converted to PCM), and the other three are the waveforms iOS
 * synthesises at launch — a click-plus-thud tile flip, a descending A4–F4–D4 game-over
 * motif and a rising C5–E5–G5–C6 victory arpeggio — generated offline from the same
 * maths so both platforms play the identical sound. Per-sound volumes are iOS's.
 *
 * Both channels are gated by the caller (settings), so this class always plays when asked.
 */
class GameFeedback(context: Context) {

    private val appContext = context.applicationContext

    private val vibrator: Vibrator? = runCatching {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            appContext.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }.getOrNull()?.takeIf { runCatching { it.hasVibrator() }.getOrDefault(false) }

    /**
     * True only when the hardware genuinely implements the predefined effects. A device
     * that does not (a Galaxy A10 reports no supported effects at all) still *accepts*
     * `createPredefined`, but the platform then substitutes its own fallback pulse,
     * which is as short as the 12 ms one-shot this used to send — and a rotating-mass
     * motor cannot spin up far enough in 12 ms to be felt at all. Those devices get the
     * explicit, longer waveforms below instead.
     */
    private val usePredefined: Boolean = vibrator?.let { v ->
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && runCatching {
            v.areAllEffectsSupported(
                VibrationEffect.EFFECT_TICK,
                VibrationEffect.EFFECT_CLICK,
                VibrationEffect.EFFECT_DOUBLE_CLICK
            ) == Vibrator.VIBRATION_EFFECT_SUPPORT_YES
        }.getOrDefault(false)
    } ?: false

    private val soundPool: SoundPool = SoundPool.Builder()
        .setMaxStreams(4)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()

    /** Sound ids that have finished decoding; playing an unloaded id is a silent no-op. */
    private val ready = mutableSetOf<Int>()

    // Must be attached before the first load() below: a sample that finishes decoding
    // while there is no listener would never be marked ready, and so never play.
    init {
        soundPool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) synchronized(ready) { ready.add(sampleId) }
        }
    }

    private val diceRoll = load(R.raw.dice_roll)
    private val tileFlip = load(R.raw.tile_flip)
    private val gameOver = load(R.raw.game_over)
    private val victory  = load(R.raw.victory)

    init {
        // One line that answers "is the phone even able to do this?" — read it with
        // `adb logcat -s BoxOfDiceFeedback`. touchVibrationSetting is the system's own
        // touch/keyboard vibration switch: it used to silence this app's haptics.
        val touchSetting = runCatching {
            Settings.System.getInt(appContext.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, -1)
        }.getOrDefault(-1)
        Log.d(
            TAG,
            "vibrator=${vibrator != null}" +
                " amplitudeControl=${vibrator?.hasAmplitudeControl()}" +
                " predefinedEffects=$usePredefined" +
                " touchVibrationSetting=$touchSetting" +
                " sdk=${Build.VERSION.SDK_INT}"
        )
    }

    // ── Haptics ──────────────────────────────────────────────────────────────

    /** iOS light impact. */
    fun tileSelected() = haptic(HapticStyle.TICK)

    /** iOS medium impact. */
    fun moveConfirmed() = haptic(HapticStyle.CLICK)

    /** iOS error notification. */
    fun invalidAction() = haptic(HapticStyle.DOUBLE)

    /** iOS success notification. */
    fun boardCleared() = pattern(longArrayOf(0, 30, 70, 30, 70, 70))

    // ── Sounds ───────────────────────────────────────────────────────────────

    fun playDiceRoll() = play(diceRoll, 0.35f)
    fun playTileFlip() = play(tileFlip, 0.28f)
    fun playGameOver() = play(gameOver, 0.50f)
    fun playVictory()  = play(victory, 0.52f)

    fun release() {
        runCatching { soundPool.release() }
    }

    // ── Internals ──────────────────────────────────────────────────────────────

    private fun load(@RawRes res: Int): Int =
        runCatching { soundPool.load(appContext, res, 1) }.getOrDefault(0)

    private fun play(id: Int, volume: Float) {
        if (id == 0) {
            Log.w(TAG, "sound: not loaded (id 0)")
            return
        }
        val loaded = synchronized(ready) { id in ready }
        if (!loaded) {
            Log.w(TAG, "sound $id: still decoding, skipped")
            return
        }
        val stream = runCatching { soundPool.play(id, volume, volume, 1, 0, 1f) }.getOrDefault(0)
        Log.d(TAG, "sound $id vol=$volume -> stream $stream")
    }

    private enum class HapticStyle { TICK, CLICK, DOUBLE }


    private fun haptic(style: HapticStyle) {
        val v = vibrator
        if (v == null) {
            Log.w(TAG, "haptic $style: device reports no vibrator")
            return
        }
        Log.d(TAG, "haptic $style (predefined=$usePredefined)")
        runCatching {
            if (usePredefined) {
                val effect = when (style) {
                    HapticStyle.TICK   -> VibrationEffect.EFFECT_TICK
                    HapticStyle.CLICK  -> VibrationEffect.EFFECT_CLICK
                    HapticStyle.DOUBLE -> VibrationEffect.EFFECT_DOUBLE_CLICK
                }
                v.vibrate(VibrationEffect.createPredefined(effect))
            } else {
                // Long enough to survive the amplitude scaling the platform applies
                // to touch feedback: every vibration an app sends is classified
                // USAGE_TOUCH (passing AudioAttributes does not change that — the
                // framework maps everything but alarms and notifications to TOUCH), and
                // the phone's touch-vibration intensity slider then scales it. At a low
                // slider setting duration is the only lever left to the app.
                when (style) {
                    HapticStyle.TICK   -> oneShot(v, 40)
                    HapticStyle.CLICK  -> oneShot(v, 65)
                    HapticStyle.DOUBLE -> pattern(longArrayOf(0, 40, 70, 40))
                }
            }
        }.onFailure { Log.e(TAG, "haptic $style failed", it) }
    }

    private fun oneShot(v: Vibrator, ms: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Full amplitude rather than DEFAULT_AMPLITUDE: on a device with amplitude
            // control the default can land well below max, which a short pulse cannot
            // afford. Devices without amplitude control ignore the value.
            val amplitude = if (v.hasAmplitudeControl()) 255 else VibrationEffect.DEFAULT_AMPLITUDE
            v.vibrate(VibrationEffect.createOneShot(ms, amplitude))
        } else {
            @Suppress("DEPRECATION") v.vibrate(ms)
        }
    }

    private fun pattern(pattern: LongArray) {
        val v = vibrator ?: return
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION") v.vibrate(pattern, -1)
            }
        }
    }
}
