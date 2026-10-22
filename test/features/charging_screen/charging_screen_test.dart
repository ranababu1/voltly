import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/features/charging_screen/charging_ring.dart';
import 'package:voltly/features/charging_screen/charging_screen.dart';
import 'package:voltly/features/charging_screen/charging_screen_settings_card.dart';

import '../../support/fake_battery_telemetry_service.dart';
import '../../support/fake_charging_screen_service.dart';
import '../../support/pump_voltly_app.dart';
import '../../support/telemetry_fixtures.dart';

/// The ring animates forever while charging, so tests pump fixed durations
/// instead of settling.
Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

TelemetrySnapshot _unpluggedNow() => TelemetrySnapshot.fromPlatformPayload(
  telemetryPayload(
    observedAtMillis: DateTime.now().millisecondsSinceEpoch,
    chargingState: telemetryReading(
      value: 'discharging',
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    ),
    plugSource: telemetryReading(
      value: 'none',
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    ),
  ),
);

void main() {
  testWidgets('charger trigger opens the charging screen with four metrics', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService();
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );

    charging.triggerLaunch();
    await _pumpRoute(tester);

    expect(find.byType(ChargingScreen), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('CHARGING'), findsOneWidget);
    expect(find.text('31.5°C'), findsOneWidget);
    expect(find.text('1500 mA'), findsOneWidget);
    expect(find.text('≈ 6.3 W'), findsOneWidget);
    expect(find.text('battery-side'), findsOneWidget);
    // No stored session window yet: the estimate is withheld, not guessed.
    expect(find.text('Estimate'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    final ChargingRing ring = tester.widget<ChargingRing>(
      find.byType(ChargingRing),
    );
    expect(ring.animate, isTrue);
    expect(ring.levelPercent, 72);
  });

  testWidgets('repeated triggers open only one charging screen', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService();
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );

    charging
      ..triggerLaunch()
      ..triggerLaunch();
    await _pumpRoute(tester);
    charging.triggerLaunch();
    await _pumpRoute(tester);

    expect(find.byType(ChargingScreen), findsOneWidget);
  });

  testWidgets('a launch queued before startup opens the charging screen', (
    WidgetTester tester,
  ) async {
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: FakeChargingScreenService(pendingLaunch: true),
    );
    await _pumpRoute(tester);

    expect(find.byType(ChargingScreen), findsOneWidget);
  });

  testWidgets('unavailable metrics show a dash, never zero', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService();
    final int millis = DateTime.now().millisecondsSinceEpoch;
    await pumpVoltlyApp(
      tester,
      snapshot: TelemetrySnapshot.fromPlatformPayload(
        telemetryPayload(
          observedAtMillis: millis,
          temperature: telemetryReading(
            availability: 'unsupported',
            unit: TelemetryUnits.celsius,
            timestampMillis: millis,
          ),
          currentNow: telemetryReading(
            availability: 'unsupported',
            unit: TelemetryUnits.amperes,
            timestampMillis: millis,
          ),
        ),
      ),
      chargingScreen: charging,
    );

    charging.triggerLaunch();
    await _pumpRoute(tester);

    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('— W'), findsOneWidget);
    expect(find.textContaining('0 mA'), findsNothing);
    expect(find.bySemanticsLabel('Temperature unavailable'), findsOneWidget);
    expect(find.bySemanticsLabel('Current unavailable'), findsOneWidget);
  });

  testWidgets('unplugging closes the screen and returns to the lock screen', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService();
    final FakeBatteryTelemetryService telemetry = await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );
    charging.triggerLaunch();
    await _pumpRoute(tester);

    telemetry.emit(_unpluggedNow());
    await _pumpRoute(tester);

    expect(find.byType(ChargingScreen), findsNothing);
    expect(charging.releaseCount, 1);
  });

  testWidgets('close button dismisses and releases the lock screen', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService();
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );
    charging.triggerLaunch();
    await _pumpRoute(tester);

    await tester.tap(find.byTooltip('Close charging screen'));
    await _pumpRoute(tester);

    expect(find.byType(ChargingScreen), findsNothing);
    expect(charging.releaseCount, 1);
  });

  testWidgets('open button stays on the screen if unlocking is cancelled', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService(
      unlockSucceeds: false,
    );
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );
    charging.triggerLaunch();
    await _pumpRoute(tester);

    await tester.tap(find.byTooltip('Open Voltly'));
    await _pumpRoute(tester);
    expect(charging.unlockCount, 1);
    expect(find.byType(ChargingScreen), findsOneWidget);

    charging.unlockSucceeds = true;
    await tester.tap(find.byTooltip('Open Voltly'));
    await _pumpRoute(tester);
    expect(find.byType(ChargingScreen), findsNothing);
    expect(find.text('Battery overview'), findsOneWidget);
  });

  testWidgets('dashboard card turns the charging screen on', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService(
      notificationsAllowed: false,
    );
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );
    await tester.pump();

    final Finder toggle = find.descendant(
      of: find.byType(ChargingScreenSettingsCard),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();

    expect(charging.enabled, isTrue);
    expect(tester.widget<Switch>(toggle).value, isTrue);
  });

  testWidgets('denied notification permission keeps the feature off', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService(
      notificationsAllowed: false,
      grantNotifications: false,
    );
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );
    await tester.pump();

    final Finder toggle = find.descendant(
      of: find.byType(ChargingScreenSettingsCard),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();

    expect(charging.enabled, isFalse);
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(
      find.textContaining('needs notification permission'),
      findsOneWidget,
    );
  });

  testWidgets('card warns when full-screen launches are blocked', (
    WidgetTester tester,
  ) async {
    final FakeChargingScreenService charging = FakeChargingScreenService(
      enabled: true,
      fullScreenAllowed: false,
    );
    await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
      chargingScreen: charging,
    );
    await tester.pump();

    expect(find.textContaining('blocking full-screen'), findsOneWidget);
    final Finder allow = find.widgetWithText(TextButton, 'Allow');
    await tester.ensureVisible(allow);
    await tester.tap(allow);
    await tester.pump();
    expect(charging.openSettingsCount, 1);
  });

  testWidgets('reduced motion stops the ring sweep', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ChargingRing(
            levelPercent: 50,
            animate: true,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    // Would time out if the sweep kept repeating.
    await tester.pumpAndSettle();
  });
}
