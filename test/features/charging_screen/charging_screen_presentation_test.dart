import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/features/charging_screen/charging_screen_presentation.dart';

TelemetryReading<double> _reading(double? value) => TelemetryReading<double>(
  value: value,
  availability: value == null
      ? TelemetryAvailability.unsupported
      : TelemetryAvailability.available,
  source: TelemetrySource.device,
  observedAt: DateTime.utc(2026, 10, 23),
);

BatteryEstimateResult _estimate(
  Duration remaining, {
  BatteryEstimateKind kind = BatteryEstimateKind.timeToFull,
  bool targetReached = false,
}) => BatteryEstimateResult.available(
  BatteryTimeEstimate(
    kind: kind,
    remaining: remaining,
    sampleCount: 5,
    observedWindow: const Duration(minutes: 12),
    latestLevelPercent: 66,
    ratePercentPerHour: 50,
    targetReached: targetReached,
    sessionHadSamplingGaps: false,
    sessionSamplesPruned: false,
  ),
);

void main() {
  test('formats the clock in 24-hour and 12-hour styles', () {
    final DateTime time = DateTime(2026, 10, 23, 0, 4);
    expect(formatChargingClock(time, use24HourFormat: true), '00:04');
    expect(formatChargingClock(time, use24HourFormat: false), '12:04');
    expect(
      formatChargingClock(
        DateTime(2026, 10, 23, 15, 30),
        use24HourFormat: false,
      ),
      '3:30',
    );
  });

  test('formats the date like the lock screen', () {
    expect(formatChargingDate(DateTime(2026, 10, 23)), '23 Oct 2026');
  });

  test('tile values are null when readings are unavailable', () {
    expect(formatTileTemperature(_reading(null)), isNull);
    expect(formatTileCurrent(_reading(null)), isNull);
    expect(formatTilePower(_reading(null)), isNull);
    expect(formatTileEstimate(null), isNull);
    expect(
      formatTileEstimate(const BatteryEstimateResult.unavailable('Too early')),
      isNull,
    );
  });

  test('tile values keep zero as a real reading', () {
    expect(formatTileCurrent(_reading(0)), '0 mA');
    expect(formatTileTemperature(_reading(28.44)), '28.4°C');
    expect(formatTileCurrent(_reading(4.0134)), '4013 mA');
    expect(formatTileCurrent(_reading(-0.25)), '-250 mA');
    expect(formatTilePower(_reading(15.904)), '15.9 W');
  });

  test('compact estimate rounds to five minutes', () {
    expect(formatTileEstimate(_estimate(const Duration(minutes: 2))), '<5m');
    expect(formatTileEstimate(_estimate(const Duration(minutes: 38))), '~40m');
    expect(formatTileEstimate(_estimate(const Duration(minutes: 60))), '~1h');
    expect(
      formatTileEstimate(_estimate(const Duration(minutes: 87))),
      '~1h 25m',
    );
    expect(
      formatTileEstimate(_estimate(Duration.zero, targetReached: true)),
      'Full',
    );
  });

  test('estimate label follows the estimate direction', () {
    expect(estimateTileLabel(null), 'Estimate');
    expect(
      estimateTileLabel(_estimate(const Duration(minutes: 30))),
      'To full',
    );
    expect(
      estimateTileLabel(
        _estimate(
          const Duration(minutes: 30),
          kind: BatteryEstimateKind.timeToEmpty,
        ),
      ),
      'To empty',
    );
  });
}
