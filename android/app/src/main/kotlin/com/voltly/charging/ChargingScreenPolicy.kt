package com.voltly.charging

/**
 * Pure decision rules for the lock-screen charging screen.
 *
 * Kept free of Android types so the rules are covered by local JVM tests.
 */
internal object ChargingScreenPolicy {
    /** Loose connectors can fire several connect broadcasts in a row. */
    const val RELAUNCH_DEBOUNCE_MILLIS = 5_000L

    /**
     * The screen is shown only when the user opted in and the device is
     * locked or its screen is off. While the phone is unlocked and in use,
     * Voltly never interrupts the foreground app.
     */
    fun shouldLaunch(
        enabled: Boolean,
        keyguardLocked: Boolean,
        screenInteractive: Boolean,
        lastLaunchAtMillis: Long?,
        nowMillis: Long,
    ): Boolean {
        if (!enabled) return false
        if (!keyguardLocked && screenInteractive) return false
        if (lastLaunchAtMillis != null &&
            nowMillis - lastLaunchAtMillis in 0 until RELAUNCH_DEBOUNCE_MILLIS
        ) {
            return false
        }
        return true
    }
}
