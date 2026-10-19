import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/app.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

import 'fake_battery_telemetry_service.dart';

/// Pumps the real app with a controllable telemetry service.
///
/// [snapshot] or [error] are emitted after the first frame; the fake replays
/// them for any later subscription. The returned fake can emit more updates.
Future<FakeBatteryTelemetryService> pumpVoltlyApp(
  WidgetTester tester, {
  TelemetrySnapshot? snapshot,
  Object? error,
}) async {
  final FakeBatteryTelemetryService fake = FakeBatteryTelemetryService();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [batteryTelemetryServiceProvider.overrideWithValue(fake)],
      child: const VoltlyApp(),
    ),
  );

  if (snapshot != null) {
    fake.emit(snapshot);
    await tester.pump();
  }
  if (error != null) {
    fake.emitError(error);
    await tester.pump();
  }

  addTearDown(() async {
    // Dispose the widget tree first so autoDispose cancels the stream and any
    // freshness timer before the fake controller closes.
    await tester.pumpWidget(const SizedBox.shrink());
    await fake.dispose();
  });

  return fake;
}
