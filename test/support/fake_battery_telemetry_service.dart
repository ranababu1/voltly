import 'dart:async';

import 'package:voltly/core/telemetry/battery_telemetry_service.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Test double that lets widget tests drive each telemetry state.
///
/// The latest snapshot or error is replayed when a new listener subscribes, so
/// tests do not depend on provider subscription timing and autoDispose
/// re-subscriptions still receive current state.
class FakeBatteryTelemetryService implements BatteryTelemetryService {
  final StreamController<TelemetrySnapshot> _controller =
      StreamController<TelemetrySnapshot>.broadcast();
  TelemetrySnapshot? _latest;
  Object? _pendingError;
  StackTrace? _pendingStackTrace;

  @override
  Stream<TelemetrySnapshot> watch() async* {
    final TelemetrySnapshot? latest = _latest;
    if (latest != null) {
      yield latest;
    }

    final Object? pendingError = _pendingError;
    if (pendingError != null) {
      Error.throwWithStackTrace(
        pendingError,
        _pendingStackTrace ?? StackTrace.current,
      );
    }

    await for (final TelemetrySnapshot snapshot in _controller.stream) {
      yield snapshot;
    }
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
    _controller.add(snapshot);
  }

  void emitError(Object error, [StackTrace? stackTrace]) {
    _pendingError = error;
    _pendingStackTrace = stackTrace ?? StackTrace.current;
    _controller.addError(error, _pendingStackTrace);
  }

  Future<void> dispose() => _controller.close();
}
