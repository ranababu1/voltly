package com.voltly.charging

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ChargingScreenPolicyTest {
    @Test
    fun launchesWhenEnabledAndLocked() {
        assertTrue(
            ChargingScreenPolicy.shouldLaunch(
                enabled = true,
                keyguardLocked = true,
                screenInteractive = true,
                lastLaunchAtMillis = null,
                nowMillis = 10_000L,
            ),
        )
    }

    @Test
    fun launchesWhenScreenIsOffEvenWithoutKeyguard() {
        assertTrue(
            ChargingScreenPolicy.shouldLaunch(
                enabled = true,
                keyguardLocked = false,
                screenInteractive = false,
                lastLaunchAtMillis = null,
                nowMillis = 10_000L,
            ),
        )
    }

    @Test
    fun neverLaunchesWhenDisabled() {
        assertFalse(
            ChargingScreenPolicy.shouldLaunch(
                enabled = false,
                keyguardLocked = true,
                screenInteractive = false,
                lastLaunchAtMillis = null,
                nowMillis = 10_000L,
            ),
        )
    }

    @Test
    fun neverInterruptsAnUnlockedDeviceInUse() {
        assertFalse(
            ChargingScreenPolicy.shouldLaunch(
                enabled = true,
                keyguardLocked = false,
                screenInteractive = true,
                lastLaunchAtMillis = null,
                nowMillis = 10_000L,
            ),
        )
    }

    @Test
    fun debouncesRepeatedConnectBroadcasts() {
        assertFalse(
            ChargingScreenPolicy.shouldLaunch(
                enabled = true,
                keyguardLocked = true,
                screenInteractive = false,
                lastLaunchAtMillis = 10_000L,
                nowMillis = 12_000L,
            ),
        )
        assertTrue(
            ChargingScreenPolicy.shouldLaunch(
                enabled = true,
                keyguardLocked = true,
                screenInteractive = false,
                lastLaunchAtMillis = 10_000L,
                nowMillis = 10_000L + ChargingScreenPolicy.RELAUNCH_DEBOUNCE_MILLIS,
            ),
        )
    }

    @Test
    fun clockMovingBackwardsDoesNotSuppressLaunch() {
        assertTrue(
            ChargingScreenPolicy.shouldLaunch(
                enabled = true,
                keyguardLocked = true,
                screenInteractive = false,
                lastLaunchAtMillis = 50_000L,
                nowMillis = 10_000L,
            ),
        )
    }
}
