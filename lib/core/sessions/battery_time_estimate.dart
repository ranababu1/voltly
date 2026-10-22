import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

enum BatteryEstimateKind { timeToFull, timeToEmpty }

/// A calculated, approximate remaining time based only on stored samples.
class BatteryTimeEstimate {
  const BatteryTimeEstimate({
    required this.kind,
    required this.remaining,
    required this.sampleCount,
    required this.observedWindow,
    required this.latestLevelPercent,
    required this.ratePercentPerHour,
    required this.targetReached,
    required this.sessionHadSamplingGaps,
    required this.sessionSamplesPruned,
  });

  final BatteryEstimateKind kind;
  final Duration remaining;
  final int sampleCount;
  final Duration observedWindow;
  final double latestLevelPercent;
  final double ratePercentPerHour;
  final bool targetReached;
  final bool sessionHadSamplingGaps;
  final bool sessionSamplesPruned;
}

class BatteryEstimateResult {
  const BatteryEstimateResult.available(BatteryTimeEstimate this.estimate)
    : reason = null;

  const BatteryEstimateResult.unavailable(String this.reason) : estimate = null;

  final BatteryTimeEstimate? estimate;
  final String? reason;

  bool get isAvailable => estimate != null;
}

/// Calculates time-to-full/empty from the most recent contiguous stored window.
///
/// Deliberate limits (documented in `docs/estimates.md`):
/// - Active sessions only.
/// - Latest sample at most 5 minutes old.
/// - At least 3 samples and 10 minutes of observations.
/// - No gap over 5 minutes; no missing level/state in the window.
/// - Charging/discharging state and level direction must agree.
/// - Projections over 24 hours are withheld.
/// - The result is approximate and never represents charger input power,
///   capacity or battery health.
abstract final class BatteryTimeEstimator {
  static const Duration minimumObservationWindow = Duration(minutes: 10);
  static const Duration maximumSampleAge = Duration(minutes: 5);
  static const Duration maximumGap = Duration(minutes: 5);
  static const Duration historyWindow = Duration(minutes: 30);
  static const Duration maximumProjection = Duration(hours: 24);
  static const int minimumSamples = 3;

