import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Tunable session rules. Both durations use observation timestamps, not wall
/// clock timers, so tests and restored sessions behave deterministically.
class ChargingSessionTrackerConfig {
  const ChargingSessionTrackerConfig({
    this.samplingGapThreshold = const Duration(minutes: 5),
    this.notChargingGrace = const Duration(minutes: 2),
  });

  /// A gap between accepted samples longer than this marks the session partial.
  final Duration samplingGapThreshold;

  /// A `not_charging` state must persist this long before the session is closed
  /// as interrupted. This prevents brief thermal pauses from fragmenting one
  /// session into several.
  final Duration notChargingGrace;
}

enum SessionUpdateKind { none, started, sample, ended }

/// The result of feeding one snapshot to the tracker.
///
/// [sample] is the accepted observation to persist. [session] is the updated
/// session snapshot. The tracker itself performs no I/O.
class SessionUpdate {
  const SessionUpdate.none()
    : kind = SessionUpdateKind.none,
      session = null,
      sample = null;

  const SessionUpdate.started({
    required ChargingSession this.session,
    required TelemetrySample this.sample,
  }) : kind = SessionUpdateKind.started;

  const SessionUpdate.sample({
    required ChargingSession this.session,
    required TelemetrySample this.sample,
  }) : kind = SessionUpdateKind.sample;

  const SessionUpdate.ended({
    required ChargingSession this.session,
    required TelemetrySample this.sample,
  }) : kind = SessionUpdateKind.ended;

  final SessionUpdateKind kind;
  final ChargingSession? session;
  final TelemetrySample? sample;

  bool get hasUpdate => kind != SessionUpdateKind.none;

  @override
  String toString() =>
      'SessionUpdate(kind: ${kind.name}, session: $session, sample: $sample)';
}

/// Pure charging-session state machine.
///
/// It consumes real telemetry snapshots and produces session/sample updates for
/// a repository to persist. It never invents samples, never treats unavailable
/// levels as zero, and marks long sampling gaps instead of implying continuous
/// coverage.
///
/// Rules:
/// - `charging` starts a session if none is active.
/// - `full` and `discharging` end an active session as completed.
/// - `not_charging` is tolerated for [ChargingSessionTrackerConfig
///   .notChargingGrace]; if it persists, the session ends as interrupted.
/// - An unavailable charging state keeps the session active but records the
///   sample with its unavailable metadata.
/// - Out-of-order or duplicate observation timestamps are ignored.
class ChargingSessionTracker {
  ChargingSessionTracker({this.config = const ChargingSessionTrackerConfig()});

  final ChargingSessionTrackerConfig config;

  ChargingSession? _activeSession;
  DateTime? _lastSampleAt;
  DateTime? _notChargingSince;
  Duration _maxSamplingGap = Duration.zero;
  bool _hasSamplingGaps = false;

  ChargingSession? get activeSession => _activeSession;

  /// Restores an active session from persistence after an app restart.
  ///
  /// The next accepted sample is compared with [ChargingSession.lastObservedAt]
  /// (or the session start), so a restart-induced gap is recorded honestly.
  void restoreActiveSession(ChargingSession session) {
    if (!session.isActive) {
      throw ArgumentError.value(
        session,
        'session',
        'Only an active session can be restored.',
      );
    }
    _activeSession = session;
    _lastSampleAt = session.lastObservedAt ?? session.startedAt;
    _maxSamplingGap = session.maxSamplingGap ?? Duration.zero;
    _hasSamplingGaps = session.hasSamplingGaps;
    _notChargingSince = null;
  }

