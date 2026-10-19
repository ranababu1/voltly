import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';
import 'package:voltly/features/dashboard/telemetry_diagnostics_screen.dart';

import '../../support/fake_battery_telemetry_service.dart';
import '../../support/telemetry_fixtures.dart';

void main() {
  Future<FakeBatteryTelemetryService> pumpDiagnostics(
    WidgetTester tester,
  ) async {
    final FakeBatteryTelemetryService fake = FakeBatteryTelemetryService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [batteryTelemetryServiceProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TelemetryDiagnosticsScreen(),
        ),
      ),
    );
    addTearDown(() async {
      // Dispose the screen first so autoDispose cancels the stream and its
      // freshness timer before the controller closes.
      await tester.pumpWidget(const SizedBox.shrink());
      await fake.dispose();
    });
    return fake;
  }

  testWidgets('shows a loading state until the first reading arrives', (
    WidgetTester tester,
  ) async {
    await pumpDiagnostics(tester);
    await tester.pump();

    expect(find.text('Waiting for a battery reading…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders real values, provenance and calculated power', (
    WidgetTester tester,
  ) async {
    final FakeBatteryTelemetryService fake = await pumpDiagnostics(tester);
    fake.emit(snapshotAt(DateTime.now()));
    await tester.pump();

    expect(find.text('Developer diagnostics'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Battery level'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Charging'), findsOneWidget);
    expect(find.text('USB'), findsOneWidget);
    expect(find.text('4.20 V'), findsOneWidget);
    expect(find.text('31.5 °C'), findsOneWidget);
    expect(find.text('1.500 A'), findsOneWidget);
    expect(find.text('1.400 A'), findsOneWidget);
    expect(find.text('3500.0 mAh'), findsOneWidget);
    expect(find.text('Battery-side power'), findsOneWidget);
    expect(find.text('6.30 W'), findsOneWidget);
    expect(find.text('Calculated'), findsOneWidget);
    expect(find.text('Device'), findsNWidgets(8));
    expect(
      find.textContaining('Approximate battery-side power'),
      findsOneWidget,
    );
  });

  testWidgets('renders unavailable metrics with reasons and no zero fallback', (
    WidgetTester tester,
  ) async {
    final FakeBatteryTelemetryService fake = await pumpDiagnostics(tester);
    final int millis = DateTime.now().millisecondsSinceEpoch;
    fake.emit(
      TelemetrySnapshot.fromPlatformPayload(
        telemetryPayload(
          observedAtMillis: millis,
          currentNow: telemetryReading(
            availability: 'unsupported',
            reason: 'No current sensor',
          ),
          temperature: telemetryReading(
            availability: 'temporarily_unavailable',
            reason: 'Battery service busy',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No current sensor'), findsOneWidget);
    expect(find.text('Battery service busy'), findsOneWidget);
    expect(find.text('Unsupported'), findsWidgets);
    expect(find.text('Unavailable'), findsWidgets);
    expect(
      find.textContaining('Battery-side power needs available voltage'),
      findsOneWidget,
    );
    expect(find.text('0.000 W'), findsNothing);
  });

  testWidgets('marks an old snapshot stale', (WidgetTester tester) async {
    final FakeBatteryTelemetryService fake = await pumpDiagnostics(tester);
    fake.emit(snapshotAt(DateTime.now().subtract(const Duration(minutes: 6))));
    await tester.pump();

    expect(find.text('Stale'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
    expect(
      find.textContaining('older than 5 minutes is marked stale'),
      findsOneWidget,
    );
  });

  testWidgets('shows a clear error state with retry', (
    WidgetTester tester,
  ) async {
    final FakeBatteryTelemetryService fake = await pumpDiagnostics(tester);
    fake.emitError(
      PlatformException(
        code: 'telemetry_receiver_failed',
        message: 'Receiver denied',
      ),
    );
    await tester.pump();

    expect(find.text('Telemetry unavailable'), findsOneWidget);
    expect(find.textContaining('telemetry_receiver_failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('remains overflow-free with large text on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final FakeBatteryTelemetryService fake = await pumpDiagnostics(tester);
    fake.emit(snapshotAt(DateTime.now()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Developer diagnostics'), findsOneWidget);
    expect(find.text('Battery-side power'), findsOneWidget);
  });
}
