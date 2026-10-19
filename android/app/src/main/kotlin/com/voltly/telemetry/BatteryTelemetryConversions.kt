package com.voltly.telemetry

/**
 * Pure conversion between Android's raw battery units and Voltly's canonical
 * units.
 *
 * Canonical units:
 * - level: percent (0..100)
 * - voltage: volts
 * - temperature: degrees Celsius
 * - current: amperes. Positive means net current entering the battery
 *   (charging); negative means net current leaving it (discharging). This
 *   matches BatteryManager.BATTERY_PROPERTY_CURRENT_NOW and CURRENT_AVERAGE.
 * - charge counter: milliampere-hours (mAh)
 *
 * Every function returns null when the raw value is missing or implausible so
 * callers can expose an explicit unavailable/invalid state instead of zero.
 */
internal object BatteryTelemetryConversions {
    const val UNIT_PERCENT = "percent"
    const val UNIT_VOLTS = "volts"
    const val UNIT_CELSIUS = "celsius"
    const val UNIT_AMPERES = "amperes"
    const val UNIT_MILLIAMPERE_HOURS = "milliampere_hours"

    private const val MIN_PLAUSIBLE_MILLIVOLTS = 1_000
    private const val MAX_PLAUSIBLE_MILLIVOLTS = 20_000
    private const val MIN_PLAUSIBLE_TENTHS_CELSIUS = -400
    private const val MAX_PLAUSIBLE_TENTHS_CELSIUS = 1_000
    private const val MAX_PLAUSIBLE_MICROAMPS = 20_000_000
    private const val MAX_PLAUSIBLE_MICROAMP_HOURS = 100_000_000L

    fun levelToPercent(level: Int, scale: Int): Double? =
        if (scale > 0 && level in 0..scale) level * 100.0 / scale else null

    fun millivoltsToVolts(rawMillivolts: Int): Double? =
        if (rawMillivolts in MIN_PLAUSIBLE_MILLIVOLTS..MAX_PLAUSIBLE_MILLIVOLTS) {
            rawMillivolts / 1_000.0
        } else {
            null
        }

    fun tenthsCelsiusToCelsius(rawTenthsCelsius: Int): Double? =
        if (rawTenthsCelsius in MIN_PLAUSIBLE_TENTHS_CELSIUS..MAX_PLAUSIBLE_TENTHS_CELSIUS) {
            rawTenthsCelsius / 10.0
        } else {
            null
        }

    fun microampsToAmps(rawMicroamps: Int): Double? =
        if (rawMicroamps in -MAX_PLAUSIBLE_MICROAMPS..MAX_PLAUSIBLE_MICROAMPS) {
            rawMicroamps / 1_000_000.0
        } else {
            null
        }

    fun microampHoursToMilliampHours(rawMicroampHours: Long): Double? =
        if (rawMicroampHours in 1..MAX_PLAUSIBLE_MICROAMP_HOURS) {
            rawMicroampHours / 1_000.0
        } else {
            null
        }

    /**
     * Maps BatteryManager.BATTERY_STATUS_* values without referencing the
     * Android class, which keeps this mapping unit-testable on the JVM.
     */
    fun statusName(status: Int): String? = when (status) {
        2 -> "charging" // BATTERY_STATUS_CHARGING
        3 -> "discharging" // BATTERY_STATUS_DISCHARGING
        4 -> "not_charging" // BATTERY_STATUS_NOT_CHARGING
        5 -> "full" // BATTERY_STATUS_FULL
        else -> null
    }

    /**
     * Maps BatteryManager.EXTRA_PLUGGED values. Zero is a valid, reported
     * "not plugged in" state, not a missing value.
     */
    fun plugName(plugged: Int): String? = when (plugged) {
        0 -> "none"
        1 -> "ac" // BATTERY_PLUGGED_AC
        2 -> "usb" // BATTERY_PLUGGED_USB
        4 -> "wireless" // BATTERY_PLUGGED_WIRELESS
        8 -> "dock" // BATTERY_PLUGGED_DOCK (API 33+)
        else -> null
    }
}
