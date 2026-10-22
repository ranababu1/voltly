import 'dart:async';

import 'package:flutter/services.dart';

/// Device-side state of the opt-in lock-screen charging screen.
class ChargingScreenStatus {
  const ChargingScreenStatus({
    required this.supported,
    required this.enabled,
    required this.notificationsAllowed,
    required this.fullScreenAllowed,
  });

  /// The platform does not implement the feature (e.g. tests, non-Android).
  const ChargingScreenStatus.unsupported()
    : supported = false,
      enabled = false,
      notificationsAllowed = false,
      fullScreenAllowed = false;

  factory ChargingScreenStatus.fromPlatform(Object? payload) {
    if (payload is! Map) return const ChargingScreenStatus.unsupported();
    bool flag(String key) => payload[key] == true;
    return ChargingScreenStatus(
      supported: true,
      enabled: flag('enabled'),
      notificationsAllowed: flag('notificationsAllowed'),
      fullScreenAllowed: flag('fullScreenAllowed'),
    );
  }

  final bool supported;
  final bool enabled;
  final bool notificationsAllowed;

  /// Android 14+ can revoke full-screen intents; without it the trigger
  /// arrives as a regular notification instead of opening the screen.
  final bool fullScreenAllowed;

  /// Enabled and every permission the lock-screen launch needs is granted.
  bool get isReady => enabled && notificationsAllowed && fullScreenAllowed;
}

/// Dart entry point for the native charging-screen trigger.
///
/// Widgets depend on this interface via a provider and never call the
/// platform channel directly. Tests substitute a fake.
abstract interface class ChargingScreenService {
  Future<ChargingScreenStatus> status();

  Future<ChargingScreenStatus> setEnabled(bool enabled);

  /// Requests POST_NOTIFICATIONS on Android 13+; resolves with the new status.
  Future<ChargingScreenStatus> requestNotificationPermission();

  Future<void> openFullScreenSettings();

  /// Whether the current activity launch came from the charger trigger.
  /// Cleared after the first read.
  Future<bool> consumeLaunchRequest();

  /// Triggers that arrive while the Flutter UI is already running.
  Stream<void> get launchRequests;

  /// Stops showing over the lock screen and returns to it if locked.
  Future<void> releaseLockScreen();

  /// Asks Android to dismiss the keyguard. Resolves true when unlocked.
  Future<bool> unlock();
}

class PlatformChargingScreenService implements ChargingScreenService {
  PlatformChargingScreenService() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'showChargingScreen') _launches.add(null);
    });
  }

  static const String channelName = 'com.voltly/charging_screen';
  static const MethodChannel _channel = MethodChannel(channelName);

  final StreamController<void> _launches = StreamController<void>.broadcast();

  @override
  Stream<void> get launchRequests => _launches.stream;

  @override
  Future<ChargingScreenStatus> status() => _status('getStatus');

  @override
  Future<ChargingScreenStatus> setEnabled(bool enabled) =>
      _status('setEnabled', <String, Object?>{'enabled': enabled});

  @override
  Future<ChargingScreenStatus> requestNotificationPermission() =>
      _status('requestNotificationPermission');

  @override
  Future<void> openFullScreenSettings() async {
    await _invoke<void>('openFullScreenSettings');
  }

  @override
  Future<bool> consumeLaunchRequest() async =>
      await _invoke<bool>('consumeLaunchRequest') ?? false;

  @override
  Future<void> releaseLockScreen() async {
    await _invoke<void>('releaseLockScreen');
  }

  @override
  Future<bool> unlock() async => await _invoke<bool>('unlock') ?? true;

  Future<ChargingScreenStatus> _status(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return ChargingScreenStatus.fromPlatform(
        await _channel.invokeMethod<Object?>(method, arguments),
      );
    } on MissingPluginException {
      return const ChargingScreenStatus.unsupported();
    }
  }

  Future<T?> _invoke<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on MissingPluginException {
      return null;
    }
  }
}
