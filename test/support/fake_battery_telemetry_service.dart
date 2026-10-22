import 'dart:async';

import 'package:voltly/core/telemetry/battery_telemetry_service.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Test double that lets widget tests drive each telemetry state.
///
/// The latest snapshot or error is replayed when a new listener subscribes, so
/// tests do not depend on provider subscription timing and later
/// re-subscriptions still receive current state.
class FakeBatteryTelemetryService implements BatteryTelemetryService {
  final List<StreamController<TelemetrySnapshot>> _listeners =
      <StreamController<TelemetrySnapshot>>[];
  TelemetrySnapshot? _latest;
  Object? _pendingError;
  StackTrace? _pendingStackTrace;

  /// Number of listeners currently attached to [watch].
  int get activeSubscriptions => _listeners.length;

  @override
  Stream<TelemetrySnapshot> watch() {
    late final StreamController<TelemetrySnapshot> controller;
    controller = StreamController<TelemetrySnapshot>(
      onListen: () {
        final TelemetrySnapshot? latest = _latest;
        if (latest != null) {
          controller.add(latest);
        }
        final Object? pendingError = _pendingError;
        if (pendingError != null) {
          controller.addError(
            pendingError,
            _pendingStackTrace ?? StackTrace.current,
          );
        }
      },
      onCancel: () {
        _listeners.remove(controller);
      },
    );
    _listeners.add(controller);
    return controller.stream;
  }

  @override
  Future<TelemetrySnapshot> readSnapshot() async {
    final TelemetrySnapshot? latest = _latest;
    if (latest == null) {
      throw StateError('No telemetry snapshot has been emitted.');
    }
    return latest;
  }

  void emit(TelemetrySnapshot snapshot) {
    _latest = snapshot;
    _pendingError = null;
    _pendingStackTrace = null;
    for (final StreamController<TelemetrySnapshot> listener
        in List<StreamController<TelemetrySnapshot>>.of(_listeners)) {
      listener.add(snapshot);
    }
  }

  void emitError(Object error, [StackTrace? stackTrace]) {
    _pendingError = error;
    _pendingStackTrace = stackTrace ?? StackTrace.current;
    for (final StreamController<TelemetrySnapshot> listener
        in List<StreamController<TelemetrySnapshot>>.of(_listeners)) {
      listener.addError(error, _pendingStackTrace);
    }
  }

  Future<void> dispose() async {
    for (final StreamController<TelemetrySnapshot> listener
        in List<StreamController<TelemetrySnapshot>>.of(_listeners)) {
      await listener.close();
    }
    _listeners.clear();
  }
}
