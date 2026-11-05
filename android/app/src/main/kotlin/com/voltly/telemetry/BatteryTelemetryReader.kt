package com.voltly.telemetry

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build

/**
 * The single native source of battery telemetry.
 *
 * It reads only Android's documented battery APIs, converts raw units once
 * here, and reports each metric independently with availability and reason
 * metadata. Missing values are never coerced to zero.
 */
internal class BatteryTelemetryReader(private val context: Context) {
    private val batteryManager =
        context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
    private val calibrationPrefs =
        context.getSharedPreferences(CALIBRATION_PREFS, Context.MODE_PRIVATE)
    private val calibration = CurrentCalibration(
        reportsMilliamps = calibrationPrefs.getBoolean(KEY_REPORTS_MILLIAMPS, false),
        signInverted = calibrationPrefs.getBoolean(KEY_SIGN_INVERTED, false),
        signLearned = calibrationPrefs.getBoolean(KEY_SIGN_LEARNED, false),
    )

    fun read(): Map<String, Any?> = read(stickyBatteryIntent())

    fun read(intent: Intent?): Map<String, Any?> {
        val observedAtMillis = System.currentTimeMillis()
        val pluggedRaw = intent?.takeIf { it.hasExtra(BatteryManager.EXTRA_PLUGGED) }
            ?.getIntExtra(BatteryManager.EXTRA_PLUGGED, Int.MIN_VALUE)
        val statusName = BatteryTelemetryConversions.statusName(
            intent?.getIntExtra(BatteryManager.EXTRA_STATUS, Int.MIN_VALUE)
                ?: Int.MIN_VALUE,
        )
        val currentNow = readIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        val currentAverage =
            readIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_AVERAGE)
        if (calibration.observe(currentNow.value?.toInt(), pluggedRaw, statusName)) {
            persistCalibration()
        }

