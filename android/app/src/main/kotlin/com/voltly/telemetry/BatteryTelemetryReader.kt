package com.voltly.telemetry

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager

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

    fun read(): Map<String, Any?> = read(stickyBatteryIntent())

    fun read(intent: Intent?): Map<String, Any?> {
        val observedAtMillis = System.currentTimeMillis()
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
                readCurrent(
                    BatteryManager.BATTERY_PROPERTY_CURRENT_NOW,
                    observedAtMillis,
                ),
            BatteryTelemetryContract.METRIC_CURRENT_AVERAGE to
                readCurrent(
                    BatteryManager.BATTERY_PROPERTY_CURRENT_AVERAGE,
                    observedAtMillis,
                ),
            BatteryTelemetryContract.METRIC_CHARGE_COUNTER to
                readChargeCounter(observedAtMillis),
        )
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
        propertyId: Int,
        timestampMillis: Long,
    ): Map<String, Any?> {
        val property = readIntProperty(propertyId)
        val rawMicroamps = property.value?.toInt()
        if (rawMicroamps == null) {
            return unavailableNumericReading(
                BatteryTelemetryConversions.UNIT_AMPERES,
                property.availability,
                property.reason ?: "Current was not reported by Android.",
                timestampMillis,
            )
        }
        val amperes =
            BatteryTelemetryConversions.microampsToAmps(rawMicroamps)
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
}
