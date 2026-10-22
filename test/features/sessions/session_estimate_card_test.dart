import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/features/sessions/session_estimate_card.dart';

void main() {
  BatteryTimeEstimate chargingEstimate({bool pruned = false}) {
    return BatteryTimeEstimate(
      kind: BatteryEstimateKind.timeToFull,
      remaining: const Duration(minutes: 50),
      sampleCount: 3,
      observedWindow: const Duration(minutes: 10),
      latestLevelPercent: 50,
      ratePercentPerHour: 60,
      targetReached: false,
      sessionHadSamplingGaps: false,
      sessionSamplesPruned: pruned,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    BatteryEstimateResult? result,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSessionEstimateProvider.overrideWith((Ref ref) async => result),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(child: SessionEstimateCard()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders an approximate estimate with its evidence', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, BatteryEstimateResult.available(chargingEstimate()));

    expect(find.text('Time to full'), findsOneWidget);
    expect(find.text('About 50 min'), findsOneWidget);
    expect(find.text('Estimated'), findsOneWidget);
    expect(find.textContaining('3 stored samples over 10 min'), findsOneWidget);
    expect(find.textContaining('Assumes a steady rate'), findsOneWidget);
    expect(find.textContaining('not charger input power'), findsOneWidget);
  });

  testWidgets('makes the estimate and its limits accessible', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpCard(tester, BatteryEstimateResult.available(chargingEstimate()));

    final SemanticsNode node = tester.getSemantics(
      find.byType(SessionEstimateCard),
    );
    expect(node.label, contains('Time to full estimate'));
    expect(node.label, contains('About 50 min'));
    expect(node.label, contains('3 stored samples over 10 min'));
    expect(node.label, contains('not charger input power'));
    handle.dispose();
  });

  testWidgets('shows an explicit reason when evidence is insufficient', (
    WidgetTester tester,
  ) async {
    await pumpCard(
      tester,
      const BatteryEstimateResult.unavailable(
        'At least 3 stored samples are needed; 1 available.',
      ),
    );

    expect(find.text('Time estimate unavailable'), findsOneWidget);
    expect(
      find.text('At least 3 stored samples are needed; 1 available.'),
      findsOneWidget,
    );
    expect(find.text('Estimated'), findsNothing);
  });

  testWidgets('renders nothing when no session is active', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, null);

    expect(find.text('Time to full'), findsNothing);
    expect(find.text('Time estimate unavailable'), findsNothing);
  });

  testWidgets('labels pruned history without hiding a valid window', (
    WidgetTester tester,
  ) async {
    await pumpCard(
      tester,
      BatteryEstimateResult.available(chargingEstimate(pruned: true)),
    );

    expect(find.text('Time to full'), findsOneWidget);
    expect(find.textContaining('Older samples were pruned'), findsOneWidget);
  });

  testWidgets('is overflow-free at 320x640 with 2x text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpCard(
      tester,
      BatteryEstimateResult.available(chargingEstimate(pruned: true)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Time to full'), findsOneWidget);
    expect(find.text('About 50 min'), findsOneWidget);
  });
}
