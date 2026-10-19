import 'package:voltly/core/telemetry/telemetry_models.dart';

import 'telemetry_fixtures.dart';

/// Snapshot at [at] with a controllable charging state and battery level.
TelemetrySnapshot sessionSnapshot({
  required DateTime at,
  String state = 'charging',
  bool stateAvailable = true,
  double level = 50,
  bool levelAvailable = true,
}) {
  final int millis = at.toUtc().millisecondsSinceEpoch;
  return TelemetrySnapshot.fromPlatformPayload(
    telemetryPayload(
      observedAtMillis: millis,
      chargingState: stateAvailable
          ? telemetryReading(value: state, timestampMillis: millis)
          : telemetryReading(
              availability: 'temporarily_unavailable',
              reason: 'Charging state unavailable',
              timestampMillis: millis,
            ),
      batteryLevel: levelAvailable
          ? telemetryReading(
              value: level,
              unit: TelemetryUnits.percent,
              timestampMillis: millis,
            )
          : telemetryReading(
              availability: 'unsupported',
              reason: 'Battery level unavailable',
              timestampMillis: millis,
            ),
    ),
  );
}