  SessionUpdate observe(TelemetrySnapshot snapshot) {
    final ChargingSession? active = _activeSession;
    final BatteryChargingState? chargingState =
        snapshot.chargingState.isAvailable
        ? snapshot.chargingState.value
        : null;
    final DateTime observedAt = snapshot.observedAt;

    if (active == null) {
      if (chargingState == BatteryChargingState.charging) {
        return _start(snapshot);
      }
      return const SessionUpdate.none();
    }

    final DateTime? lastSampleAt = _lastSampleAt;
    if (lastSampleAt != null && !observedAt.isAfter(lastSampleAt)) {
      return const SessionUpdate.none();
    }

    final TelemetrySample sample = TelemetrySample.fromSnapshot(snapshot);
    final ChargingSession withSample = _appendSample(active, snapshot);

    switch (chargingState) {
      case BatteryChargingState.charging:
        _notChargingSince = null;
        return SessionUpdate.sample(session: withSample, sample: sample);
      case BatteryChargingState.full:
      case BatteryChargingState.discharging:
        return _end(
          withSample,
          snapshot,
          ChargingSessionState.completed,
          sample,
        );
      case BatteryChargingState.notCharging:
        final DateTime since = _notChargingSince ?? observedAt;
        _notChargingSince = since;
        if (observedAt.difference(since) >= config.notChargingGrace) {
          return _end(
            withSample,
            snapshot,
            ChargingSessionState.interrupted,
            sample,
          );
        }
        return SessionUpdate.sample(session: withSample, sample: sample);
      case null:
        return SessionUpdate.sample(session: withSample, sample: sample);
    }
  }

  void reset() {
    _activeSession = null;
    _lastSampleAt = null;
    _notChargingSince = null;
    _maxSamplingGap = Duration.zero;
    _hasSamplingGaps = false;
  }

  SessionUpdate _start(TelemetrySnapshot snapshot) {
    final double? level = snapshot.batteryLevel.isAvailable
        ? snapshot.batteryLevel.value
        : null;
    final ChargingSession session = ChargingSession(
      startedAt: snapshot.observedAt,
      lastObservedAt: snapshot.observedAt,
      startLevelPercent: level,
      state: ChargingSessionState.active,
      sampleCount: 1,
    );

    _activeSession = session;
    _lastSampleAt = snapshot.observedAt;
    _notChargingSince = null;
    _maxSamplingGap = Duration.zero;
    _hasSamplingGaps = false;

    return SessionUpdate.started(
      session: session,
      sample: TelemetrySample.fromSnapshot(snapshot),
    );
  }

  ChargingSession _appendSample(
    ChargingSession session,
    TelemetrySnapshot snapshot,
  ) {
    final DateTime? lastSampleAt = _lastSampleAt;
    if (lastSampleAt != null) {
      final Duration gap = snapshot.observedAt.difference(lastSampleAt);
      if (gap > config.samplingGapThreshold) {
        _hasSamplingGaps = true;
        if (gap > _maxSamplingGap) {
          _maxSamplingGap = gap;
        }
      }
    }

    final ChargingSession updated = session.copyWith(
      sampleCount: session.sampleCount + 1,
      lastObservedAt: snapshot.observedAt,
      hasSamplingGaps: _hasSamplingGaps,
      maxSamplingGap: _maxSamplingGap > Duration.zero ? _maxSamplingGap : null,
    );

    _activeSession = updated;
    _lastSampleAt = snapshot.observedAt;
    return updated;
  }

  SessionUpdate _end(
    ChargingSession session,
    TelemetrySnapshot snapshot,
    ChargingSessionState endState,
    TelemetrySample sample,
  ) {
    final double? endLevel = snapshot.batteryLevel.isAvailable
        ? snapshot.batteryLevel.value
        : null;

    final ChargingSession ended = session.copyWith(
      endedAt: snapshot.observedAt,
      endLevelPercent: endLevel,
      state: endState,
    );

    _activeSession = null;
    _lastSampleAt = null;
    _notChargingSince = null;
    _maxSamplingGap = Duration.zero;
    _hasSamplingGaps = false;

    return SessionUpdate.ended(session: ended, sample: sample);
  }
}
