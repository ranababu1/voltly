import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

/// One device-reported current reading, in milliamperes (positive = charging).
class LiveCurrentPoint {
  const LiveCurrentPoint(this.observedAt, this.milliamps);

  final DateTime observedAt;
  final double milliamps;
}

/// Short-term, in-memory view of the live current while the app is open.
///
/// Statistics cover the current power phase only (plugged in or on battery)
/// and reset whenever the phone is plugged in or unplugged, so a charging
/// maximum is never mixed with a discharging minimum. Nothing here is
/// persisted; it is derived from real readings and never interpolated.
class LiveCurrentState {
  const LiveCurrentState({
    required this.history,
    required this.sampleCount,
    required this.pluggedIn,
    this.minMilliamps,
    this.maxMilliamps,
    this.averageMilliamps,
    this.phaseStartedAt,
  });

  const LiveCurrentState.empty()
    : history = const <LiveCurrentPoint>[],
      sampleCount = 0,
      pluggedIn = null,
      minMilliamps = null,
      maxMilliamps = null,
      averageMilliamps = null,
      phaseStartedAt = null;

  /// Readings from the last [LiveCurrentController.historyWindow], oldest
  /// first.
  final List<LiveCurrentPoint> history;
  final int sampleCount;
  final bool? pluggedIn;
  final double? minMilliamps;
  final double? maxMilliamps;
  final double? averageMilliamps;
  final DateTime? phaseStartedAt;

  /// Min/avg/max are meaningful only after a few readings.
  bool get hasStats => sampleCount >= LiveCurrentController.minimumStatsSamples;
}

class LiveCurrentController extends Notifier<LiveCurrentState> {
  static const Duration historyWindow = Duration(seconds: 60);
  static const int minimumStatsSamples = 3;

  DateTime? _lastObservedAt;
  double _sum = 0;

  @override
  LiveCurrentState build() {
    _lastObservedAt = null;
    _sum = 0;
    ref.listen<AsyncValue<TelemetrySnapshot>>(telemetrySnapshotProvider, (
      AsyncValue<TelemetrySnapshot>? previous,
      AsyncValue<TelemetrySnapshot> next,
    ) {
      final TelemetrySnapshot? snapshot = next.value;
      if (snapshot != null) observe(snapshot);
    });
    final TelemetrySnapshot? initial = ref
        .read(telemetrySnapshotProvider)
        .value;
    const LiveCurrentState empty = LiveCurrentState.empty();
    return initial == null ? empty : (_fold(empty, initial) ?? empty);
  }

  /// Folds one snapshot into the live statistics. Exposed for tests.
  void observe(TelemetrySnapshot snapshot) {
    final LiveCurrentState? next = _fold(state, snapshot);
    if (next != null) state = next;
  }

  /// Clears min/avg/max and the sparkline, keeping the plug phase.
  void reset() {
    _sum = 0;
    state = LiveCurrentState(
      history: const <LiveCurrentPoint>[],
      sampleCount: 0,
      pluggedIn: state.pluggedIn,
      phaseStartedAt: _lastObservedAt,
    );
  }

  /// Returns the next state, or null when [snapshot] changes nothing.
  LiveCurrentState? _fold(
    LiveCurrentState current,
    TelemetrySnapshot snapshot,
  ) {
    final DateTime observedAt = snapshot.observedAt;
    final DateTime? last = _lastObservedAt;
    if (last != null && !observedAt.isAfter(last)) return null;
    _lastObservedAt = observedAt;

    final bool? plugged = _pluggedIn(snapshot);
    bool changed = false;
    if (plugged != null && plugged != current.pluggedIn) {
      changed = true;
      if (current.pluggedIn != null) {
        // Plugged in or unplugged: start a fresh phase.
        _sum = 0;
        current = LiveCurrentState(
          history: const <LiveCurrentPoint>[],
          sampleCount: 0,
          pluggedIn: plugged,
          phaseStartedAt: observedAt,
        );
      } else {
        current = _copy(current, pluggedIn: plugged);
      }
    }

    final TelemetryReading<double> reading = snapshot.currentNow;
    if (!reading.isAvailable) return changed ? current : null;

    final double milliamps = reading.value! * 1000;
    final DateTime cutoff = observedAt.subtract(historyWindow);
    final List<LiveCurrentPoint> history = <LiveCurrentPoint>[
      for (final LiveCurrentPoint point in current.history)
        if (point.observedAt.isAfter(cutoff)) point,
      LiveCurrentPoint(observedAt, milliamps),
    ];
    final int count = current.sampleCount + 1;
    _sum += milliamps;
    final double? min = current.minMilliamps;
    final double? max = current.maxMilliamps;

    return LiveCurrentState(
      history: List<LiveCurrentPoint>.unmodifiable(history),
      sampleCount: count,
      pluggedIn: current.pluggedIn,
      minMilliamps: min == null || milliamps < min ? milliamps : min,
      maxMilliamps: max == null || milliamps > max ? milliamps : max,
      averageMilliamps: _sum / count,
      phaseStartedAt: current.phaseStartedAt ?? observedAt,
    );
  }

  static LiveCurrentState _copy(LiveCurrentState s, {bool? pluggedIn}) =>
      LiveCurrentState(
        history: s.history,
        sampleCount: s.sampleCount,
        pluggedIn: pluggedIn ?? s.pluggedIn,
        minMilliamps: s.minMilliamps,
        maxMilliamps: s.maxMilliamps,
        averageMilliamps: s.averageMilliamps,
        phaseStartedAt: s.phaseStartedAt,
      );

  static bool? _pluggedIn(TelemetrySnapshot snapshot) {
    final TelemetryReading<BatteryPlugSource> plug = snapshot.plugSource;
    if (plug.isAvailable) return plug.value != BatteryPlugSource.none;
    final TelemetryReading<BatteryChargingState> charging =
        snapshot.chargingState;
    if (!charging.isAvailable) return null;
    return switch (charging.value!) {
      BatteryChargingState.charging || BatteryChargingState.full => true,
      BatteryChargingState.discharging => false,
      BatteryChargingState.notCharging => null,
    };
  }
}

final NotifierProvider<LiveCurrentController, LiveCurrentState>
liveCurrentProvider = NotifierProvider<LiveCurrentController, LiveCurrentState>(
  LiveCurrentController.new,
);
