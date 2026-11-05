import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/telemetry/live_current.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

import '../../support/fake_battery_telemetry_service.dart';
import '../../support/telemetry_fixtures.dart';

TelemetrySnapshot _snap(
  DateTime at, {
  double? amps,
  String plug = 'usb',
  String state = 'charging',
}) {
  final int ms = at.millisecondsSinceEpoch;
  return TelemetrySnapshot.fromPlatformPayload(
    telemetryPayload(
      observedAtMillis: ms,
      plugSource: telemetryReading(value: plug, timestampMillis: ms),
      chargingState: telemetryReading(value: state, timestampMillis: ms),
      currentNow: amps == null
          ? telemetryReading(availability: 'unsupported', timestampMillis: ms)
          : telemetryReading(
              value: amps,
              unit: TelemetryUnits.amperes,
              timestampMillis: ms,
            ),
    ),
  );
}

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 1, 12);
  late ProviderContainer container;
  late LiveCurrentController controller;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        batteryTelemetryServiceProvider.overrideWithValue(
          FakeBatteryTelemetryService(),
        ),
      ],
    );
    container.read(liveCurrentProvider);
    controller = container.read(liveCurrentProvider.notifier);
  });
  tearDown(() => container.dispose());

  LiveCurrentState read() => container.read(liveCurrentProvider);

  test('tracks min, average and max in milliamperes', () {
    controller.observe(_snap(t0, amps: 1.0));
    expect(read().hasStats, isFalse);
    controller.observe(_snap(t0.add(const Duration(seconds: 1)), amps: 2.0));
    controller.observe(_snap(t0.add(const Duration(seconds: 2)), amps: 1.5));

    final LiveCurrentState state = read();
    expect(state.hasStats, isTrue);
    expect(state.minMilliamps, 1000);
    expect(state.maxMilliamps, 2000);
    expect(state.averageMilliamps, closeTo(1500, 1e-9));
    expect(state.history, hasLength(3));
    expect(state.pluggedIn, isTrue);
  });

  test('ignores duplicate and out-of-order observations', () {
    controller.observe(_snap(t0, amps: 1.0));
    controller.observe(_snap(t0, amps: 9.0));
    controller.observe(_snap(t0.subtract(const Duration(seconds: 1)), amps: 9));
    expect(read().sampleCount, 1);
    expect(read().maxMilliamps, 1000);
  });

  test('unplugging starts a fresh phase', () {
    controller.observe(_snap(t0, amps: 2.0));
    controller.observe(_snap(t0.add(const Duration(seconds: 1)), amps: 2.2));
    controller.observe(
      _snap(
        t0.add(const Duration(seconds: 2)),
        amps: -0.4,
        plug: 'none',
        state: 'discharging',
      ),
    );

    final LiveCurrentState state = read();
    expect(state.pluggedIn, isFalse);
    expect(state.sampleCount, 1);
    expect(state.maxMilliamps, closeTo(-400, 1e-9));
    expect(state.history, hasLength(1));
  });

  test('drops history older than the window', () {
    controller.observe(_snap(t0, amps: 1.0));
    controller.observe(
      _snap(
        t0.add(
          LiveCurrentController.historyWindow + const Duration(seconds: 1),
        ),
        amps: 1.1,
      ),
    );
    expect(read().history, hasLength(1));
    expect(read().sampleCount, 2);
  });

  test('unavailable current never becomes a zero reading', () {
    controller.observe(_snap(t0));
    expect(read().sampleCount, 0);
    expect(read().history, isEmpty);
    expect(read().minMilliamps, isNull);
  });

  test('reset clears statistics but keeps the phase', () {
    controller.observe(_snap(t0, amps: 1.0));
    controller.reset();
    expect(read().sampleCount, 0);
    expect(read().pluggedIn, isTrue);
  });
}