  static BatteryEstimateResult estimate({
    required ChargingSession session,
    required List<TelemetrySample> samples,
    DateTime? now,
  }) {
    if (!session.isActive) {
      return const BatteryEstimateResult.unavailable(
        'An estimate is available only while a session is active.',
      );
    }
    if (samples.isEmpty) {
      return const BatteryEstimateResult.unavailable(
        'No stored samples are available yet.',
      );
    }

    final DateTime nowUtc = (now ?? DateTime.now()).toUtc();
    final List<TelemetrySample> ordered = samples.toList()
      ..sort(
        (TelemetrySample a, TelemetrySample b) =>
            a.observedAt.compareTo(b.observedAt),
      );
    final TelemetrySample latest = ordered.last;
    final Duration age = nowUtc.difference(latest.observedAt.toUtc());
    if (age > maximumSampleAge) {
      return const BatteryEstimateResult.unavailable(
        'The latest stored sample is older than 5 minutes.',
      );
    }

    final DateTime cutoff = latest.observedAt.subtract(historyWindow);
    final List<TelemetrySample> window = ordered
        .where((TelemetrySample sample) => !sample.observedAt.isBefore(cutoff))
        .toList(growable: false);
    if (window.length < minimumSamples) {
      final String pruningNote = session.samplesPruned
          ? 'Older samples were pruned; '
          : '';
      return BatteryEstimateResult.unavailable(
        '${pruningNote}at least $minimumSamples stored samples are needed; '
        '${window.length} available.',
      );
    }

    final Duration observed = latest.observedAt.difference(
      window.first.observedAt,
    );
    if (observed < minimumObservationWindow) {
      return const BatteryEstimateResult.unavailable(
        'At least 10 minutes of stored observations are needed.',
      );
    }

    final BatteryChargingState? latestState = latest.chargingState;
    if (latestState == null) {
      return const BatteryEstimateResult.unavailable(
        'Charging state is unavailable in the latest sample.',
      );
    }
    if (latestState == BatteryChargingState.full) {
      return const BatteryEstimateResult.unavailable(
        'Battery is already full; no remaining time to estimate.',
      );
    }
    if (latestState == BatteryChargingState.notCharging) {
      return const BatteryEstimateResult.unavailable(
        'Device is not charging; no time estimate is available.',
      );
    }

    final BatteryEstimateKind kind =
        latestState == BatteryChargingState.charging
        ? BatteryEstimateKind.timeToFull
        : BatteryEstimateKind.timeToEmpty;

    for (int i = 0; i < window.length; i++) {
      final TelemetrySample sample = window[i];
      if (sample.batteryLevelPercent == null) {
        return const BatteryEstimateResult.unavailable(
          'Battery level was unavailable during the estimation window.',
        );
      }
      if (sample.chargingState != latestState) {
        return const BatteryEstimateResult.unavailable(
          'Charging state changed during the estimation window.',
        );
      }
      if (i > 0) {
        final Duration gap = sample.observedAt.difference(
          window[i - 1].observedAt,
        );
        if (gap > maximumGap) {
          return const BatteryEstimateResult.unavailable(
            'The estimation window contains a sampling gap over 5 minutes.',
          );
        }
      }
    }

    final double startLevel = window.first.batteryLevelPercent!;
    final double latestLevel = window.last.batteryLevelPercent!;
    final double elapsedMinutes = observed.inSeconds / 60;
    final double ratePerMinute = (latestLevel - startLevel) / elapsedMinutes;

    if (kind == BatteryEstimateKind.timeToFull && latestLevel >= 100) {
      return BatteryEstimateResult.available(
        _result(
          kind: kind,
          remaining: Duration.zero,
          targetReached: true,
          window: window,
          observed: observed,
          latestLevel: latestLevel,
          ratePercentPerHour: ratePerMinute * 60,
          session: session,
        ),
      );
    }
    if (kind == BatteryEstimateKind.timeToEmpty && latestLevel <= 0) {
      return BatteryEstimateResult.available(
        _result(
          kind: kind,
          remaining: Duration.zero,
          targetReached: true,
          window: window,
          observed: observed,
          latestLevel: latestLevel,
          ratePercentPerHour: ratePerMinute * 60,
          session: session,
        ),
      );
    }

    if (kind == BatteryEstimateKind.timeToFull && latestLevel <= startLevel) {
      return const BatteryEstimateResult.unavailable(
        'Battery level did not rise during the estimation window.',
      );
    }
    if (kind == BatteryEstimateKind.timeToEmpty && latestLevel >= startLevel) {
      return const BatteryEstimateResult.unavailable(
        'Battery level did not fall during the estimation window.',
      );
    }

    final double remainingPercent = kind == BatteryEstimateKind.timeToFull
        ? 100 - latestLevel
        : latestLevel;
    final double projectedMinutes = remainingPercent / ratePerMinute.abs();
    if (projectedMinutes > maximumProjection.inMinutes) {
      return const BatteryEstimateResult.unavailable(
        'The projected time exceeds 24 hours; estimate withheld.',
      );
    }

    final int roundedMinutes = projectedMinutes.round().clamp(1, 24 * 60);
    return BatteryEstimateResult.available(
      _result(
        kind: kind,
        remaining: Duration(minutes: roundedMinutes),
        targetReached: false,
        window: window,
        observed: observed,
        latestLevel: latestLevel,
        ratePercentPerHour: ratePerMinute * 60,
        session: session,
      ),
    );
  }

  static BatteryTimeEstimate _result({
    required BatteryEstimateKind kind,
    required Duration remaining,
    required bool targetReached,
    required List<TelemetrySample> window,
    required Duration observed,
    required double latestLevel,
    required double ratePercentPerHour,
    required ChargingSession session,
  }) {
    return BatteryTimeEstimate(
      kind: kind,
      remaining: remaining,
      sampleCount: window.length,
      observedWindow: observed,
      latestLevelPercent: latestLevel,
      ratePercentPerHour: ratePercentPerHour,
      targetReached: targetReached,
      sessionHadSamplingGaps: session.hasSamplingGaps,
      sessionSamplesPruned: session.samplesPruned,
    );
  }
}
