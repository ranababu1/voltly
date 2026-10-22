import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/core/persistence/persistence_providers.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/features/sessions/session_detail_screen.dart';
import 'package:voltly/features/sessions/session_trend_chart.dart';

import '../../support/fake_session_store.dart';
import '../../support/session_fixtures.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  ChargingSession completedSession({
    bool gaps = false,
    bool pruned = false,
    int sampleCount = 4,
  }) => ChargingSession(
    id: 1,
    startedAt: t0,
    endedAt: t0.add(const Duration(minutes: 30)),
    lastObservedAt: t0.add(const Duration(minutes: 3)),
    startLevelPercent: 40,
    endLevelPercent: 60,
    state: ChargingSessionState.completed,
    sampleCount: sampleCount,
    hasSamplingGaps: gaps,
    samplesPruned: pruned,
  );

  TelemetrySample sampleAt(DateTime at, double level) =>
      TelemetrySample.fromSnapshot(sessionSnapshot(at: at, level: level));

  FakeSessionStore seededStore({
    ChargingSession? session,
    List<TelemetrySample>? samples,
  }) {
    final FakeSessionStore store = FakeSessionStore();
    store.sessions[1] = session ?? completedSession();
    for (final TelemetrySample sample
        in samples ??
            <TelemetrySample>[
              sampleAt(t0, 40),
              sampleAt(t0.add(const Duration(minutes: 1)), 45),
              sampleAt(t0.add(const Duration(minutes: 2)), 50),
              sampleAt(t0.add(const Duration(minutes: 3)), 60),
            ]) {
      store.samples.add(sample.copyWith(sessionId: 1));
    }
    return store;
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    FakeSessionStore store, {
    int sessionId = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: SessionDetailScreen(sessionId: sessionId),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders stored summary and all trend cards', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, seededStore());

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Stored'), findsOneWidget);
    expect(find.textContaining('Charged 40% to 60%'), findsOneWidget);
    expect(find.text('Stored trends'), findsOneWidget);
    expect(find.text('Battery level'), findsOneWidget);
    expect(find.text('Current now'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Battery-side power'), findsOneWidget);
    expect(find.text('4 stored samples'), findsNWidgets(4));
    expect(find.textContaining('No sampling breaks'), findsNWidgets(4));
    expect(find.byType(SessionTrendCard), findsNWidgets(4));
    expect(find.textContaining('not charger input power'), findsOneWidget);
  });

  testWidgets('marks gaps, partial sessions and pruned samples', (
    WidgetTester tester,
  ) async {
    final ChargingSession interrupted = completedSession(
      gaps: true,
      pruned: true,
    ).copyWith(state: ChargingSessionState.interrupted);
    await pumpDetail(
      tester,
      seededStore(
        session: interrupted,
        samples: <TelemetrySample>[
          sampleAt(t0, 40),
          sampleAt(t0.add(const Duration(minutes: 10)), 50),
        ],
      ),
    );

    expect(find.text('Interrupted'), findsOneWidget);
    expect(find.text('Partial session'), findsOneWidget);
    expect(find.text('Older samples pruned'), findsOneWidget);
    expect(
      find.textContaining('Line breaks mark sampling gaps'),
      findsNWidgets(4),
    );
    expect(find.textContaining('Older samples were pruned'), findsNWidgets(4));
    expect(find.textContaining('1 sampling break'), findsNWidgets(4));
  });

  testWidgets('does not invent chart values when no samples were retained', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, seededStore(samples: <TelemetrySample>[]));

    expect(find.text('No stored samples'), findsNWidgets(4));
    expect(find.text('No stored battery level values.'), findsOneWidget);
    expect(find.textContaining('No sampling breaks'), findsNothing);
  });

  testWidgets('shows a not-found state for a deleted session', (
    WidgetTester tester,
  ) async {
    await pumpDetail(tester, FakeSessionStore(), sessionId: 99);

    expect(find.text('Session not found'), findsOneWidget);
    expect(find.textContaining('retention'), findsOneWidget);
    expect(find.text('Battery level'), findsNothing);
  });

  testWidgets('shows a storage error with retry', (WidgetTester tester) async {
    final FakeSessionStore store = FakeSessionStore()
      ..failOperation = 'session';
    await pumpDetail(tester, store);

    expect(find.text('Session detail unavailable'), findsOneWidget);
    expect(find.textContaining('session failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('detail is overflow-free at 320x640 with 2x text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpDetail(tester, seededStore());

    expect(tester.takeException(), isNull);
    expect(find.text('Session detail'), findsOneWidget);
    expect(find.text('Battery level'), findsOneWidget);
  });

  testWidgets('trend cards expose chart semantics', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpDetail(tester, seededStore());

    final SemanticsNode node = tester.getSemantics(
      find.byType(SessionTrendCard).first,
    );
    expect(node.label, contains('Battery level trend.'));
    expect(node.label, contains('4 stored samples.'));
    expect(node.label, contains('gaps are not interpolated.'));
    handle.dispose();
  });
}
