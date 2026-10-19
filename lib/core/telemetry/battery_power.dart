import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Maximum age difference allowed between voltage and current when deriving
/// power. Beyond this, the inputs are not considered contemporaneous.
const Duration batteryPowerMaxInputSkew = Duration(seconds: 2);

/// Derives approximate **battery-side** power from voltage and current.
///
/// Positive watts mean energy flowing into the battery; negative watts mean
/// energy leaving it. This is never wall-charger or adapter input power.
/// Returns an explicit unavailable/invalid/stale reading rather than zero when
/// either input cannot support the calculation.
TelemetryReading<double> calculateBatteryPower(TelemetrySnapshot snapshot) {
  final TelemetryReading<double> voltage = snapshot.voltage;
  final TelemetryReading<double> current = snapshot.currentNow;
  final DateTime observedAt = voltage.observedAt.isAfter(current.observedAt)
      ? voltage.observedAt
      : current.observedAt;

  if (!voltage.isAvailable || !current.isAvailable) {
    return TelemetryReading<double>(
      availability: _unavailableAvailability(voltage, current),
      source: TelemetrySource.calculated,
      observedAt: observedAt,
      unit: TelemetryUnits.watts,
      reason:
          'Battery-side power needs available voltage and current readings.',
    );
  }

  if (voltage.unit != TelemetryUnits.volts ||
      current.unit != TelemetryUnits.amperes) {
    return TelemetryReading<double>(
      availability: TelemetryAvailability.invalid,
      source: TelemetrySource.calculated,
      observedAt: observedAt,
      unit: TelemetryUnits.watts,
      reason: 'Voltage or current used an unexpected unit.',
    );
  }

  final double volts = voltage.value!;
  final double amperes = current.value!;
  final Duration skew = voltage.observedAt.difference(current.observedAt).abs();
  if (skew > batteryPowerMaxInputSkew) {
    return TelemetryReading<double>(
      availability: TelemetryAvailability.stale,
      source: TelemetrySource.calculated,
      observedAt: observedAt,
      unit: TelemetryUnits.watts,
      reason: 'Voltage and current were not observed close enough in time.',
    );
  }

  final double watts = volts * amperes;
  if (!watts.isFinite) {
    return TelemetryReading<double>(
      availability: TelemetryAvailability.invalid,
      source: TelemetrySource.calculated,
      observedAt: observedAt,
      unit: TelemetryUnits.watts,
      reason: 'The derived power value was not finite.',
    );
  }

  return TelemetryReading<double>(
    value: watts,
    unit: TelemetryUnits.watts,
    availability: TelemetryAvailability.available,
    source: TelemetrySource.calculated,
    observedAt: observedAt,
    reason: 'Approximate battery-side power; not wall-charger or adapter input power.',
  );
}

TelemetryAvailability _unavailableAvailability(
  TelemetryReading<double> voltage,
  TelemetryReading<double> current,
) {
  final List<TelemetryAvailability> inputs = <TelemetryAvailability>[
    voltage.availability,
    current.availability,
  ];
  if (inputs.contains(TelemetryAvailability.invalid)) {
    return TelemetryAvailability.invalid;
  }
  if (inputs.contains(TelemetryAvailability.unsupported)) {
    return TelemetryAvailability.unsupported;
  }
  return TelemetryAvailability.temporarilyUnavailable;
}
