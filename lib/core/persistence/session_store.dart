import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';

/// Persistence operations needed by the live session coordinator and history.
///
/// Keeping this boundary narrow lets coordinator tests use a deterministic fake
/// without opening SQLite.
abstract interface class SessionStore {
  Future<ChargingSession> startSession({
    required ChargingSession session,
    required TelemetrySample sample,
  });

  Future<void> appendSample({
    required int sessionId,
    required ChargingSession session,
    required TelemetrySample sample,
  });

  Future<void> endSession({
    required int sessionId,
    required ChargingSession session,
    required TelemetrySample sample,
  });

  Future<ChargingSession?> recoverActiveSession();

  Future<ChargingSession?> sessionById(int id);

  Future<List<ChargingSession>> recentSessions({int limit});

  Future<List<TelemetrySample>> samplesForSession(int sessionId);

  Future<void> enforceRetention({DateTime? now});

  Future<int> deleteAllSessions();
}
