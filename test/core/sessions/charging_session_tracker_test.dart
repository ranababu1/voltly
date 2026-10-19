import 'package:flutter_test/flutter_test.dart';

import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/charging_session_tracker.dart';

import '../../support/session_fixtures.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  test('starts one session on the first charging observation', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();

    final SessionUpdate update = tracker.observe(
      sessionSnapshot(at: t0, level: 42),
    );

    expect(update.kind, SessionUpdateKind.started);
    expect(update.sample, isNotNull);
    final ChargingSession session = update.session!;
    expect(session.state, ChargingSessionState.active);
    expect(session.startedAt, t0);
    expect(session.lastObservedAt, t0);
    expect(session.startLevelPercent, 42);
    expect(session.endLevelPercent, isNull);
    expect(session.sampleCount, 1);
    expect(session.endedAt, isNull);
    expect(update.sample!.batteryLevelPercent, 42);
    expect(tracker.activeSession?.startedAt, t0);
  });

  test('repeated charging observations extend the same session', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 40));

    final SessionUpdate update = tracker.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 41),
    );

    expect(update.kind, SessionUpdateKind.sample);
    expect(update.session!.state, ChargingSessionState.active);
    expect(update.session!.startedAt, t0);
    expect(update.session!.startLevelPercent, 40);
    expect(update.session!.sampleCount, 2);
    expect(update.session!.lastObservedAt, t0.add(const Duration(minutes: 1)));
    expect(tracker.activeSession!.sampleCount, 2);
  });

  test('discharging completes the active session with level change', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 40));

    final DateTime end = t0.add(const Duration(minutes: 30));
    final SessionUpdate update = tracker.observe(
      sessionSnapshot(at: end, state: 'discharging', level: 55),
    );

    final ChargingSession session = update.session!;
    expect(update.kind, SessionUpdateKind.ended);
    expect(session.state, ChargingSessionState.completed);
    expect(session.endedAt, end);
    expect(session.endLevelPercent, 55);
    expect(session.duration, const Duration(minutes: 30));
    expect(session.levelChangePercent, 15);
    expect(session.sampleCount, 2);
    expect(tracker.activeSession, isNull);
  });

  test('full completes the active session', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 90));

    final SessionUpdate update = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 20)),
        state: 'full',
        level: 100,
      ),
    );

    expect(update.kind, SessionUpdateKind.ended);
    expect(update.session!.state, ChargingSessionState.completed);
    expect(update.session!.endLevelPercent, 100);
    expect(tracker.activeSession, isNull);
  });

  test('ignores non-charging observations when no session is active', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();

    for (final String state in <String>[
      'discharging',
      'not_charging',
      'full',
    ]) {
      final SessionUpdate update = tracker.observe(
        sessionSnapshot(at: t0, state: state),
      );
      expect(update.kind, SessionUpdateKind.none);
      expect(update.sample, isNull);
      expect(tracker.activeSession, isNull);
    }
  });

  test(
    'tolerates a brief not_charging pause without splitting the session',
    () {
      final ChargingSessionTracker tracker = ChargingSessionTracker();
      tracker.observe(sessionSnapshot(at: t0, level: 40));

      final SessionUpdate pause = tracker.observe(
        sessionSnapshot(
          at: t0.add(const Duration(minutes: 1)),
          state: 'not_charging',
          level: 42,
        ),
      );
      expect(pause.kind, SessionUpdateKind.sample);
      expect(pause.session!.state, ChargingSessionState.active);
      expect(tracker.activeSession, isNotNull);

      final SessionUpdate resume = tracker.observe(
        sessionSnapshot(
          at: t0.add(const Duration(minutes: 1, seconds: 30)),
          level: 43,
        ),
      );

      expect(resume.kind, SessionUpdateKind.sample);
      expect(resume.session!.state, ChargingSessionState.active);
      expect(resume.session!.startedAt, t0);
      expect(resume.session!.sampleCount, 3);
      expect(tracker.activeSession!.startedAt, t0);
    },
  );

  test('ends a persistent not_charging state as interrupted', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 40));

    tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 1)),
        state: 'not_charging',
        level: 42,
      ),
    );

    final SessionUpdate update = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 3, seconds: 1)),
        state: 'not_charging',
        level: 42,
      ),
    );

    expect(update.kind, SessionUpdateKind.ended);
    expect(update.session!.state, ChargingSessionState.interrupted);
    expect(update.session!.isPartial, isTrue);
    expect(
      update.session!.endedAt,
      t0.add(const Duration(minutes: 3, seconds: 1)),
    );
    expect(tracker.activeSession, isNull);
  });

  test('ignores duplicate and out-of-order timestamps', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 40));

    final SessionUpdate duplicate = tracker.observe(
      sessionSnapshot(at: t0, level: 41),
    );
    final SessionUpdate earlier = tracker.observe(
      sessionSnapshot(at: t0.subtract(const Duration(seconds: 1)), level: 42),
    );

    expect(duplicate.kind, SessionUpdateKind.none);
    expect(earlier.kind, SessionUpdateKind.none);
    expect(tracker.activeSession!.sampleCount, 1);

    final SessionUpdate later = tracker.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 1)), level: 43),
    );
    expect(later.kind, SessionUpdateKind.sample);
    expect(later.session!.sampleCount, 2);
  });

  test('marks a long sampling gap instead of implying continuous coverage', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 40));

    final SessionUpdate resumed = tracker.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 10)), level: 50),
    );

    expect(resumed.session!.hasSamplingGaps, isTrue);
    expect(resumed.session!.maxSamplingGap, const Duration(minutes: 10));
    expect(resumed.session!.sampleCount, 2);

    final SessionUpdate ended = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 11)),
        state: 'discharging',
        level: 51,
      ),
    );

    expect(ended.session!.hasSamplingGaps, isTrue);
    expect(ended.session!.isPartial, isTrue);
    expect(ended.session!.maxSamplingGap, const Duration(minutes: 10));
  });

  test('keeps a session active when the charging state is unavailable', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 40));

    final SessionUpdate update = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 1)),
        stateAvailable: false,
        level: 48,
      ),
    );

    expect(update.kind, SessionUpdateKind.sample);
    expect(update.session!.state, ChargingSessionState.active);
    expect(update.sample!.chargingState, isNull);
    expect(update.sample!.batteryLevelPercent, 48);
    expect(tracker.activeSession, isNotNull);

    final SessionUpdate ended = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 2)),
        state: 'discharging',
        level: 50,
      ),
    );
    expect(ended.kind, SessionUpdateKind.ended);
    expect(ended.session!.state, ChargingSessionState.completed);
  });

  test('does not fabricate an end level when it is unavailable', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.observe(sessionSnapshot(at: t0, level: 50));

    final SessionUpdate update = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 5)),
        state: 'discharging',
        levelAvailable: false,
      ),
    );

    expect(update.session!.endLevelPercent, isNull);
    expect(update.session!.levelChangePercent, isNull);
    expect(update.session!.state, ChargingSessionState.completed);
  });

  test('keeps an unavailable start level null', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    final SessionUpdate update = tracker.observe(
      sessionSnapshot(at: t0, levelAvailable: false),
    );

    expect(update.kind, SessionUpdateKind.started);
    expect(update.session!.startLevelPercent, isNull);
    expect(update.sample!.batteryLevelPercent, isNull);
  });

  test('restores an active session and flags the restart gap', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    tracker.restoreActiveSession(
      ChargingSession(
        id: 7,
        startedAt: t0,
        lastObservedAt: t0.add(const Duration(minutes: 1)),
        startLevelPercent: 40,
        state: ChargingSessionState.active,
        sampleCount: 3,
      ),
    );

    final SessionUpdate resumed = tracker.observe(
      sessionSnapshot(at: t0.add(const Duration(minutes: 10)), level: 60),
    );

    expect(resumed.kind, SessionUpdateKind.sample);
    expect(resumed.session!.id, 7);
    expect(resumed.session!.startedAt, t0);
    expect(resumed.session!.sampleCount, 4);
    expect(resumed.session!.hasSamplingGaps, isTrue);
    expect(resumed.session!.maxSamplingGap, const Duration(minutes: 9));

    final SessionUpdate ended = tracker.observe(
      sessionSnapshot(
        at: t0.add(const Duration(minutes: 11)),
        state: 'discharging',
        level: 60,
      ),
    );
    expect(ended.session!.state, ChargingSessionState.completed);
    expect(ended.session!.endLevelPercent, 60);
  });

  test('rejects restoring a session that is not active', () {
    final ChargingSessionTracker tracker = ChargingSessionTracker();
    expect(
      () => tracker.restoreActiveSession(
        ChargingSession(
          startedAt: t0,
          endedAt: t0.add(const Duration(minutes: 1)),
          state: ChargingSessionState.completed,
        ),
      ),
      throwsArgumentError,
    );
  });
}
