# Voltly Telemetry Contract v1

Status: implemented in the Kotlin adapter and typed Dart client, and validated
end-to-end on an Android emulator. Physical-device validation is pending. The
telemetry dashboard and developer diagnostics screen are the current UI clients;
both consume this same contract.

This is the authoritative description of the Android-to-Dart battery telemetry
boundary. The Kotlin `BatteryTelemetryReader` is the single acquisition source.
No widget may call these channels or Android APIs directly.

## Transport

| Purpose | Channel | Contract |
| --- | --- | --- |
| Live updates | `com.voltly/telemetry/events` (`EventChannel`) | Emits a snapshot map whenever Android broadcasts `ACTION_BATTERY_CHANGED` while Dart is listening. |
| On-demand read | `com.voltly/telemetry` (`MethodChannel`) | Method `getSnapshot` returns one snapshot map. |

The native receiver is registered in `onListen` and unregistered in `onCancel`
or engine cleanup. The adapter does not poll. Battery broadcasts are
system-driven, so update cadence varies by device and state.

## Snapshot envelope

```json
{
  "schemaVersion": 1,
  "observedAtMillis": 1760918400000,
  "batteryLevel": {
    "value": 72.0,
    "unit": "percent",
    "availability": "available",
    "source": "device",
    "timestampMillis": 1760918400000,
    "reason": null
  }
}
```

The real payload also contains `chargingState`, `plugSource`, `voltage`,
`temperature`, `currentNow`, `currentAverage` and `chargeCounter`.

- `observedAtMillis` is the adapter's capture time (Unix epoch milliseconds,
  UTC), not a hardware sample timestamp.
- Every metric carries its own `timestampMillis`, `availability`, `source` and
  optional `reason`. A metric timestamp is never inferred from another metric.
- Numeric readings carry `unit`. Enum readings (`chargingState`,
  `plugSource`) carry a textual `value` and no unit.
- An unavailable reading has `value: null` and a non-empty `reason` when
  known. It is never represented as `0`.

## Metrics and canonical units

| Key | Unit | Android source | Conversion |
| --- | --- | --- | --- |
| `batteryLevel` | `percent` | `EXTRA_LEVEL` / `EXTRA_SCALE`; fallback `BATTERY_PROPERTY_CAPACITY` | `level * 100 / scale`; property is already percent |
| `chargingState` | none | `EXTRA_STATUS` | `charging`, `discharging`, `not_charging`, `full` |
| `plugSource` | none | `EXTRA_PLUGGED` | `none`, `ac`, `usb`, `wireless`, `dock` |
| `voltage` | `volts` | `EXTRA_VOLTAGE` (millivolts) | divide by 1000 |
| `temperature` | `celsius` | `EXTRA_TEMPERATURE` (tenths of °C) | divide by 10 |
| `currentNow` | `amperes` | `BATTERY_PROPERTY_CURRENT_NOW` (microamperes) | divide by 1,000,000 |
| `currentAverage` | `amperes` | `BATTERY_PROPERTY_CURRENT_AVERAGE` (microamperes) | divide by 1,000,000 |
| `chargeCounter` | `milliampere_hours` | `BATTERY_PROPERTY_CHARGE_COUNTER` (microampere-hours, `getLongProperty`) | `value / 1000` |

Android reports unsupported integer properties as `Integer.MIN_VALUE` and
unsupported long properties as `Long.MIN_VALUE`. These become `unsupported`,
never numeric values.

Plausibility guards reject physically implausible raw values as `invalid`:
voltage outside 1.0-20.0 V, temperature outside -40-100 °C, current outside
-20-20 A, and charge counter outside 1-100,000 mAh. Level must be within its
reported scale.

## Availability

- `available`: usable value from the stated source.
- `unsupported`: Android does not expose the metric on this device.
- `temporarily_unavailable`: the metric exists but could not be read now.
- `invalid`: the payload or raw value failed validation.
- `stale`: never emitted natively. Dart exposes `TelemetrySnapshot.isStaleAt`
  and marks derived power stale when inputs are too far apart.

The per-metric availability map is the capability report. The UI must render
each metric independently and must not crash when one is missing.

## Current and power semantics

- **Current sign:** positive amperes means net current entering the battery
  (charging); negative means net current leaving it (discharging). This matches
  Android's documented `BATTERY_PROPERTY_CURRENT_NOW` and
  `BATTERY_PROPERTY_CURRENT_AVERAGE` convention; Voltly does not invert it.
- **Power:** not sent by the native adapter. Dart derives
  `voltage * currentNow` only when both are available, in canonical units, and
  observed within 2 seconds of each other. It is labeled
  **approximate battery-side power** with `source: calculated`. It is never
  charger input power, wall power or adapter wattage.
- A snapshot more than 5 minutes old must not be presented as live.

## Errors

| Code | Meaning |
| --- | --- |
| `telemetry_read_failed` | Android threw while the snapshot was assembled. |
| `telemetry_receiver_failed` | The battery broadcast receiver could not be registered. |

Dart throws `TelemetryFormatException` for a non-map payload, a missing or
non-integer top-level field, or an unsupported `schemaVersion`. Malformed
individual metrics degrade to `invalid` readings instead of exception-throwing.

## Privacy and permissions

These APIs require no runtime permission. The adapter performs no network
access, no writes and no logging of user data.

## Versioning

`schemaVersion` is `1`. A breaking payload change requires a version bump and
updating the Kotlin adapter, Dart model, Dart tests and this document in the
same buildable increment.
