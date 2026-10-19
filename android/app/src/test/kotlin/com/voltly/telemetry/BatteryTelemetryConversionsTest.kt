package com.voltly.telemetry

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BatteryTelemetryConversionsTest {
    @Test
    fun `level uses the reported scale`() {
        assertEquals(50.0, BatteryTelemetryConversions.levelToPercent(50, 100)!!, 0.0001)
        assertEquals(0.0, BatteryTelemetryConversions.levelToPercent(0, 100)!!, 0.0001)
        assertEquals(100.0, BatteryTelemetryConversions.levelToPercent(100, 100)!!, 0.0001)
        assertEquals(37.5, BatteryTelemetryConversions.levelToPercent(3, 8)!!, 0.0001)
    }

    @Test
    fun `level rejects missing or impossible values`() {
        assertNull(BatteryTelemetryConversions.levelToPercent(101, 100))
        assertNull(BatteryTelemetryConversions.levelToPercent(-1, 100))
        assertNull(BatteryTelemetryConversions.levelToPercent(50, 0))
        assertNull(BatteryTelemetryConversions.levelToPercent(50, -1))
    }

    @Test
    fun `millivolts convert to volts exactly once`() {
        assertEquals(5.0, BatteryTelemetryConversions.millivoltsToVolts(5000)!!, 0.0001)
        assertEquals(3.82, BatteryTelemetryConversions.millivoltsToVolts(3820)!!, 0.0001)
        assertEquals(20.0, BatteryTelemetryConversions.millivoltsToVolts(20000)!!, 0.0001)
    }

    @Test
    fun `voltage outside the plausible range is rejected`() {
        assertNull(BatteryTelemetryConversions.millivoltsToVolts(0))
        assertNull(BatteryTelemetryConversions.millivoltsToVolts(999))
        assertNull(BatteryTelemetryConversions.millivoltsToVolts(20001))
        assertNull(BatteryTelemetryConversions.millivoltsToVolts(Int.MIN_VALUE))
    }

    @Test
    fun `tenths of celsius convert to celsius`() {
        assertEquals(25.0, BatteryTelemetryConversions.tenthsCelsiusToCelsius(250)!!, 0.0001)
        assertEquals(-5.0, BatteryTelemetryConversions.tenthsCelsiusToCelsius(-50)!!, 0.0001)
        assertEquals(-40.0, BatteryTelemetryConversions.tenthsCelsiusToCelsius(-400)!!, 0.0001)
        assertEquals(100.0, BatteryTelemetryConversions.tenthsCelsiusToCelsius(1000)!!, 0.0001)
    }

    @Test
    fun `temperature outside the plausible range is rejected`() {
        assertNull(BatteryTelemetryConversions.tenthsCelsiusToCelsius(-401))
        assertNull(BatteryTelemetryConversions.tenthsCelsiusToCelsius(1001))
        assertNull(BatteryTelemetryConversions.tenthsCelsiusToCelsius(Int.MIN_VALUE))
    }

    @Test
    fun `positive microamps mean current entering the battery`() {
        assertEquals(1.5, BatteryTelemetryConversions.microampsToAmps(1_500_000)!!, 0.000001)
        assertEquals(0.0, BatteryTelemetryConversions.microampsToAmps(0)!!, 0.000001)
    }

    @Test
    fun `negative microamps mean current leaving the battery`() {
        assertEquals(-0.5, BatteryTelemetryConversions.microampsToAmps(-500_000)!!, 0.000001)
        assertEquals(-2.25, BatteryTelemetryConversions.microampsToAmps(-2_250_000)!!, 0.000001)
    }

    @Test
    fun `current outside the plausible range is rejected`() {
        assertNull(BatteryTelemetryConversions.microampsToAmps(20_000_001))
        assertNull(BatteryTelemetryConversions.microampsToAmps(-20_000_001))
        assertNull(BatteryTelemetryConversions.microampsToAmps(Int.MIN_VALUE))
    }

    @Test
    fun `charge counter converts microamp hours to milliamp hours`() {
        assertEquals(10.0, BatteryTelemetryConversions.microampHoursToMilliampHours(10000)!!, 0.0001)
        assertEquals(3500.0, BatteryTelemetryConversions.microampHoursToMilliampHours(3_500_000)!!, 0.0001)
    }

    @Test
    fun `charge counter rejects non-positive and implausible values`() {
        assertNull(BatteryTelemetryConversions.microampHoursToMilliampHours(0))
        assertNull(BatteryTelemetryConversions.microampHoursToMilliampHours(-1))
        assertNull(BatteryTelemetryConversions.microampHoursToMilliampHours(100_000_001))
        assertNull(BatteryTelemetryConversions.microampHoursToMilliampHours(Long.MIN_VALUE))
    }

    @Test
    fun `status values map to stable contract names`() {
        assertEquals("charging", BatteryTelemetryConversions.statusName(2))
        assertEquals("discharging", BatteryTelemetryConversions.statusName(3))
        assertEquals("not_charging", BatteryTelemetryConversions.statusName(4))
        assertEquals("full", BatteryTelemetryConversions.statusName(5))
        assertNull(BatteryTelemetryConversions.statusName(1))
        assertNull(BatteryTelemetryConversions.statusName(99))
    }

    @Test
    fun `plug values map to stable contract names`() {
        assertEquals("none", BatteryTelemetryConversions.plugName(0))
        assertEquals("ac", BatteryTelemetryConversions.plugName(1))
        assertEquals("usb", BatteryTelemetryConversions.plugName(2))
        assertEquals("wireless", BatteryTelemetryConversions.plugName(4))
        assertEquals("dock", BatteryTelemetryConversions.plugName(8))
        assertNull(BatteryTelemetryConversions.plugName(3))
        assertNull(BatteryTelemetryConversions.plugName(-1))
    }
}
