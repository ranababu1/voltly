import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/telemetry_fixtures.dart';

void main() {
  test('maps available snapshot readings into a sample', () {
    final TelemetrySample sample = TelemetrySample.fromSnapshot(
      parseFixture(),
      sessionId: 12,
    );

    expect(sample.sessionId, 12);
    expect(sample.observedAt, parseFixture().observedAt);
    expect(sample.batteryLevelPercent, 72);
    expect(sample.chargingState, BatteryChargingState.charging);
    expect(sample.voltageVolts, 4.2);
    expect(sample.currentAmps, 1.5);
    expect(sample.temperatureCelsius, 31.5);
    expect(sample.chargeCounterMilliampHours, 3500);
    expect(sample.powerWatts, closeTo(6.3, 0.000001));
  });

  test('keeps unavailable readings null instead of zero', () {
    final TelemetrySample sample = TelemetrySample.fromSnapshot(
      TelemetrySnapshot.fromPlatformPayload(
        telemetryPayload(
          batteryLevel: telemetryReading(
            availability: 'unsupported',
            reason: 'No level',
          ),
          voltage: telemetryReading(
            availability: 'temporarily_unavailable',
            reason: 'No voltage',
          ),
          currentNow: telemetryReading(
            availability: 'unsupported',
            reason: 'No current',
          ),
          temperature: telemetryReading(
            availability: 'invalid',
            reason: 'Bad temperature',
          ),
          chargeCounter: telemetryReading(
            availability: 'unsupported',
            reason: 'No counter',
          ),
        ),
      ),
    );

    expect(sample.batteryLevelPercent, isNull);
    expect(sample.voltageVolts, isNull);
    expect(sample.currentAmps, isNull);
    expect(sample.temperatureCelsius, isNull);
    expect(sample.chargeCounterMilliampHours, isNull);
    expect(sample.powerWatts, isNull);
  });
}
