import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/core/persistence/persistence_providers.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/features/sessions/session_history_screen.dart';

import '../../support/fake_session_store.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  ChargingSession activeSession() => ChargingSession(
    id: 1,
    startedAt: t0,
    lastObservedAt: t0.add(const Duration(minutes: 5)),
    startLevelPercent: 40,
    state: ChargingSessionState.active,
    sampleCount: 6,
    hasSamplingGaps: true,
  );

  ChargingSession completedSession() => ChargingSession(
    id: 2,
    startedAt: t0.subtract(const Duration(hours: 2)),
    endedAt: t0.subtract(const Duration(hours: 1)),
    lastObservedAt: t0.subtract(const Duration(hours: 1)),
    startLevelPercent: 30,
    endLevelPercent: 70,
    state: ChargingSessionState.completed,
    sampleCount: 25,
  );

  ChargingSession interruptedSession() => ChargingSession(
    id: 3,
    startedAt: t0.subtract(const Duration(hours: 3)),
    endedAt: t0.subtract(const Duration(hours: 2)),
    lastObservedAt: t0.subtract(const Duration(hours: 2)),
    startLevelPercent: 50,
    endLevelPercent: 55,
    state: ChargingSessionState.interrupted,
    sampleCount: 3,
    samplesPruned: true,
  );

  Future<void> pumpHistory(
    WidgetTester tester,
    List<ChargingSession> sessions,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionHistoryProvider.overrideWith((ref) async => sessions),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SessionHistoryScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders active, completed and interrupted sessions honestly', (
    WidgetTester tester,
  ) async {
    await pumpHistory(tester, <ChargingSession>[
      activeSession(),
      completedSession(),
      interruptedSession(),
    ]);

    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Interrupted'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Stored'), findsNWidgets(2));
    expect(find.text('Telemetry gaps'), findsOneWidget);
    expect(find.text('Samples pruned'), findsNothing);
    expect(find.text('Partial session'), findsOneWidget);
    expect(find.text('Older samples pruned'), findsOneWidget);
    expect(find.textContaining('Charged 30% to 70%'), findsOneWidget);
    expect(find.text('In progress'), findsWidgets);
    expect(find.textContaining('Started '), findsNWidgets(3));
    expect(find.textContaining('Ended '), findsNWidgets(3));
    expect(find.text('1 h'), findsNWidgets(2));
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('shows an empty state without inventing sessions', (
    WidgetTester tester,
  ) async {
    await pumpHistory(tester, <ChargingSession>[]);

    expect(find.text('No charging sessions yet'), findsOneWidget);
    expect(find.textContaining('never filled in'), findsOneWidget);
    expect(find.text('Recording'), findsNothing);
  });

  testWidgets('shows a storage error with retry', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionHistoryProvider.overrideWith(
            (ref) async => throw StateError('database unavailable'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SessionHistoryScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session history unavailable'), findsOneWidget);
    expect(find.text('database unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows a loading state', (WidgetTester tester) async {
    final Completer<List<ChargingSession>> completer =
        Completer<List<ChargingSession>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionHistoryProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SessionHistoryScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading sessions…'), findsOneWidget);
    completer.complete(<ChargingSession>[]);
    await tester.pump();
  });

  testWidgets('history is overflow-free at 320x640 with 2x text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpHistory(tester, <ChargingSession>[
      activeSession(),
      completedSession(),
      interruptedSession(),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Session history'), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Telemetry gaps'), findsOneWidget);
  });

  testWidgets('exposes a concise semantics label per session', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpHistory(tester, <ChargingSession>[completedSession()]);

    final SemanticsNode node = tester.getSemantics(find.byType(Card).first);
    expect(node.label, contains('Charging session. Completed.'));
    expect(node.label, contains('Start level 30%.'));
    expect(node.label, contains('End level 70%.'));
    expect(node.label, contains('25 samples.'));
    handle.dispose();
  });

  testWidgets('opens a session detail from a history card', (
    WidgetTester tester,
  ) async {
    final FakeSessionStore store = FakeSessionStore();
    store.sessions[2] = completedSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SessionHistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Completed'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Session detail'), findsOneWidget);
    expect(find.text('Stored trends'), findsOneWidget);
  });
}
