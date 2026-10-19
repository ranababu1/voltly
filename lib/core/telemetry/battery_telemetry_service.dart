import 'package:flutter/services.dart';

import 'package:voltly/core/telemetry/telemetry_models.dart';

/// The single Dart entry point for battery telemetry.
///
/// UI and feature code depend on this interface; they must never call the
/// platform channels or Android APIs directly. Tests substitute a fake
/// implementation.
abstract interface class BatteryTelemetryService {
  /// Streams snapshots while subscribed. The native receiver is registered on
  /// listen and released on cancel, so no polling occurs.
  Stream<TelemetrySnapshot> watch();

  /// Reads one snapshot on demand, primarily for diagnostics and tests.
  Future<TelemetrySnapshot> readSnapshot();
}

/// Platform-channel implementation backed by the Kotlin telemetry adapter.
class PlatformBatteryTelemetryService implements BatteryTelemetryService {
  static const String methodChannelName = 'com.voltly/telemetry';
  static const String eventChannelName = 'com.voltly/telemetry/events';
  static const String getSnapshotMethod = 'getSnapshot';

  static const MethodChannel _methodChannel = MethodChannel(methodChannelName);
  static const EventChannel _eventChannel = EventChannel(eventChannelName);

  @override
  Stream<TelemetrySnapshot> watch() => _eventChannel
      .receiveBroadcastStream()
      .map<TelemetrySnapshot>(TelemetrySnapshot.fromPlatformPayload);

  @override
  Future<TelemetrySnapshot> readSnapshot() async {
    final Object? payload = await _methodChannel.invokeMethod<Object?>(
      getSnapshotMethod,
    );
    return TelemetrySnapshot.fromPlatformPayload(payload);
  }
}
