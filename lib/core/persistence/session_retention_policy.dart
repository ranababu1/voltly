/// Bounded local-history policy. Active sessions are never aged out of the
/// database; their samples are still capped so one abnormally long session
/// cannot grow without limit.
class SessionRetentionPolicy {
  const SessionRetentionPolicy({
    this.maxEndedSessions = 100,
    this.maxAge = const Duration(days: 180),
    this.maxSamplesPerSession = 720,
  });

  /// Maximum completed/interrupted sessions retained by age order.
  final int maxEndedSessions;

  /// Ended sessions older than this are removed. Active sessions are kept until
  /// they end.
  final Duration maxAge;

  /// Maximum sample rows retained per session. Older samples are removed first
  /// and the session is marked `samplesPruned`.
  final int maxSamplesPerSession;

  void validate() {
    if (maxEndedSessions <= 0) {
      throw ArgumentError.value(
        maxEndedSessions,
        'maxEndedSessions',
        'Retention must keep at least one ended session.',
      );
    }
    if (maxAge <= Duration.zero) {
      throw ArgumentError.value(
        maxAge,
        'maxAge',
        'Retention age must be positive.',
      );
    }
    if (maxSamplesPerSession <= 0) {
      throw ArgumentError.value(
        maxSamplesPerSession,
        'maxSamplesPerSession',
        'Retention must keep at least one sample per session.',
      );
    }
  }
}
