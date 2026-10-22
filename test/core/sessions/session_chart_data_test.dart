import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/sessions/session_chart_data.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/session_fixtures.dart';
import '../../support/telemetry_fixtures.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  TelemetrySample sampleAt(
    DateTime at, {
    double level = 50,
    bool levelAvailable = true,
  }) => TelemetrySample.fromSnapshot(
    sessionSnapshot(at: at, level: level, levelAvailable: levelAvailable),
  );

  test('splits lines at unavailable values instead of connecting them', () {
    final SessionChartData data = SessionChartData.fromSamples(
      SessionChartMetric.batteryLevel,
      <TelemetrySample>[
        sampleAt(t0, level: 40),
        sampleAt(t0.add(const Duration(minutes: 1)), levelAvailable: false),
        sampleAt(t0.add(const Duration(minutes: 2)), level: 45),
      ],
    );

    expect(data.points, hasLength(2));
    expect(data.segments, hasLength(2));
    expect(data.hasUnavailableSamples, isTrue);
    expect(data.hasGaps, isTrue);
    expect(data.summary, contains('unavailable values'));
    expect(data.semanticsLabel, contains('gaps are not interpolated'));
  });

  test('splits lines when the sample interval exceeds the gap threshold', () {
    final SessionChartData data = SessionChartData.fromSamples(
      SessionChartMetric.batteryLevel,
      <TelemetrySample>[
        sampleAt(t0, level: 40),
        sampleAt(t0.add(const Duration(minutes: 10)), level: 50),
      ],
    );

    expect(data.segments, hasLength(2));
    expect(data.hasGaps, isTrue);
    expect(data.summary, contains('1 sampling break'));
  });

  test('keeps a line continuous at exactly the gap threshold', () {
    final SessionChartData data = SessionChartData.fromSamples(
      SessionChartMetric.batteryLevel,
      <TelemetrySample>[
        sampleAt(t0, level: 40),
        sampleAt(t0.add(const Duration(minutes: 5)), level: 41),
      ],
    );

    expect(data.segments, hasLength(1));
    expect(data.hasGaps, isFalse);
    expect(data.summary, contains('No sampling breaks'));
  });

  test('sorts points and reports real min, max and latest values', () {
    final SessionChartData data = SessionChartData.fromSamples(
      SessionChartMetric.batteryLevel,
      <TelemetrySample>[
        sampleAt(t0.add(const Duration(minutes: 2)), level: 55),
        sampleAt(t0, level: 40),
        sampleAt(t0.add(const Duration(minutes: 1)), level: 45),
      ],
    );

    expect(data.points.map((SessionChartPoint p) => p.value).toList(), <double>[
      40,
      45,
      55,
    ]);
    expect(data.minimum, 40);
    expect(data.maximum, 55);
    expect(data.latest, 55);
    expect(data.pointCount, 3);
    expect(data.summary, contains('Latest 55 %'));
  });

  test('reports no data without inventing a point', () {
    final SessionChartData data = SessionChartData.fromSamples(
      SessionChartMetric.temperature,
      <TelemetrySample>[],
    );

    expect(data.hasData, isFalse);
    expect(data.points, isEmpty);
    expect(data.segments, isEmpty);
    expect(data.summary, 'No stored temperature samples.');
  });

  test('maps stored current, temperature and calculated power metrics', () {
    final TelemetrySample sample = TelemetrySample.fromSnapshot(
      TelemetrySnapshot.fromPlatformPayload(
        telemetryPayload(
          observedAtMillis: t0.millisecondsSinceEpoch,
          currentNow: telemetryReading(
            value: 1.25,
            unit: TelemetryUnits.amperes,
            timestampMillis: t0.millisecondsSinceEpoch,
          ),
          temperature: telemetryReading(
            value: 33.5,
            unit: TelemetryUnits.celsius,
            timestampMillis: t0.millisecondsSinceEpoch,
          ),
        ),
      ),
    );

    expect(SessionChartMetric.currentNow.valueOf(sample), 1.25);
    expect(SessionChartMetric.temperature.valueOf(sample), 33.5);
    expect(SessionChartMetric.power.valueOf(sample), closeTo(5.25, 0.000001));
  });
}
