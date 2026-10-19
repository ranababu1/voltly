/// Normalized lifecycle state of a charging session.
enum ChargingSessionState {
  /// The session is in progress and samples may still be added.
  active,

  /// The session ended from a definitive event (full or discharging).
  completed,

  /// The session ended without a clean charging transition, or its sampling
  /// coverage is incomplete. It must not be presented as a continuous record.
  interrupted,
}

/// A charging session derived from real device telemetry.
///
/// All timestamps are observation timestamps (UTC). Levels are nullable because
/// Android may not report a valid battery level; they are never defaulted to 0.
class ChargingSession {
  const ChargingSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.lastObservedAt,
    this.startLevelPercent,
    this.endLevelPercent,
    required this.state,
    this.sampleCount = 0,
    this.maxSamplingGap,
    this.hasSamplingGaps = false,
    this.samplesPruned = false,
  }) : assert(sampleCount >= 0, 'sampleCount cannot be negative'),
       assert(
         startLevelPercent == null ||
             (startLevelPercent >= 0 && startLevelPercent <= 100),
         'startLevelPercent must be in 0..100',
       ),
       assert(
         endLevelPercent == null ||
             (endLevelPercent >= 0 && endLevelPercent <= 100),
         'endLevelPercent must be in 0..100',
       );

  /// Database identifier once persisted; null for a new, unsaved session.
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Time of the most recent accepted sample, used to detect gaps after restore.
  final DateTime? lastObservedAt;

  final double? startLevelPercent;
  final double? endLevelPercent;
  final ChargingSessionState state;
  final int sampleCount;

  /// Longest gap between consecutive accepted samples, when known.
  final Duration? maxSamplingGap;

  /// True when at least one inter-sample gap exceeded the configured threshold.
  final bool hasSamplingGaps;

  /// True when repository retention removed older sample rows from this
  /// session. This is distinct from a telemetry sampling gap: the summary is
  /// still valid, but the stored sample list is not complete.
  final bool samplesPruned;

  bool get isActive => state == ChargingSessionState.active;

  /// A session is partial when it ended without a clean transition or when its
  /// sampling coverage contains gaps.
  bool get isPartial =>
      state == ChargingSessionState.interrupted || hasSamplingGaps;

  Duration? get duration {
    final DateTime? ended = endedAt;
    if (ended == null) return null;
    return ended.difference(startedAt);
  }

  double? get levelChangePercent {
    final double? start = startLevelPercent;
    final double? end = endLevelPercent;
    if (start == null || end == null) return null;
    return end - start;
  }

  ChargingSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? lastObservedAt,
    double? startLevelPercent,
    double? endLevelPercent,
    ChargingSessionState? state,
    int? sampleCount,
    Duration? maxSamplingGap,
    bool? hasSamplingGaps,
    bool? samplesPruned,
  }) {
    return ChargingSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      startLevelPercent: startLevelPercent ?? this.startLevelPercent,
      endLevelPercent: endLevelPercent ?? this.endLevelPercent,
      state: state ?? this.state,
      sampleCount: sampleCount ?? this.sampleCount,
      maxSamplingGap: maxSamplingGap ?? this.maxSamplingGap,
      hasSamplingGaps: hasSamplingGaps ?? this.hasSamplingGaps,
      samplesPruned: samplesPruned ?? this.samplesPruned,
    );
  }

  @override
  String toString() =>
      'ChargingSession(id: $id, state: ${state.name}, startedAt: $startedAt, '
      'endedAt: $endedAt, samples: $sampleCount, gaps: $hasSamplingGaps, '
      'pruned: $samplesPruned)';
}
