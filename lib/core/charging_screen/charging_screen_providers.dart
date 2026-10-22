import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/core/charging_screen/charging_screen_service.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

final Provider<ChargingScreenService> chargingScreenServiceProvider =
    Provider<ChargingScreenService>(
      (Ref ref) => PlatformChargingScreenService(),
    );

/// Why turning the charging screen on did not complete.
enum ChargingScreenEnableIssue { notificationsDenied }

/// Opt-in state for the lock-screen charging screen.
///
/// Re-reads native status whenever the app returns to the foreground so a
/// permission changed in system settings is reflected immediately.
class ChargingScreenStatusController
    extends AsyncNotifier<ChargingScreenStatus> {
  @override
  Future<ChargingScreenStatus> build() {
    ref.watch(appActiveProvider);
    return ref.watch(chargingScreenServiceProvider).status();
  }

  /// Turns the feature on (requesting notification permission first) or off.
  Future<ChargingScreenEnableIssue?> setEnabled(bool enabled) async {
    final ChargingScreenService service = ref.read(
      chargingScreenServiceProvider,
    );
    if (enabled) {
      final ChargingScreenStatus permission = await service
          .requestNotificationPermission();
      if (!permission.notificationsAllowed) {
        if (ref.mounted) state = AsyncData<ChargingScreenStatus>(permission);
        return ChargingScreenEnableIssue.notificationsDenied;
      }
    }
    final ChargingScreenStatus next = await service.setEnabled(enabled);
    if (ref.mounted) state = AsyncData<ChargingScreenStatus>(next);
    return null;
  }
}

final AsyncNotifierProvider<
  ChargingScreenStatusController,
  ChargingScreenStatus
>
chargingScreenStatusProvider =
    AsyncNotifierProvider<ChargingScreenStatusController, ChargingScreenStatus>(
      ChargingScreenStatusController.new,
    );
