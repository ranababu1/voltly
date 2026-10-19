import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/app.dart';
import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

import 'support/pump_voltly_app.dart';
import 'support/telemetry_fixtures.dart';

void main() {
  testWidgets('root app renders the telemetry dashboard with the dark theme', (
    WidgetTester tester,
  ) async {
    await pumpVoltlyApp(tester, snapshot: snapshotAt(DateTime.now()));

    expect(find.text('VOLTLY'), findsOneWidget);
    expect(find.text('Battery overview'), findsOneWidget);
    expect(find.byTooltip('Telemetry diagnostics'), findsOneWidget);

    final BuildContext context = tester.element(find.byType(Scaffold));
    final ThemeData theme = Theme.of(context);

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.mint);
    expect(theme.colorScheme.surface, AppColors.surface);
  });

  testWidgets('pauses telemetry while the app is not resumed', (
    WidgetTester tester,
  ) async {
    final fake = await pumpVoltlyApp(
      tester,
      snapshot: snapshotAt(DateTime.now()),
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(VoltlyApp)),
    );

    expect(container.read(appActiveProvider), isTrue);
    expect(fake.activeSubscriptions, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(container.read(appActiveProvider), isFalse);
    expect(fake.activeSubscriptions, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(container.read(appActiveProvider), isTrue);
    expect(fake.activeSubscriptions, 1);
  });
}
