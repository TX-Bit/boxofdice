package com.example.boxofdice.engine

/**
 * Deterministic pseudo-random generator producing the same dice sequence for a given
 * seed as the iOS `SeededRandomNumberGenerator` (SplitMix64). Used for the Daily
 * Challenge and custom-seed games so a seed plays identically on both platforms.
 *
 * All arithmetic is unsigned 64-bit, emulated with Kotlin's `Long` + `*ULong` ops.
 */
class SeededRandom(seed: Long) {

    private var state: Long = if (seed == 0L) GOLDEN else seed

    /** Next raw 64-bit value (interpreted as unsigned). */
    fun nextLong(): Long {
        state += GOLDEN
        var z = state
        z = (z xor (z ushr 30)) * MIX_1
        z = (z xor (z ushr 27)) * MIX_2
        return z xor (z ushr 31)
    }

    /** Uniform die value in [1, 6], matching Swift's `Int.random(in:1...6, using:)`. */
    fun nextDie(): Int = nextInt(1, 6)

    /** Uniform integer in [min, max] inclusive, using unbiased rejection sampling. */
    fun nextInt(min: Int, max: Int): Int {
        require(max >= min)
        val range = (max - min + 1).toULong()
        // Unbiased: reject the top remainder so every value is equally likely.
        val limit = ULong.MAX_VALUE - (ULong.MAX_VALUE % range)
        var bits: ULong
        do {
            bits = nextLong().toULong()
        } while (bits >= limit)
        return min + (bits % range).toInt()
    }

    companion object {
        private const val GOLDEN: Long = -0x61c8864680b583ebL   // 0x9E3779B97F4A7C15
        private const val MIX_1: Long = -0x40a7b892e31b1a47L     // 0xBF58476D1CE4E5B9
        private const val MIX_2: Long = -0x6b2fb644ecceee15L     // 0x94D049BB133111EB

        /** A stable seed for the day in the given epoch-day count (UTC). */
        fun dailySeed(epochDay: Long): Long = epochDay * 2654435761L + 0x5DEECE66DL
    }
}
