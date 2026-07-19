package com.example.boxofdice.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SeededRandomTest {

    @Test fun `same seed produces the same die sequence`() {
        val a = SeededRandom(12345L)
        val b = SeededRandom(12345L)
        val seqA = List(20) { a.nextDie() }
        val seqB = List(20) { b.nextDie() }
        assertEquals(seqA, seqB)
    }

    @Test fun `different seeds usually differ`() {
        val seqA = SeededRandom(1L).let { r -> List(20) { r.nextDie() } }
        val seqB = SeededRandom(2L).let { r -> List(20) { r.nextDie() } }
        assertTrue(seqA != seqB)
    }

    @Test fun `dice stay within one to six`() {
        val r = SeededRandom(98765L)
        repeat(1000) {
            val d = r.nextDie()
            assertTrue("die $d out of range", d in 1..6)
        }
    }

    @Test fun `zero seed is remapped and still produces valid dice`() {
        val r = SeededRandom(0L)
        repeat(50) { assertTrue(r.nextDie() in 1..6) }
    }
}
