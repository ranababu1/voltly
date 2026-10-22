import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/app.dart';
import 'package:voltly/core/persistence/app_database.dart';
import 'package:voltly/core/persistence/persistence_providers.dart';
import 'package:voltly/core/persistence/session_store.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

import 'fake_battery_telemetry_service.dart';

/// Pumps the real app with a controllable telemetry service and an in-memory
/// session database.
///
/// [snapshot] or [error] are emitted after the first frame; the fake replays
/// them for any later subscription. The returned fake can emit more updates.
Future<FakeBatteryTelemetryService> pumpVoltlyApp(
  WidgetTester tester, {
  TelemetrySnapshot? snapshot,
  Object? error,
  SessionStore? sessionStore,
}) async {
  final FakeBatteryTelemetryService fake = FakeBatteryTelemetryService();
  final VoltlyDatabase database = VoltlyDatabase(NativeDatabase.memory());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        batteryTelemetryServiceProvider.overrideWithValue(fake),
        databaseProvider.overrideWithValue(database),
        if (sessionStore != null)
          sessionRepositoryProvider.overrideWithValue(sessionStore),
      ],
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
    // Dispose the widget tree/provider scope before closing the database.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await fake.dispose();
    await database.close();
  });

  return fake;
}
