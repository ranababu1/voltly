import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// JSON-safe metadata describing why each snapshot reading is available and
/// where it came from. Scalar values are stored in their own database columns.
Map<String, Object?> encodeAvailabilityMetadata(TelemetrySnapshot snapshot) {
  final TelemetryReading<double> power = calculateBatteryPower(snapshot);
  return <String, Object?>{
    'batteryLevel': _encodeAvailability(snapshot.batteryLevel),
    'chargingState': _encodeAvailability(snapshot.chargingState),
    'plugSource': _encodeAvailability(snapshot.plugSource),
    'voltage': _encodeAvailability(snapshot.voltage),
    'temperature': _encodeAvailability(snapshot.temperature),
    'currentNow': _encodeAvailability(snapshot.currentNow),
    'currentAverage': _encodeAvailability(snapshot.currentAverage),
    'chargeCounter': _encodeAvailability(snapshot.chargeCounter),
    'power': _encodeAvailability(power),
  };
}

/// JSON-safe provenance metadata for a stored sample.
Map<String, Object?> encodeSourceMetadata(TelemetrySnapshot snapshot) {
  final TelemetryReading<double> power = calculateBatteryPower(snapshot);
  return <String, Object?>{
    'snapshotSchemaVersion': snapshot.schemaVersion,
    'readings': <String, Object?>{
      'batteryLevel': snapshot.batteryLevel.source.name,
      'chargingState': snapshot.chargingState.source.name,
      'plugSource': snapshot.plugSource.source.name,
      'voltage': snapshot.voltage.source.name,
      'temperature': snapshot.temperature.source.name,
      'currentNow': snapshot.currentNow.source.name,
      'currentAverage': snapshot.currentAverage.source.name,
      'chargeCounter': snapshot.chargeCounter.source.name,
      'power': power.source.name,
    },
    'powerMethod': 'battery_side_voltage_times_current',
  };
}

Map<String, Object?> _encodeAvailability(TelemetryReading<Object> reading) {
  return <String, Object?>{
    'availability': _availabilityName(reading.availability),
    'observedAtMillis': reading.observedAt.toUtc().millisecondsSinceEpoch,
    if (reading.unit != null) 'unit': reading.unit,
    if (reading.reason != null) 'reason': reading.reason,
  };
}

String _availabilityName(TelemetryAvailability availability) {
  return switch (availability) {
    TelemetryAvailability.available => 'available',
    TelemetryAvailability.unsupported => 'unsupported',
    TelemetryAvailability.temporarilyUnavailable => 'temporarily_unavailable',
    TelemetryAvailability.invalid => 'invalid',
    TelemetryAvailability.stale => 'stale',
  };
}
