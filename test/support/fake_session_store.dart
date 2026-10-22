import 'package:voltly/core/persistence/session_store.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';

/// Deterministic session store for coordinator and provider tests.
class FakeSessionStore implements SessionStore {
  final Map<int, ChargingSession> sessions = <int, ChargingSession>{};
  final List<TelemetrySample> samples = <TelemetrySample>[];

  int nextId = 1;
  int recoverCalls = 0;
  String? failOperation;

  ChargingSession? get activeSession {
    for (final ChargingSession session in sessions.values) {
      if (session.isActive) return session;
    }
    return null;
  }

  void seedActive(ChargingSession session) {
    sessions[session.id ?? nextId] = session;
    if (session.id == null) nextId++;
  }

  void _maybeFail(String operation) {
    if (failOperation == operation) {
      throw StateError('$operation failed');
    }
  }

  @override
  Future<ChargingSession> startSession({
    required ChargingSession session,
    required TelemetrySample sample,
  }) async {
    _maybeFail('start');
    final int id = nextId++;
    final ChargingSession persisted = session.copyWith(id: id);
    sessions[id] = persisted;
    samples.add(sample.copyWith(sessionId: id));
    return persisted;
  }

  @override
  Future<void> appendSample({
    required int sessionId,
    required ChargingSession session,
    required TelemetrySample sample,
  }) async {
    _maybeFail('append');
    if (!sessions.containsKey(sessionId)) {
      throw StateError('missing session');
    }
    sessions[sessionId] = session.copyWith(id: sessionId);
    samples.add(sample.copyWith(sessionId: sessionId));
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required ChargingSession session,
    required TelemetrySample sample,
  }) async {
    _maybeFail('end');
    if (!sessions.containsKey(sessionId)) {
      throw StateError('missing session');
    }
    sessions[sessionId] = session.copyWith(id: sessionId);
    samples.add(sample.copyWith(sessionId: sessionId));
  }

  @override
  Future<ChargingSession?> recoverActiveSession() async {
    recoverCalls++;
    _maybeFail('recover');
    final List<ChargingSession> active =
        sessions.values.where((ChargingSession s) => s.isActive).toList()..sort(
          (ChargingSession a, ChargingSession b) =>
              b.startedAt.compareTo(a.startedAt),
        );
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<ChargingSession?> sessionById(int id) async {
    _maybeFail('session');
    return sessions[id];
  }

  @override
  Future<List<ChargingSession>> recentSessions({int limit = 20}) async {
    _maybeFail('history');
    final List<ChargingSession> ordered = sessions.values.toList()
      ..sort(
        (ChargingSession a, ChargingSession b) =>
            b.startedAt.compareTo(a.startedAt),
      );
    return ordered.take(limit).toList(growable: false);
  }

  @override
  Future<List<TelemetrySample>> samplesForSession(int sessionId) async {
    _maybeFail('samples');
    return samples
        .where((TelemetrySample s) => s.sessionId == sessionId)
        .toList(growable: false);
  }

  @override
  Future<void> enforceRetention({DateTime? now}) async {
    _maybeFail('retention');
  }

  @override
  Future<int> deleteAllSessions() async {
    _maybeFail('delete');
    final int count = sessions.length;
    sessions.clear();
    samples.clear();
    return count;
  }
}