        return mapOf(
            BatteryTelemetryContract.KEY_SCHEMA_VERSION to
                BatteryTelemetryContract.SCHEMA_VERSION,
            BatteryTelemetryContract.KEY_OBSERVED_AT_MILLIS to observedAtMillis,
            BatteryTelemetryContract.METRIC_BATTERY_LEVEL to
                readLevel(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_CHARGING_STATE to
                readChargingState(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_PLUG_SOURCE to
                readPlugSource(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_VOLTAGE to
                readVoltage(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_TEMPERATURE to
                readTemperature(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_CURRENT_NOW to
                readCurrent(currentNow, statusName, observedAtMillis),
            BatteryTelemetryContract.METRIC_CURRENT_AVERAGE to
                readCurrent(currentAverage, statusName, observedAtMillis),
            BatteryTelemetryContract.METRIC_CHARGE_COUNTER to
                readChargeCounter(observedAtMillis),
            BatteryTelemetryContract.METRIC_HEALTH to
                readHealth(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_TECHNOLOGY to
                readTechnology(intent, observedAtMillis),
            BatteryTelemetryContract.METRIC_CYCLE_COUNT to
                readCycleCount(intent, observedAtMillis),
        )
    }

    private fun persistCalibration() {
        calibrationPrefs.edit()
            .putBoolean(KEY_REPORTS_MILLIAMPS, calibration.reportsMilliamps)
            .putBoolean(KEY_SIGN_INVERTED, calibration.signInverted)
            .putBoolean(KEY_SIGN_LEARNED, calibration.signLearned)
            .apply()
    }

    private fun readHealth(intent: Intent?, timestampMillis: Long): Map<String, Any?> {
        val raw = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, Int.MIN_VALUE)
            ?: Int.MIN_VALUE
        val name = BatteryTelemetryConversions.healthName(raw)
        return if (name != null) {
            availableTextReading(name, timestampMillis)
        } else {
            unavailableTextReading(
                BatteryTelemetryContract.AVAILABILITY_UNSUPPORTED,
                "Android did not report a battery health state.",
                timestampMillis,
            )
        }
    }

    private fun readTechnology(
        intent: Intent?,
        timestampMillis: Long,
    ): Map<String, Any?> {
        val name = BatteryTelemetryConversions.technologyName(
            intent?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY),
        )
        return if (name != null) {
            availableTextReading(name, timestampMillis)
        } else {
            unavailableTextReading(
                BatteryTelemetryContract.AVAILABILITY_UNSUPPORTED,
                "Android did not report the battery technology.",
                timestampMillis,
            )
        }
    }

    private fun readCycleCount(
        intent: Intent?,
        timestampMillis: Long,
    ): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ||
            intent?.hasExtra(BatteryManager.EXTRA_CYCLE_COUNT) != true
        ) {
            return unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_COUNT,
                BatteryTelemetryContract.AVAILABILITY_UNSUPPORTED,
                "Cycle count is reported only on Android 14+ devices that expose it.",
                timestampMillis,
            )
        }
        val raw = intent.getIntExtra(BatteryManager.EXTRA_CYCLE_COUNT, Int.MIN_VALUE)
        val cycles = BatteryTelemetryConversions.cycleCount(raw)
        return if (cycles != null) {
            availableNumericReading(
                cycles,
                BatteryTelemetryConversions.UNIT_COUNT,
                timestampMillis,
            )
        } else {
            unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_COUNT,
                BatteryTelemetryContract.AVAILABILITY_INVALID,
                "Cycle count was outside the plausible range.",
                timestampMillis,
            )
        }
    }

    private fun stickyBatteryIntent(): Intent? = try {
        context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    } catch (_: RuntimeException) {
        null
    }

    private fun readLevel(intent: Intent?, timestampMillis: Long): Map<String, Any?> {
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, Int.MIN_VALUE)
            ?: Int.MIN_VALUE
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, Int.MIN_VALUE)
            ?: Int.MIN_VALUE
        val broadcastPercent =
            BatteryTelemetryConversions.levelToPercent(level, scale)
        if (broadcastPercent != null) {
            return availableNumericReading(
                broadcastPercent,
                BatteryTelemetryConversions.UNIT_PERCENT,
                timestampMillis,
            )
        }

        val capacity = readIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val propertyValue = capacity.value
        if (propertyValue != null) {
            return if (propertyValue in 0..100) {
                availableNumericReading(
                    propertyValue.toDouble(),
                    BatteryTelemetryConversions.UNIT_PERCENT,
                    timestampMillis,
                )
            } else {
                unavailableNumericReading(
                    BatteryTelemetryConversions.UNIT_PERCENT,
                    BatteryTelemetryContract.AVAILABILITY_INVALID,
                    "Battery capacity was outside the documented 0..100% range.",
                    timestampMillis,
                )
            }
        }
        return unavailableNumericReading(
            BatteryTelemetryConversions.UNIT_PERCENT,
            capacity.availability,
            capacity.reason ?: "Battery level was not reported by Android.",
            timestampMillis,
        )
    }

    private fun readChargingState(
        intent: Intent?,
        timestampMillis: Long,
    ): Map<String, Any?> {
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, Int.MIN_VALUE)
            ?: Int.MIN_VALUE
        val name = BatteryTelemetryConversions.statusName(status)
        return if (name != null) {
            availableTextReading(name, timestampMillis)
        } else {
            unavailableTextReading(
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "Android did not report a defined charging state.",
                timestampMillis,
            )
        }
    }

    private fun readPlugSource(
        intent: Intent?,
        timestampMillis: Long,
    ): Map<String, Any?> {
        val plugged = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, Int.MIN_VALUE)
            ?: Int.MIN_VALUE
        val name = BatteryTelemetryConversions.plugName(plugged)
        return if (name != null) {
            availableTextReading(name, timestampMillis)
        } else {
            unavailableTextReading(
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "Android did not report a valid power source.",
                timestampMillis,
            )
        }
    }

    private fun readVoltage(intent: Intent?, timestampMillis: Long): Map<String, Any?> {
        if (intent?.hasExtra(BatteryManager.EXTRA_VOLTAGE) != true) {
            return unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_VOLTS,
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "Voltage was not included in the battery broadcast.",
                timestampMillis,
            )
        }
        val rawMillivolts =
            intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, Int.MIN_VALUE)
        val volts = BatteryTelemetryConversions.millivoltsToVolts(rawMillivolts)
        return if (volts != null) {
            availableNumericReading(
                volts,
                BatteryTelemetryConversions.UNIT_VOLTS,
                timestampMillis,
            )
        } else {
            unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_VOLTS,
                BatteryTelemetryContract.AVAILABILITY_INVALID,
                "Voltage was outside the plausible 1.0..20.0 V range.",
                timestampMillis,
            )
        }
    }

    private fun readTemperature(
        intent: Intent?,
        timestampMillis: Long,
    ): Map<String, Any?> {
        if (intent?.hasExtra(BatteryManager.EXTRA_TEMPERATURE) != true) {
            return unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_CELSIUS,
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "Temperature was not included in the battery broadcast.",
                timestampMillis,
            )
        }
        val rawTenths =
            intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
        val celsius =
            BatteryTelemetryConversions.tenthsCelsiusToCelsius(rawTenths)
        return if (celsius != null) {
            availableNumericReading(
                celsius,
                BatteryTelemetryConversions.UNIT_CELSIUS,
                timestampMillis,
            )
        } else {
            unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_CELSIUS,
                BatteryTelemetryContract.AVAILABILITY_INVALID,
                "Temperature was outside the plausible -40..100 °C range.",
                timestampMillis,
            )
        }
    }

    private fun readCurrent(
        property: PropertyResult,
        statusName: String?,
        timestampMillis: Long,
    ): Map<String, Any?> {
        val raw = property.value?.toInt()
        if (raw == null) {
            return unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_AMPERES,
                property.availability,
                property.reason ?: "Current was not reported by Android.",
                timestampMillis,
            )
        }
        val amperes = calibration.toAmperes(raw, statusName)
        return if (amperes != null) {
            availableNumericReading(
                amperes,
                BatteryTelemetryConversions.UNIT_AMPERES,
                timestampMillis,
            )
        } else {
            unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_AMPERES,
                BatteryTelemetryContract.AVAILABILITY_INVALID,
                "Current was outside the plausible -20..20 A range.",
                timestampMillis,
            )
        }
    }

    private fun readChargeCounter(timestampMillis: Long): Map<String, Any?> {
        val property =
            readLongProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
        val rawMicroampHours = property.value
        if (rawMicroampHours == null) {
            return unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_MILLIAMPERE_HOURS,
                property.availability,
                property.reason ?: "Charge counter was not reported by Android.",
                timestampMillis,
            )
        }
        val milliampHours =
            BatteryTelemetryConversions.microampHoursToMilliampHours(
                rawMicroampHours,
            )
        return if (milliampHours != null) {
            availableNumericReading(
                milliampHours,
                BatteryTelemetryConversions.UNIT_MILLIAMPERE_HOURS,
                timestampMillis,
            )
        } else {
            unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_MILLIAMPERE_HOURS,
                BatteryTelemetryContract.AVAILABILITY_INVALID,
                "Charge counter was non-positive or outside the plausible range.",
                timestampMillis,
            )
        }
    }

    private fun readIntProperty(propertyId: Int): PropertyResult {
        val manager = batteryManager
            ?: return PropertyResult(
                null,
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "BatteryManager is unavailable on this device.",
            )
        return try {
            val raw = manager.getIntProperty(propertyId)
            if (raw == Int.MIN_VALUE) {
                PropertyResult(
                    null,
                    BatteryTelemetryContract.AVAILABILITY_UNSUPPORTED,
                    "Android does not expose this battery property.",
                )
            } else {
                PropertyResult(
                    raw.toLong(),
                    BatteryTelemetryContract.AVAILABILITY_AVAILABLE,
                    null,
                )
            }
        } catch (_: RuntimeException) {
            PropertyResult(
                null,
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "Android could not read this battery property.",
            )
        }
    }

    private fun readLongProperty(propertyId: Int): PropertyResult {
        val manager = batteryManager
            ?: return PropertyResult(
                null,
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "BatteryManager is unavailable on this device.",
            )
        return try {
            val raw = manager.getLongProperty(propertyId)
            if (raw == Long.MIN_VALUE) {
                PropertyResult(
                    null,
                    BatteryTelemetryContract.AVAILABILITY_UNSUPPORTED,
                    "Android does not expose this battery property.",
                )
            } else {
                PropertyResult(
                    raw,
                    BatteryTelemetryContract.AVAILABILITY_AVAILABLE,
                    null,
                )
            }
        } catch (_: RuntimeException) {
            PropertyResult(
                null,
                BatteryTelemetryContract.AVAILABILITY_TEMPORARILY_UNAVAILABLE,
                "Android could not read this battery property.",
            )
        }
    }

    private fun availableNumericReading(
        value: Double,
        unit: String,
        timestampMillis: Long,
    ): Map<String, Any?> = readingMap(
        value = value,
        unit = unit,
        availability = BatteryTelemetryContract.AVAILABILITY_AVAILABLE,
        reason = null,
        timestampMillis = timestampMillis,
    )

    private fun unavailableNumericReading(
        unit: String,
        availability: String,
        reason: String,
        timestampMillis: Long,
    ): Map<String, Any?> = readingMap(
        value = null,
        unit = unit,
        availability = availability,
        reason = reason,
        timestampMillis = timestampMillis,
    )

    private fun availableTextReading(
        value: String,
        timestampMillis: Long,
    ): Map<String, Any?> = readingMap(
        value = value,
        unit = null,
        availability = BatteryTelemetryContract.AVAILABILITY_AVAILABLE,
        reason = null,
        timestampMillis = timestampMillis,
    )

    private fun unavailableTextReading(
        availability: String,
        reason: String,
        timestampMillis: Long,
    ): Map<String, Any?> = readingMap(
        value = null,
        unit = null,
        availability = availability,
        reason = reason,
        timestampMillis = timestampMillis,
    )

    private fun readingMap(
        value: Any?,
        unit: String?,
        availability: String,
        reason: String?,
        timestampMillis: Long,
    ): Map<String, Any?> = mapOf(
        BatteryTelemetryContract.KEY_VALUE to value,
        BatteryTelemetryContract.KEY_UNIT to unit,
        BatteryTelemetryContract.KEY_AVAILABILITY to availability,
        BatteryTelemetryContract.KEY_SOURCE to
            BatteryTelemetryContract.SOURCE_DEVICE,
        BatteryTelemetryContract.KEY_TIMESTAMP_MILLIS to timestampMillis,
        BatteryTelemetryContract.KEY_REASON to reason,
    )

    private data class PropertyResult(
        val value: Long?,
        val availability: String,
        val reason: String?,
    )

    private companion object {
        const val CALIBRATION_PREFS = "voltly_current_calibration"
        const val KEY_REPORTS_MILLIAMPS = "reportsMilliamps"
        const val KEY_SIGN_INVERTED = "signInverted"
        const val KEY_SIGN_LEARNED = "signLearned"
    }
}
