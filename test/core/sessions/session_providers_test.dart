import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/persistence/persistence_providers.dart';
import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_detail.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

import '../../support/fake_battery_telemetry_service.dart';
import '../../support/fake_session_store.dart';
import '../../support/session_fixtures.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  late FakeSessionStore store;
  late FakeBatteryTelemetryService telemetry;
  late ProviderContainer container;

  setUp(() {
    store = FakeSessionStore();
    telemetry = FakeBatteryTelemetryService();
    container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(store),
        batteryTelemetryServiceProvider.overrideWithValue(telemetry),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await telemetry.dispose();
  });

  test('persists live snapshots through the app-scoped coordinator', () async {
    container.read(sessionTrackingProvider);
    await pumpEventQueue();
    expect(container.read(sessionTrackingProvider).initialized, isTrue);

    telemetry.emit(sessionSnapshot(at: t0, level: 40));
    await pumpEventQueue();
    await pumpEventQueue();

    final SessionTrackingState state = container.read(sessionTrackingProvider);
    expect(state.error, isNull);
    expect(state.activeSession!.id, 1);
    expect(store.sessions, hasLength(1));
    expect(store.samples, hasLength(1));

    telemetry.emit(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 41),
    );
    await pumpEventQueue();
    await pumpEventQueue();
    expect(store.samples, hasLength(2));
    expect(
      container.read(sessionTrackingProvider).activeSession!.sampleCount,
      2,
    );
  });

  test('restores the active session at app startup', () async {
    store.seedActive(
      ChargingSession(
        id: 7,
        startedAt: t0,
        lastObservedAt: t0,
        startLevelPercent: 40,
        state: ChargingSessionState.active,
        sampleCount: 1,
      ),
    );

    container.read(sessionTrackingProvider);
    await pumpEventQueue();

    final SessionTrackingState state = container.read(sessionTrackingProvider);
    expect(state.initialized, isTrue);
    expect(state.activeSession!.id, 7);
    expect(state.error, isNull);
  });

  test('surfaces a storage failure and resumes from committed state', () async {
    container.read(sessionTrackingProvider);
    await pumpEventQueue();
    store.failOperation = 'start';

    telemetry.emit(sessionSnapshot(at: t0, level: 40));
    await pumpEventQueue();
    await pumpEventQueue();

    final SessionTrackingState failed = container.read(sessionTrackingProvider);
    expect(failed.error, isA<StateError>());
    expect(store.sessions, isEmpty);

    store.failOperation = null;
    await container.read(sessionTrackingProvider.notifier).retry();
    await pumpEventQueue();
    expect(container.read(sessionTrackingProvider).error, isNull);

    telemetry.emit(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 41),
    );
    await pumpEventQueue();
    await pumpEventQueue();
    expect(store.sessions, hasLength(1));
    expect(store.samples, hasLength(1));
  });

  test('history refreshes after a committed session update', () async {
    final ProviderSubscription<AsyncValue<List<ChargingSession>>> subscription =
        container.listen<AsyncValue<List<ChargingSession>>>(
          sessionHistoryProvider,
          (_, _) {},
        );
    addTearDown(subscription.close);
    container.read(sessionTrackingProvider);
    await pumpEventQueue();

    telemetry.emit(sessionSnapshot(at: t0, level: 40));
    await pumpEventQueue();
    await pumpEventQueue();
    final List<ChargingSession> first = await container.read(
      sessionHistoryProvider.future,
    );
    expect(first, hasLength(1));
    expect(first.single.sampleCount, 1);

    telemetry.emit(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 41),
    );
    await pumpEventQueue();
    await pumpEventQueue();
    final List<ChargingSession> second = await container.read(
      sessionHistoryProvider.future,
    );
    expect(second.single.sampleCount, 2);
  });

  test('loads one session with its retained samples for detail', () async {
    store.sessions[7] = ChargingSession(
      id: 7,
      startedAt: t0,
      endedAt: t0.add(const Duration(minutes: 2)),
      lastObservedAt: t0.add(const Duration(minutes: 2)),
      startLevelPercent: 40,
      endLevelPercent: 45,
      state: ChargingSessionState.completed,
      sampleCount: 2,
    );
    final TelemetrySample sample = TelemetrySample.fromSnapshot(
      sessionSnapshot(at: t0, level: 40),
    );
    store.samples.add(sample.copyWith(sessionId: 7));

    final SessionDetail? detail = await container.read(
      sessionDetailProvider(7).future,
    );
    expect(detail, isNotNull);
    expect(detail!.session.id, 7);
    expect(detail.samples, hasLength(1));
    expect(detail.samples.single.sessionId, 7);

    expect(await container.read(sessionDetailProvider(999).future), isNull);
  });

  test('has no active estimate when no session is active', () async {
    container.read(sessionTrackingProvider);
    await pumpEventQueue();

    expect(await container.read(activeSessionEstimateProvider.future), isNull);
  });

  test('calculates an active estimate from stored session samples', () async {
    final DateTime now = DateTime.now().toUtc();
    store.sessions[7] = ChargingSession(
      id: 7,
      startedAt: now.subtract(const Duration(minutes: 10)),
      lastObservedAt: now,
      startLevelPercent: 40,
      state: ChargingSessionState.active,
      sampleCount: 3,
    );
    for (final (int minutesAgo, double level) point in <(int, double)>[
      (10, 40),
      (5, 45),
      (0, 50),
    ]) {
      store.samples.add(
        TelemetrySample.fromSnapshot(
          sessionSnapshot(
            at: now.subtract(Duration(minutes: point.$1)),
            level: point.$2,
          ),
          sessionId: 7,
        ),
      );
    }

    container.read(sessionTrackingProvider);
    await pumpEventQueue();

    final BatteryEstimateResult? result = await container.read(
      activeSessionEstimateProvider.future,
    );
    expect(result, isNotNull);
    expect(result!.isAvailable, isTrue);
    expect(result.estimate!.kind, BatteryEstimateKind.timeToFull);
    expect(result.estimate!.remaining, const Duration(minutes: 50));
  });
}
