import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/theme/app_colors.dart';

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
}
