import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Fixed observation time used by telemetry fixtures (2025-10-20T00:00:00Z).
const int fixtureObservedAtMillis = 1760918400000;

Map<String, Object?> telemetryReading({
  Object? value,
  String? unit,
  String availability = 'available',
  String source = 'device',
  int? timestampMillis = fixtureObservedAtMillis,
  String? reason,
}) => <String, Object?>{
  'value': value,
  'unit': unit,
  'availability': availability,
  'source': source,
  'timestampMillis': timestampMillis,
  'reason': reason,
};

Map<String, Object?> telemetryPayload({
  int schemaVersion = 1,
  int observedAtMillis = fixtureObservedAtMillis,
  Map<String, Object?>? batteryLevel,
  Map<String, Object?>? chargingState,
  Map<String, Object?>? plugSource,
  Map<String, Object?>? voltage,
  Map<String, Object?>? temperature,
  Map<String, Object?>? currentNow,
  Map<String, Object?>? currentAverage,
  Map<String, Object?>? chargeCounter,
}) => <String, Object?>{
  'schemaVersion': schemaVersion,
  'observedAtMillis': observedAtMillis,
  'batteryLevel':
      batteryLevel ?? telemetryReading(value: 72, unit: TelemetryUnits.percent),
  'chargingState': chargingState ?? telemetryReading(value: 'charging'),
  'plugSource': plugSource ?? telemetryReading(value: 'usb'),
  'voltage':
      voltage ?? telemetryReading(value: 4.2, unit: TelemetryUnits.volts),
  'temperature':
      temperature ??
      telemetryReading(value: 31.5, unit: TelemetryUnits.celsius),
  'currentNow':
      currentNow ?? telemetryReading(value: 1.5, unit: TelemetryUnits.amperes),
  'currentAverage':
      currentAverage ??
      telemetryReading(value: 1.4, unit: TelemetryUnits.amperes),
  'chargeCounter':
      chargeCounter ??
      telemetryReading(value: 3500, unit: TelemetryUnits.milliampereHours),
};

TelemetrySnapshot parseFixture([Map<String, Object?>? payload]) =>
    TelemetrySnapshot.fromPlatformPayload(payload ?? telemetryPayload());
