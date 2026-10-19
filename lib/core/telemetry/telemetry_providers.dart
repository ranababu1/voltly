import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/core/telemetry/battery_telemetry_service.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Whether the app is in the foreground and telemetry acquisition is needed.
///
/// The app root updates this from its lifecycle observer; screens never set it
/// directly.
class AppActiveController extends Notifier<bool> {
  @override
  bool build() => true;

  void setActive(bool active) {
    if (state != active) state = active;
  }
}

final NotifierProvider<AppActiveController, bool> appActiveProvider =
    NotifierProvider<AppActiveController, bool>(AppActiveController.new);

/// The single telemetry service for the app. Tests override this provider with
/// a fake; widgets never construct a service or call platform channels.
final Provider<BatteryTelemetryService> batteryTelemetryServiceProvider =
    Provider<BatteryTelemetryService>(
      (ref) => PlatformBatteryTelemetryService(),
    );

/// Owns the one telemetry subscription and its retained last snapshot.
///
/// While the app is foregrounded the controller subscribes to the service.
/// When the app becomes inactive it cancels that subscription explicitly (so
/// the native receiver unregisters), retains the last observation and exposes
/// it with its original timestamp. It never polls.
class TelemetryController extends Notifier<AsyncValue<TelemetrySnapshot>> {
  StreamSubscription<TelemetrySnapshot>? _subscription;
  TelemetrySnapshot? _lastSnapshot;
  Object? _lastError;
  StackTrace? _lastStackTrace;

  /// Last valid observation, retained through pauses.
  TelemetrySnapshot? get lastSnapshot => _lastSnapshot;

  /// Whether the controller currently owns a service subscription.
  bool get isSubscribed => _subscription != null;

  @override
  AsyncValue<TelemetrySnapshot> build() {
    final bool active = ref.watch(appActiveProvider);
    final BatteryTelemetryService service = ref.watch(
      batteryTelemetryServiceProvider,
    );
    ref.onDispose(_cancel);

    if (active) {
      _subscribe(service);
    } else {
      _cancel();
    }
    return _restingState();
  }

  void retry() {
    _lastError = null;
    _lastStackTrace = null;
    _cancel();
    state = _lastSnapshot == null
        ? const AsyncLoading<TelemetrySnapshot>()
        : AsyncData<TelemetrySnapshot>(_lastSnapshot!);
    if (ref.read(appActiveProvider)) {
      _subscribe(ref.read(batteryTelemetryServiceProvider));
    }
  }

  AsyncValue<TelemetrySnapshot> _restingState() {
    if (_lastSnapshot != null) {
      return AsyncData<TelemetrySnapshot>(_lastSnapshot!);
    }
    if (_lastError != null) {
      return AsyncError<TelemetrySnapshot>(
        _lastError!,
        _lastStackTrace ?? StackTrace.current,
      );
    }
    return const AsyncLoading<TelemetrySnapshot>();
  }

  void _subscribe(BatteryTelemetryService service) {
    _cancel();
    _subscription = service.watch().listen(
      (TelemetrySnapshot snapshot) {
        _lastSnapshot = snapshot;
        _lastError = null;
        _lastStackTrace = null;
        state = AsyncData<TelemetrySnapshot>(snapshot);
      },
      onError: (Object error, StackTrace stackTrace) {
        _lastError = error;
        _lastStackTrace = stackTrace;
        state = AsyncError<TelemetrySnapshot>(error, stackTrace);
      },
    );
  }

  void _cancel() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final NotifierProvider<TelemetryController, AsyncValue<TelemetrySnapshot>>
telemetrySnapshotProvider =
    NotifierProvider.autoDispose<
      TelemetryController,
      AsyncValue<TelemetrySnapshot>
    >(TelemetryController.new);
