import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';

import '../../support/session_fixtures.dart';

void main() {
  final DateTime start = DateTime.utc(2025, 10, 20, 12);
  final DateTime now = start.add(const Duration(minutes: 10));

  ChargingSession session({
    ChargingSessionState state = ChargingSessionState.active,
    bool samplesPruned = false,
    bool hasSamplingGaps = false,
  }) {
    return ChargingSession(
      id: 1,
      startedAt: start,
      state: state,
      samplesPruned: samplesPruned,
      hasSamplingGaps: hasSamplingGaps,
    );
  }

  List<TelemetrySample> observations({
    required List<(int, double)> values,
    String state = 'charging',
    bool levelAvailable = true,
    bool stateAvailable = true,
  }) {
    return values
        .map(((int, double) value) {
          return TelemetrySample.fromSnapshot(
            sessionSnapshot(
              at: start.add(Duration(minutes: value.$1)),
              level: value.$2,
              levelAvailable: levelAvailable,
              state: state,
              stateAvailable: stateAvailable,
            ),
            sessionId: 1,
          );
        })
        .toList(growable: false);
  }

  group('BatteryTimeEstimator', () {
    test('estimates time to full from a valid charging window', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
        ),
        now: now,
      );

      expect(result.isAvailable, isTrue);
      expect(result.reason, isNull);
      final BatteryTimeEstimate estimate = result.estimate!;
      expect(estimate.kind, BatteryEstimateKind.timeToFull);
      expect(estimate.remaining, const Duration(minutes: 50));
      expect(estimate.sampleCount, 3);
      expect(estimate.observedWindow, const Duration(minutes: 10));
      expect(estimate.latestLevelPercent, 50);
      expect(estimate.ratePercentPerHour, closeTo(60, 0.001));
      expect(estimate.targetReached, isFalse);
    });

    test('estimates time to empty from a valid discharging window', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 50), (5, 45), (10, 40)],
          state: 'discharging',
        ),
        now: now,
      );

      expect(result.isAvailable, isTrue);
      expect(result.estimate!.kind, BatteryEstimateKind.timeToEmpty);
      expect(result.estimate!.remaining, const Duration(minutes: 40));
    });

    test('reports a reached target without inventing a duration', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 98), (5, 99), (10, 100)],
        ),
        now: now,
      );

      expect(result.isAvailable, isTrue);
      expect(result.estimate!.targetReached, isTrue);
      expect(result.estimate!.remaining, Duration.zero);
    });

    test('withholds an estimate with fewer than three samples', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(values: <(int, double)>[(0, 40), (5, 45)]),
        now: start.add(const Duration(minutes: 5)),
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('3'));
    });

    test('withholds an estimate shorter than the minimum window', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 40), (2, 42), (4, 44)],
        ),
        now: start.add(const Duration(minutes: 4)),
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('10 minutes'));
    });

    test('withholds an estimate containing a sampling gap', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 40), (6, 46), (11, 51)],
        ),
        now: start.add(const Duration(minutes: 11)),
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('gap'));
    });

    test('withholds an estimate when a level is unavailable', () {
      final List<TelemetrySample> samples = observations(
        values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
      ).toList();
      samples[1] = TelemetrySample.fromSnapshot(
        sessionSnapshot(
          at: start.add(const Duration(minutes: 5)),
          levelAvailable: false,
        ),
        sessionId: 1,
      );

      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: samples,
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('Battery level'));
    });

    test('withholds an estimate when charging state changes', () {
      final List<TelemetrySample> samples = observations(
        values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
      ).toList();
      samples[1] = TelemetrySample.fromSnapshot(
        sessionSnapshot(
          at: start.add(const Duration(minutes: 5)),
          level: 45,
          stateAvailable: false,
        ),
        sessionId: 1,
      );

      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: samples,
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('Charging state'));
    });

    test('withholds an estimate from stale samples', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
        ),
        now: start.add(const Duration(minutes: 16)),
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('older than 5 minutes'));
    });

    test('withholds an estimate for a completed session', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(state: ChargingSessionState.completed),
        samples: observations(
          values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
        ),
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('active'));
    });

    test('withholds an estimate when level direction contradicts charging', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 50), (5, 49), (10, 50)],
        ),
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('did not rise'));
    });

    test('withholds projections beyond 24 hours', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 40), (5, 40.1), (10, 40.2)],
        ),
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('24 hours'));
    });

    test('reports pruned history without discarding a valid recent window', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(samplesPruned: true),
        samples: observations(
          values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
        ),
        now: now,
      );

      expect(result.isAvailable, isTrue);
      expect(result.estimate!.sessionSamplesPruned, isTrue);
    });

    test('withholds an estimate when the latest state is unavailable', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 40), (5, 45), (10, 50)],
          stateAvailable: false,
        ),
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('latest sample'));
    });

    test('mentions pruning when too few retained samples remain', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(samplesPruned: true),
        samples: observations(values: <(int, double)>[(0, 40), (5, 45)]),
        now: start.add(const Duration(minutes: 5)),
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('pruned'));
    });

    test('withholds an estimate when the latest state is full', () {
      final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
        session: session(),
        samples: observations(
          values: <(int, double)>[(0, 98), (5, 99), (10, 100)],
          state: 'full',
        ),
        now: now,
      );

      expect(result.isAvailable, isFalse);
      expect(result.reason, contains('already full'));
    });
  });
}
