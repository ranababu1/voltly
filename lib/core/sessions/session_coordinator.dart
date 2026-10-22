import 'dart:async';

import 'package:voltly/core/persistence/session_store.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/charging_session_tracker.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Serializes live snapshots into the session tracker and local store.
///
/// Observations are processed one at a time so a session cannot be inserted
/// twice by overlapping battery events. The coordinator restores the active
/// session at startup and leaves it open across foreground pauses; the next
/// observation records the resulting gap. It performs no UI work.
class SessionCoordinator {
  SessionCoordinator(this._store, {ChargingSessionTracker? tracker})
    : _tracker = tracker ?? ChargingSessionTracker();

  final SessionStore _store;
  final ChargingSessionTracker _tracker;

  int? _activeSessionId;
  bool _initialized = false;
  Future<ChargingSession?>? _initializing;
  Future<void> _queue = Future<void>.value();

  ChargingSession? get activeSession => _tracker.activeSession;

  /// Loads the active session from storage exactly once.
  Future<ChargingSession?> initialize() {
    if (_initialized) {
      return Future<ChargingSession?>.value(_tracker.activeSession);
    }
    return _initializing ??= _initialize();
  }

  Future<ChargingSession?> _initialize() async {
    try {
      final ChargingSession? active = await _store.recoverActiveSession();
      if (active != null) {
        if (active.id == null) {
          throw StateError('Recovered session has no database id.');
        }
        _tracker.restoreActiveSession(active);
        _activeSessionId = active.id;
      } else {
        _activeSessionId = null;
      }
      _initialized = true;
      return active;
    } catch (_) {
      _initialized = false;
      _initializing = null;
      rethrow;
    }
  }

  /// Processes one observation in queue order and returns the current active
  /// session, or null after the session ends.
  Future<ChargingSession?> observe(TelemetrySnapshot snapshot) {
    final Future<ChargingSession?> result = _queue.then(
      (_) => _observe(snapshot),
    );
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<ChargingSession?> _observe(TelemetrySnapshot snapshot) async {
    await initialize();
    final SessionUpdate update = _tracker.observe(snapshot);

    switch (update.kind) {
      case SessionUpdateKind.none:
        return _tracker.activeSession;
      case SessionUpdateKind.started:
        final ChargingSession persisted = await _store.startSession(
          session: update.session!,
          sample: update.sample!,
        );
        if (persisted.id == null) {
          throw StateError('Session store did not return a persisted id.');
        }
        _activeSessionId = persisted.id;
        return persisted;
      case SessionUpdateKind.sample:
        final int sessionId = _requireActiveSessionId();
        final ChargingSession current = update.session!.copyWith(id: sessionId);
        await _store.appendSample(
          sessionId: sessionId,
          session: current,
          sample: update.sample!,
        );
        return current;
      case SessionUpdateKind.ended:
        final int sessionId = _requireActiveSessionId();
        final ChargingSession ended = update.session!.copyWith(id: sessionId);
        await _store.endSession(
          sessionId: sessionId,
          session: ended,
          sample: update.sample!,
        );
        _activeSessionId = null;
        return null;
    }
  }

  /// Discards unsaved tracker state and reloads the persisted active session.
  ///
  /// Used after a storage failure so tracking resumes from the last committed
  /// state instead of silently continuing with unpersisted data.
  Future<ChargingSession?> recover() {
    final Future<ChargingSession?> result = _queue.then((_) {
      _tracker.reset();
      _activeSessionId = null;
      _initialized = false;
      _initializing = null;
      return initialize();
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  int _requireActiveSessionId() {
    final int? id = _activeSessionId;
    if (id == null) {
      throw StateError('No persisted active session is available.');
    }
    return id;
  }
}
