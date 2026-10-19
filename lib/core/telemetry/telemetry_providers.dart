import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/core/telemetry/battery_telemetry_service.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// The single telemetry service for the app. Tests override this provider with
/// a fake; widgets never construct a service or call platform channels.
final Provider<BatteryTelemetryService> batteryTelemetryServiceProvider =
    Provider<BatteryTelemetryService>(
      (ref) => PlatformBatteryTelemetryService(),
    );

/// Live battery snapshots. Being auto-disposed, the native broadcast receiver
/// is registered only while a screen watches this provider.
final StreamProvider<TelemetrySnapshot> telemetrySnapshotProvider =
    StreamProvider.autoDispose<TelemetrySnapshot>(
      (ref) => ref.watch(batteryTelemetryServiceProvider).watch(),
      // Surface channel failures immediately. Silent exponential retries would
      // hide a broken receiver and mask the explicit error/retry state.
      retry: (int retryCount, Object error) => null,
    );
