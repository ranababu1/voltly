import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// A real telemetry observation captured during a session.
///
/// The original snapshot is retained so every value keeps its availability,
/// timestamp and provenance. Convenience getters return null when a metric is
/// unavailable; they never substitute zero.
class TelemetrySample {
  const TelemetrySample({required this.snapshot, this.id, this.sessionId});

  factory TelemetrySample.fromSnapshot(
    TelemetrySnapshot snapshot, {
    int? id,
    int? sessionId,
  }) {
    return TelemetrySample(snapshot: snapshot, id: id, sessionId: sessionId);
  }

  final int? id;
  final int? sessionId;
  final TelemetrySnapshot snapshot;

  DateTime get observedAt => snapshot.observedAt;

  double? get batteryLevelPercent =>
      snapshot.batteryLevel.isAvailable ? snapshot.batteryLevel.value : null;

  BatteryChargingState? get chargingState =>
      snapshot.chargingState.isAvailable ? snapshot.chargingState.value : null;

  double? get voltageVolts =>
      snapshot.voltage.isAvailable ? snapshot.voltage.value : null;

  double? get currentAmps =>
      snapshot.currentNow.isAvailable ? snapshot.currentNow.value : null;

  double? get temperatureCelsius =>
      snapshot.temperature.isAvailable ? snapshot.temperature.value : null;

  double? get chargeCounterMilliampHours =>
      snapshot.chargeCounter.isAvailable ? snapshot.chargeCounter.value : null;

  /// Calculated battery-side power, or null when its inputs are unavailable or
  /// not contemporaneous.
  double? get powerWatts {
    final TelemetryReading<double> power = calculateBatteryPower(snapshot);
    return power.isAvailable ? power.value : null;
  }

  TelemetrySample copyWith({int? id, int? sessionId}) {
    return TelemetrySample(
      snapshot: snapshot,
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  String toString() =>
      'TelemetrySample(id: $id, sessionId: $sessionId, '
      'observedAt: $observedAt, level: $batteryLevelPercent, '
      'chargingState: ${chargingState?.name})';
}
