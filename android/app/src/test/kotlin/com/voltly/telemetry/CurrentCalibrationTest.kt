package com.voltly.telemetry

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CurrentCalibrationTest {
    @Test
    fun `documented microamp devices are converted unchanged`() {
        val calibration = CurrentCalibration()
        assertTrue(calibration.observe(-450_000, 0, "discharging"))
        assertFalse(calibration.reportsMilliamps)
        assertFalse(calibration.signInverted)
        assertTrue(calibration.signLearned)
        assertEquals(-0.45, calibration.toAmperes(-450_000)!!, 1e-9)
        assertEquals(1.2, calibration.toAmperes(1_200_000, "charging")!!, 1e-9)
    }

    @Test
    fun `small discharging magnitudes reveal milliamp reporting`() {
        val calibration = CurrentCalibration()
        assertTrue(calibration.observe(-380, 0, "discharging"))
        assertTrue(calibration.reportsMilliamps)
        assertEquals(-0.38, calibration.toAmperes(-380)!!, 1e-9)
        assertEquals(2.1, calibration.toAmperes(2_100, "charging")!!, 1e-9)
    }

    @Test
    fun `a large magnitude locks microamps again`() {
        val calibration = CurrentCalibration(reportsMilliamps = true)
        assertTrue(calibration.observe(1_500_000, 1, "charging"))
        assertFalse(calibration.reportsMilliamps)
        assertEquals(1.5, calibration.toAmperes(1_500_000, "charging")!!, 1e-9)
    }

    @Test
    fun `positive current while unplugged and discharging inverts the sign`() {
        val calibration = CurrentCalibration()
        assertTrue(calibration.observe(520_000, 0, "discharging"))
        assertTrue(calibration.signInverted)
        assertEquals(-0.52, calibration.toAmperes(520_000)!!, 1e-9)
        // Once learned, charging readings use the same inversion.
        assertEquals(1.8, calibration.toAmperes(-1_800_000, "charging")!!, 1e-9)
    }

    @Test
    fun `plugged observations never teach unit or sign`() {
        val calibration = CurrentCalibration()
        assertFalse(calibration.observe(-300, 1, "charging"))
        assertFalse(calibration.observe(-300, 2, "discharging"))
        assertFalse(calibration.reportsMilliamps)
        assertFalse(calibration.signLearned)
    }

    @Test
    fun `near-zero discharging readings do not teach the sign`() {
        val calibration = CurrentCalibration()
        calibration.observe(-2_000_000, 1, "charging")
        assertFalse(calibration.observe(0, 0, "discharging"))
        assertFalse(calibration.signLearned)
    }

    @Test
    fun `negative charging current is provisionally inverted until learned`() {
        val calibration = CurrentCalibration()
        assertEquals(1.1, calibration.toAmperes(-1_100_000, "charging")!!, 1e-9)

        val learned = CurrentCalibration(signLearned = true)
        assertEquals(-1.1, learned.toAmperes(-1_100_000, "charging")!!, 1e-9)
    }

    @Test
    fun `implausible magnitudes are rejected`() {
        val calibration = CurrentCalibration()
        assertNull(calibration.toAmperes(25_000_000))
        val milliamps = CurrentCalibration(reportsMilliamps = true)
        assertNull(milliamps.toAmperes(25_000))
    }
}
