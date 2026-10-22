import 'dart:async';

import 'package:voltly/core/charging_screen/charging_screen_service.dart';

/// Controllable stand-in for the native charging-screen channel.
class FakeChargingScreenService implements ChargingScreenService {
  FakeChargingScreenService({
    this.supported = true,
    this.enabled = false,
    this.notificationsAllowed = true,
    this.fullScreenAllowed = true,
    this.grantNotifications = true,
    this.pendingLaunch = false,
    this.unlockSucceeds = true,
  });

  bool supported;
  bool enabled;
  bool notificationsAllowed;
  bool fullScreenAllowed;
  bool grantNotifications;
  bool pendingLaunch;
  bool unlockSucceeds;

  int releaseCount = 0;
  int unlockCount = 0;
  int openSettingsCount = 0;

  final StreamController<void> _launches = StreamController<void>.broadcast();

  ChargingScreenStatus get _status => supported
      ? ChargingScreenStatus(
          supported: true,
          enabled: enabled,
          notificationsAllowed: notificationsAllowed,
          fullScreenAllowed: fullScreenAllowed,
        )
      : const ChargingScreenStatus.unsupported();

  /// Simulates a charger trigger while the UI is running.
  void triggerLaunch() => _launches.add(null);

  @override
  Stream<void> get launchRequests => _launches.stream;

  @override
  Future<ChargingScreenStatus> status() async => _status;

  @override
  Future<ChargingScreenStatus> setEnabled(bool value) async {
    enabled = value;
    return _status;
  }

  @override
  Future<ChargingScreenStatus> requestNotificationPermission() async {
    if (grantNotifications) notificationsAllowed = true;
    return _status;
  }

  @override
  Future<void> openFullScreenSettings() async => openSettingsCount++;

  @override
  Future<bool> consumeLaunchRequest() async {
    final bool launch = pendingLaunch;
    pendingLaunch = false;
    return launch;
  }

  @override
  Future<void> releaseLockScreen() async => releaseCount++;

  @override
  Future<bool> unlock() async {
    unlockCount++;
    return unlockSucceeds;
  }

  Future<void> dispose() => _launches.close();
}
