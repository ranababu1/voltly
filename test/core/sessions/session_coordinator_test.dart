import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_coordinator.dart';

import '../../support/fake_session_store.dart';
import '../../support/session_fixtures.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  test('starts, appends and ends one persisted session', () async {
    final FakeSessionStore store = FakeSessionStore();
    final SessionCoordinator coordinator = SessionCoordinator(store);

    expect(await coordinator.initialize(), isNull);
    final ChargingSession? started = await coordinator.observe(
      sessionSnapshot(at: t0, level: 40),
    );
    expect(started!.id, 1);
    expect(started.sampleCount, 1);
    expect(store.samples, hasLength(1));

    final ChargingSession? next = await coordinator.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 45),
    );
    expect(next!.id, 1);
    expect(next.sampleCount, 2);
    expect(store.samples, hasLength(2));

    final ChargingSession? ended = await coordinator.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 2)),
        state: 'discharging',
        level: 50,
      ),
    );
    expect(ended, isNull);
    final ChargingSession stored = store.sessions[1]!;
    expect(stored.state, ChargingSessionState.completed);
    expect(stored.endLevelPercent, 50);
    expect(stored.sampleCount, 3);
    expect(store.samples, hasLength(3));
  });

  test('restores the active session and records the restart gap', () async {
    final FakeSessionStore store = FakeSessionStore();
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
    final SessionCoordinator coordinator = SessionCoordinator(store);

    final ChargingSession? recovered = await coordinator.initialize();
    expect(recovered!.id, 7);
    expect(store.recoverCalls, 1);

    final ChargingSession? resumed = await coordinator.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 10)), level: 45),
    );
    expect(resumed!.id, 7);
    expect(resumed.hasSamplingGaps, isTrue);
    expect(resumed.maxSamplingGap, const Duration(minutes: 10));
    expect(store.sessions[7]!.sampleCount, 2);
    expect(store.samples.single.sessionId, 7);
  });

  test('ignores duplicate and out-of-order snapshots', () async {
    final FakeSessionStore store = FakeSessionStore();
    final SessionCoordinator coordinator = SessionCoordinator(store);
    await coordinator.observe(sessionSnapshot(at: t0, level: 40));

    final ChargingSession? duplicate = await coordinator.observe(
      sessionSnapshot(at: t0, level: 99),
    );
    final ChargingSession? earlier = await coordinator.observe(
      sessionSnapshot(at: t0.subtract(const Duration(minutes: 1)), level: 98),
    );

    expect(duplicate!.sampleCount, 1);
    expect(earlier!.sampleCount, 1);
    expect(store.samples, hasLength(1));
  });

  test('serializes concurrent observations into one session', () async {
    final FakeSessionStore store = FakeSessionStore();
    final SessionCoordinator coordinator = SessionCoordinator(store);

    final List<ChargingSession?> results = await Future.wait(
      <Future<ChargingSession?>>[
        coordinator.observe(sessionSnapshot(at: t0, level: 40)),
        coordinator.observe(
          sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 41),
        ),
      ],
    );

    expect(results[0]!.id, 1);
    expect(results[1]!.id, 1);
    expect(store.sessions, hasLength(1));
    expect(store.samples, hasLength(2));
    expect(store.recoverCalls, 1);
  });

  test('recovers committed state after an append failure', () async {
    final FakeSessionStore store = FakeSessionStore();
    final SessionCoordinator coordinator = SessionCoordinator(store);
    await coordinator.observe(sessionSnapshot(at: t0, level: 40));
    store.failOperation = 'append';

    await expectLater(
      coordinator.observe(
        sessionSnapshot(at: t0.add(const Duration(minutes: 10)), level: 45),
      ),
      throwsA(isA<StateError>()),
    );
    expect(store.sessions[1]!.sampleCount, 1);
    expect(store.samples, hasLength(1));

    store.failOperation = null;
    final ChargingSession? recovered = await coordinator.recover();
    expect(recovered!.id, 1);
    expect(recovered.sampleCount, 1);

    final ChargingSession? resumed = await coordinator.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 20)), level: 50),
    );
    expect(resumed!.id, 1);
    expect(resumed.hasSamplingGaps, isTrue);
    expect(store.sessions[1]!.sampleCount, 2);
  });

  test('a failed start does not leave a phantom persisted session', () async {
    final FakeSessionStore store = FakeSessionStore();
    final SessionCoordinator coordinator = SessionCoordinator(store);
    store.failOperation = 'start';

    await expectLater(
      coordinator.observe(sessionSnapshot(at: t0, level: 40)),
      throwsA(isA<StateError>()),
    );
    expect(store.sessions, isEmpty);
    expect(store.samples, isEmpty);

    store.failOperation = null;
    expect(await coordinator.recover(), isNull);
    final ChargingSession? started = await coordinator.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 41),
    );
    expect(started!.id, 1);
    expect(store.samples, hasLength(1));
  });
}
