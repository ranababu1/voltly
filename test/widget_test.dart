import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/app.dart';
import 'package:voltly/app/theme/app_colors.dart';

void main() {
  testWidgets('renders the Voltly foundation screen without telemetry values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoltlyApp());

    expect(find.text('VOLTLY'), findsOneWidget);
    expect(find.text('Know your battery.'), findsOneWidget);
    expect(
      find.text('Battery intelligence, beautifully simple.'),
      findsOneWidget,
    );
    expect(find.text('Telemetry connected'), findsOneWidget);
    expect(find.text('Open telemetry diagnostics'), findsOneWidget);
    expect(find.textContaining('Android 8.0+'), findsOneWidget);

    // The dashboard must never present a fabricated battery reading.
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('uses the AMOLED dark theme with mint as the accent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoltlyApp());

    final BuildContext context = tester.element(find.byType(Scaffold));
    final ThemeData theme = Theme.of(context);

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.mint);
    expect(theme.colorScheme.surface, AppColors.surface);
  });

  testWidgets('remains scrollable and overflow-free with large text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const VoltlyApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
