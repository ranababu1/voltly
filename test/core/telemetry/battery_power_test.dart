import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/telemetry_fixtures.dart';

void main() {
  group('calculateBatteryPower', () {
    test('derives positive battery-side watts while charging', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(),
      );

      expect(power.isAvailable, isTrue);
      expect(power.value, closeTo(6.3, 0.000001));
      expect(power.unit, TelemetryUnits.watts);
      expect(power.source, TelemetrySource.calculated);
      expect(power.reason, contains('battery-side'));
    });

    test('derives negative battery-side watts while discharging', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(
          telemetryPayload(
            currentNow: telemetryReading(
              value: -0.5,
              unit: TelemetryUnits.amperes,
            ),
          ),
        ),
      );

      expect(power.isAvailable, isTrue);
      expect(power.value, closeTo(-2.1, 0.000001));
      expect(power.source, TelemetrySource.calculated);
    });

    test('reports unavailable power when current is unsupported', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(
          telemetryPayload(
            currentNow: telemetryReading(
              availability: 'unsupported',
              reason: 'No current sensor',
            ),
          ),
        ),
      );

      expect(power.isAvailable, isFalse);
      expect(power.value, isNull);
      expect(power.availability, TelemetryAvailability.unsupported);
      expect(power.source, TelemetrySource.calculated);
    });

    test('reports invalid power when an input is invalid', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(
          telemetryPayload(
            voltage: telemetryReading(
              value: double.infinity,
              unit: TelemetryUnits.volts,
            ),
          ),
        ),
      );

      expect(power.isAvailable, isFalse);
      expect(power.availability, TelemetryAvailability.invalid);
    });

    test('marks power stale when inputs are not contemporaneous', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(
          telemetryPayload(
            voltage: telemetryReading(
              value: 4.2,
              unit: TelemetryUnits.volts,
              timestampMillis: fixtureObservedAtMillis - 2001,
            ),
          ),
        ),
      );

      expect(power.isAvailable, isFalse);
      expect(power.availability, TelemetryAvailability.stale);
      expect(power.reason, contains('close enough in time'));
    });

    test('accepts inputs exactly at the maximum skew', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(
          telemetryPayload(
            voltage: telemetryReading(
              value: 4.2,
              unit: TelemetryUnits.volts,
              timestampMillis: fixtureObservedAtMillis - 2000,
            ),
          ),
        ),
      );

      expect(power.isAvailable, isTrue);
      expect(power.value, closeTo(6.3, 0.000001));
    });

    test('keeps zero current as available zero power', () {
      final TelemetryReading<double> power = calculateBatteryPower(
        parseFixture(
          telemetryPayload(
            currentNow: telemetryReading(
              value: 0,
              unit: TelemetryUnits.amperes,
            ),
          ),
        ),
      );

      expect(power.isAvailable, isTrue);
      expect(power.value, 0);
    });
  });
}
