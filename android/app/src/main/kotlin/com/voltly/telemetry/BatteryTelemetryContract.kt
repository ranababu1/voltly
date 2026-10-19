package com.voltly.telemetry

/**
 * Versioned contract shared with Dart.
 *
 * Keep this in sync with lib/core/telemetry/telemetry_models.dart and
 * docs/telemetry-contract.md. A breaking change requires a schema version
 * bump and matching Dart parsing plus tests in the same increment.
 */
internal object BatteryTelemetryContract {
    const val SCHEMA_VERSION = 1

    const val METHOD_CHANNEL = "com.voltly/telemetry"
    const val EVENT_CHANNEL = "com.voltly/telemetry/events"
    const val METHOD_GET_SNAPSHOT = "getSnapshot"

    const val KEY_SCHEMA_VERSION = "schemaVersion"
    const val KEY_OBSERVED_AT_MILLIS = "observedAtMillis"
    const val KEY_VALUE = "value"
    const val KEY_UNIT = "unit"
    const val KEY_AVAILABILITY = "availability"
    const val KEY_SOURCE = "source"
    const val KEY_TIMESTAMP_MILLIS = "timestampMillis"
    const val KEY_REASON = "reason"

    const val METRIC_BATTERY_LEVEL = "batteryLevel"
    const val METRIC_CHARGING_STATE = "chargingState"
    const val METRIC_PLUG_SOURCE = "plugSource"
    const val METRIC_VOLTAGE = "voltage"
    const val METRIC_TEMPERATURE = "temperature"
    const val METRIC_CURRENT_NOW = "currentNow"
    const val METRIC_CURRENT_AVERAGE = "currentAverage"
    const val METRIC_CHARGE_COUNTER = "chargeCounter"

    const val AVAILABILITY_AVAILABLE = "available"
    const val AVAILABILITY_UNSUPPORTED = "unsupported"
    const val AVAILABILITY_TEMPORARILY_UNAVAILABLE = "temporarily_unavailable"
    const val AVAILABILITY_INVALID = "invalid"

    const val SOURCE_DEVICE = "device"
}
