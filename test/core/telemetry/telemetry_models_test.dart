import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/errors/telemetry_exception.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/telemetry_fixtures.dart';

void main() {
  group('TelemetrySnapshot.fromPlatformPayload', () {
    test('parses a complete available payload', () {
      final TelemetrySnapshot snapshot = parseFixture();

      expect(snapshot.schemaVersion, 1);
      expect(
        snapshot.observedAt,
        DateTime.fromMillisecondsSinceEpoch(
          fixtureObservedAtMillis,
          isUtc: true,
        ),
      );

      expect(snapshot.batteryLevel.value, 72);
      expect(snapshot.batteryLevel.unit, TelemetryUnits.percent);
      expect(snapshot.batteryLevel.source, TelemetrySource.device);
      expect(snapshot.batteryLevel.isAvailable, isTrue);

      expect(snapshot.chargingState.value, BatteryChargingState.charging);
      expect(snapshot.plugSource.value, BatteryPlugSource.usb);
      expect(snapshot.voltage.value, 4.2);
      expect(snapshot.temperature.value, 31.5);
      expect(snapshot.currentNow.value, 1.5);
      expect(snapshot.currentAverage.value, 1.4);
      expect(snapshot.chargeCounter.value, 3500);
      expect(snapshot.chargeCounter.unit, TelemetryUnits.milliampereHours);

      expect(snapshot.voltage.observedAt, snapshot.observedAt);
      expect(snapshot.currentNow.observedAt, snapshot.observedAt);
    });

    test('preserves an explicitly unavailable metric', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          currentNow: telemetryReading(
            availability: 'unsupported',
            reason: 'No current sensor',
          ),
        ),
      );

      expect(snapshot.currentNow.isAvailable, isFalse);
      expect(snapshot.currentNow.value, isNull);
      expect(
        snapshot.currentNow.availability,
        TelemetryAvailability.unsupported,
      );
      expect(snapshot.currentNow.reason, 'No current sensor');
    });

    test('maps temporarily unavailable readings', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          temperature: telemetryReading(
            availability: 'temporarily_unavailable',
            reason: 'Battery service busy',
          ),
        ),
      );

      expect(
        snapshot.temperature.availability,
        TelemetryAvailability.temporarilyUnavailable,
      );
      expect(snapshot.temperature.isAvailable, isFalse);
    });

    test('treats a missing metric as invalid instead of throwing', () {
      final Map<String, Object?> payload = telemetryPayload()
        ..remove('voltage');
      final TelemetrySnapshot snapshot = parseFixture(payload);

      expect(snapshot.voltage.availability, TelemetryAvailability.invalid);
      expect(snapshot.voltage.value, isNull);
      expect(snapshot.voltage.reason, contains('voltage'));
    });

    test('rejects a non-finite numeric value', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          batteryLevel: telemetryReading(
            value: double.nan,
            unit: TelemetryUnits.percent,
          ),
        ),
      );

      expect(snapshot.batteryLevel.availability, TelemetryAvailability.invalid);
      expect(snapshot.batteryLevel.value, isNull);
    });

    test('rejects a numeric value with an unexpected unit', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          voltage: telemetryReading(value: 4200, unit: 'millivolts'),
        ),
      );

      expect(snapshot.voltage.availability, TelemetryAvailability.invalid);
      expect(snapshot.voltage.reason, contains('expected'));
    });

    test('treats an unknown enum value as invalid instead of throwing', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(chargingState: telemetryReading(value: 'trickle')),
      );

      expect(
        snapshot.chargingState.availability,
        TelemetryAvailability.invalid,
      );
      expect(snapshot.chargingState.value, isNull);
      expect(snapshot.chargingState.reason, contains('trickle'));
    });

    test('represents a reported "none" plug source as available', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(plugSource: telemetryReading(value: 'none')),
      );

      expect(snapshot.plugSource.isAvailable, isTrue);
      expect(snapshot.plugSource.value, BatteryPlugSource.none);
    });

    test('treats an unknown availability as invalid', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          plugSource: telemetryReading(value: 'usb', availability: 'probably'),
        ),
      );

      expect(snapshot.plugSource.availability, TelemetryAvailability.invalid);
      expect(snapshot.plugSource.reason, contains('availability'));
    });

    test('treats an unknown source as invalid', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          voltage: telemetryReading(
            value: 4.2,
            unit: TelemetryUnits.volts,
            source: 'vendor_extension',
          ),
        ),
      );

      expect(snapshot.voltage.availability, TelemetryAvailability.invalid);
      expect(snapshot.voltage.reason, contains('source'));
    });

    test('treats a missing per-reading timestamp as invalid', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          temperature: telemetryReading(
            value: 31.5,
            unit: TelemetryUnits.celsius,
            timestampMillis: null,
          ),
        ),
      );

      expect(snapshot.temperature.availability, TelemetryAvailability.invalid);
      expect(snapshot.temperature.reason, contains('timestampMillis'));
    });

    test('keeps metric timestamps independent from the snapshot timestamp', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          voltage: telemetryReading(
            value: 4.1,
            unit: TelemetryUnits.volts,
            timestampMillis: fixtureObservedAtMillis - 1500,
          ),
        ),
      );

      expect(
        snapshot.voltage.observedAt.millisecondsSinceEpoch,
        fixtureObservedAtMillis - 1500,
      );
      expect(snapshot.voltage.value, 4.1);
    });

    test('distinguishes zero from unavailable', () {
      final TelemetrySnapshot snapshot = parseFixture(
        telemetryPayload(
          batteryLevel: telemetryReading(
            value: 0,
            unit: TelemetryUnits.percent,
          ),
          currentNow: telemetryReading(value: 0, unit: TelemetryUnits.amperes),
        ),
      );

      expect(snapshot.batteryLevel.isAvailable, isTrue);
      expect(snapshot.batteryLevel.value, 0);
      expect(snapshot.currentNow.isAvailable, isTrue);
      expect(snapshot.currentNow.value, 0);
    });

    test('rejects an unsupported schema version', () {
      expect(
        () => TelemetrySnapshot.fromPlatformPayload(
          telemetryPayload(schemaVersion: 2),
        ),
        throwsA(
          isA<TelemetryFormatException>().having(
            (TelemetryFormatException error) => error.message,
            'message',
            contains('schema version'),
          ),
        ),
      );
    });

    test('rejects a malformed top-level payload', () {
      expect(
        () => TelemetrySnapshot.fromPlatformPayload(<Object?>[]),
        throwsA(isA<TelemetryFormatException>()),
      );
    });

    test('marks a snapshot stale only after the freshness window', () {
      final TelemetrySnapshot snapshot = parseFixture();

      expect(
        snapshot.isStaleAt(
          snapshot.observedAt.add(const Duration(minutes: 4, seconds: 59)),
        ),
        isFalse,
      );
      expect(
        snapshot.isStaleAt(
          snapshot.observedAt.add(const Duration(minutes: 5, seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
