import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/pump_voltly_app.dart';
import '../../support/telemetry_fixtures.dart';

void main() {
  testWidgets('renders live primary and secondary telemetry with provenance', (
    WidgetTester tester,
  ) async {
    await pumpVoltlyApp(tester, snapshot: snapshotAt(DateTime.now()));

    expect(find.text('Battery overview'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Charging'), findsOneWidget);
    expect(find.text('Power source: USB'), findsOneWidget);
    expect(find.text('Voltage'), findsOneWidget);
    expect(find.text('4.20 V'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('31.5 °C'), findsOneWidget);
    expect(find.text('Current now'), findsOneWidget);
    expect(find.text('1.500 A'), findsOneWidget);
    expect(find.text('Average current'), findsOneWidget);
    expect(find.text('1.400 A'), findsOneWidget);
    expect(find.text('Charge counter'), findsOneWidget);
    expect(find.text('3500.0 mAh'), findsOneWidget);
    expect(find.text('Battery-side power'), findsOneWidget);
    expect(find.text('6.30 W'), findsOneWidget);
    expect(find.text('Calculated'), findsOneWidget);
    expect(find.text('Device'), findsWidgets);
    expect(find.text('Live'), findsOneWidget);
    expect(find.textContaining('Observed'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders low-capability metrics without zero fallbacks', (
    WidgetTester tester,
  ) async {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    await pumpVoltlyApp(
      tester,
      snapshot: TelemetrySnapshot.fromPlatformPayload(
        telemetryPayload(
          observedAtMillis: millis,
          chargingState: telemetryReading(
            availability: 'temporarily_unavailable',
            reason: 'Battery service busy',
          ),
          voltage: telemetryReading(
            availability: 'unsupported',
            reason: 'No voltage sensor',
          ),
          temperature: telemetryReading(
            availability: 'invalid',
            reason: 'Temperature out of range',
          ),
          currentNow: telemetryReading(
            availability: 'unsupported',
            reason: 'No current sensor',
          ),
          currentAverage: telemetryReading(
            availability: 'unsupported',
            reason: 'No current sensor',
          ),
          chargeCounter: telemetryReading(
            availability: 'unsupported',
            reason: 'No charge counter',
          ),
        ),
      ),
    );

    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Charging state unavailable'), findsOneWidget);
    expect(find.text('Battery service busy'), findsOneWidget);
    expect(find.text('No voltage sensor'), findsOneWidget);
    expect(find.text('Temperature out of range'), findsOneWidget);
    expect(find.text('No current sensor'), findsNWidgets(2));
    expect(find.text('No charge counter'), findsOneWidget);
    expect(find.text('Unsupported'), findsWidgets);
    expect(find.text('Invalid'), findsOneWidget);
    expect(find.text('0.00 V'), findsNothing);
    expect(find.text('0.0 °C'), findsNothing);
    expect(find.text('0.000 A'), findsNothing);
    expect(find.text('0.00 W'), findsNothing);
  });

  testWidgets('never renders zero when battery level is unavailable', (
    WidgetTester tester,
  ) async {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    await pumpVoltlyApp(
      tester,
      snapshot: TelemetrySnapshot.fromPlatformPayload(
        telemetryPayload(
          observedAtMillis: millis,
          batteryLevel: telemetryReading(
            availability: 'unsupported',
            reason: 'No battery level sensor',
          ),
        ),
      ),
    );

    expect(find.text('Battery level unavailable'), findsOneWidget);
    expect(find.text('No battery level sensor'), findsOneWidget);
    expect(find.textContaining('0%'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows a loading state without readings or percentages', (
    WidgetTester tester,
  ) async {
    await pumpVoltlyApp(tester);

    expect(find.text('Reading battery…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('shows an explicit error state with retry', (
    WidgetTester tester,
  ) async {
    await pumpVoltlyApp(
      tester,
      error: PlatformException(
        code: 'telemetry_receiver_failed',
        message: 'Receiver denied',
      ),
    );

    expect(find.text('Telemetry unavailable'), findsOneWidget);
    expect(find.textContaining('telemetry_receiver_failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets(
    'marks an old snapshot stale and warns instead of implying live',
    (WidgetTester tester) async {
      await pumpVoltlyApp(
        tester,
        snapshot: snapshotAt(
          DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      );

      expect(find.text('Stale'), findsOneWidget);
      expect(find.text('Live'), findsNothing);
      expect(find.textContaining('over 5 minutes old'), findsOneWidget);
    },
  );

  testWidgets('dashboard is overflow-free at 320x640 with 2x text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpVoltlyApp(tester, snapshot: snapshotAt(DateTime.now()));

    expect(tester.takeException(), isNull);
    expect(find.text('Battery overview'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Battery-side power'), findsOneWidget);
  });

  testWidgets('opens telemetry diagnostics from the dashboard', (
    WidgetTester tester,
  ) async {
    await pumpVoltlyApp(tester, snapshot: snapshotAt(DateTime.now()));

    await tester.tap(find.byTooltip('Telemetry diagnostics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Telemetry diagnostics'), findsOneWidget);
    expect(find.text('Developer diagnostics'), findsOneWidget);
    expect(find.text('Schema v1'), findsOneWidget);
  });
}
