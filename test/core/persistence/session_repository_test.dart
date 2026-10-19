import 'dart:io';

import 'package:drift/drift.dart'
    show TableOrViewStatements, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:voltly/core/persistence/app_database.dart';
import 'package:voltly/core/persistence/session_retention_policy.dart';
import 'package:voltly/core/persistence/session_repository.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

import '../../support/session_fixtures.dart';
import '../../support/telemetry_fixtures.dart';

void main() {
  // File-backed tests intentionally open a second database instance while the
  // per-test in-memory database is alive. They use separate executors, so the
  // default multi-instance warning is not actionable here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final DateTime t0 = DateTime.utc(2026, 10, 20, 10);

  late VoltlyDatabase database;
  late SessionRepository repository;

  setUp(() {
    database = VoltlyDatabase(NativeDatabase.memory());
    repository = SessionRepository(
      database,
      clock: () => t0.add(const Duration(hours: 1)),
    );
  });

  tearDown(() => database.close());

  ChargingSession activeSession({DateTime? at, double level = 40}) {
    final DateTime time = at ?? t0;
    return ChargingSession(
      startedAt: time,
      lastObservedAt: time,
      startLevelPercent: level,
      state: ChargingSessionState.active,
      sampleCount: 1,
    );
  }

  TelemetrySample sampleAt(
    DateTime at, {
    String state = 'charging',
    double level = 50,
    bool levelAvailable = true,
  }) {
    return TelemetrySample.fromSnapshot(
      sessionSnapshot(
        at: at,
        state: state,
        level: level,
        levelAvailable: levelAvailable,
      ),
    );
  }

  test(
    'creates schema v1 tables, indexes and foreign-key enforcement',
    () async {
      final List<String> tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((row) => row.read<String>('name'))
          .get();
      expect(
        tables,
        containsAll(<String>['charging_sessions', 'telemetry_samples']),
      );

      final List<String> indexes = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .map((row) => row.read<String>('name'))
          .get();
      expect(
        indexes,
        containsAll(<String>[
          'idx_charging_sessions_started_at',
          'idx_charging_sessions_state_started_at',
          'idx_telemetry_samples_session_observed_at',
          'idx_telemetry_samples_observed_at',
        ]),
      );

      final row = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(row.data.values.first, 1);
      final fk = await database.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.data.values.first, 1);
    },
  );

  test('persists a new session and first sample atomically', () async {
    final ChargingSession persisted = await repository.startSession(
      session: activeSession(level: 42),
      sample: sampleAt(t0, level: 42),
    );

    expect(persisted.id, isNotNull);
    final ChargingSession? recovered = await repository.recoverActiveSession();
    expect(recovered, isNotNull);
    expect(recovered!.id, persisted.id);
    expect(recovered.startedAt.isAtSameMomentAs(t0), isTrue);
    expect(recovered.state, ChargingSessionState.active);
    expect(recovered.startLevelPercent, 42);
    expect(recovered.sampleCount, 1);
    expect(recovered.samplesPruned, isFalse);

    final List<TelemetrySample> samples = await repository.samplesForSession(
      persisted.id!,
    );
    expect(samples, hasLength(1));
    final TelemetrySample sample = samples.single;
    expect(sample.sessionId, persisted.id);
    expect(sample.observedAt.isAtSameMomentAs(t0), isTrue);
    expect(sample.batteryLevelPercent, 42);
    expect(sample.chargingState, BatteryChargingState.charging);
    expect(sample.voltageVolts, 4.2);
    expect(sample.currentAmps, 1.5);
    expect(sample.powerWatts, closeTo(6.3, 0.000001));
    expect(sample.snapshot.batteryLevel.source, TelemetrySource.device);
  });

  test('appends samples and persists a completed session in order', () async {
    final DateTime t1 = t0.add(const Duration(minutes: 1));
    final DateTime t2 = t0.add(const Duration(minutes: 2));

    final ChargingSession started = await repository.startSession(
      session: activeSession(level: 40),
      sample: sampleAt(t0, level: 40),
    );
    final int id = started.id!;

    await repository.appendSample(
      sessionId: id,
      session: started.copyWith(sampleCount: 2, lastObservedAt: t1),
      sample: sampleAt(t1, level: 45),
    );

    final ChargingSession ended = started.copyWith(
      sampleCount: 3,
      lastObservedAt: t2,
      endedAt: t2,
      endLevelPercent: 55,
      state: ChargingSessionState.completed,
    );
    await repository.endSession(
      sessionId: id,
      session: ended,
      sample: sampleAt(t2, state: 'discharging', level: 55),
    );

    expect(await repository.recoverActiveSession(), isNull);
    final List<ChargingSession> recent = await repository.recentSessions();
    expect(recent, hasLength(1));
    expect(recent.single.state, ChargingSessionState.completed);
    expect(recent.single.startedAt.isAtSameMomentAs(t0), isTrue);
    expect(recent.single.endedAt!.isAtSameMomentAs(t2), isTrue);
    expect(recent.single.sampleCount, 3);
    expect(recent.single.endLevelPercent, 55);
    expect(recent.single.duration, const Duration(minutes: 2));
    expect(recent.single.levelChangePercent, 15);

    final List<TelemetrySample> samples = await repository.samplesForSession(
      id,
    );
    expect(samples, hasLength(3));
    expect(
      samples.map((TelemetrySample s) => s.observedAt).toList(),
      <DateTime>[t0, t1, t2],
    );
    expect(
      samples.map((TelemetrySample s) => s.batteryLevelPercent).toList(),
      <double>[40, 45, 55],
    );
    expect(
      samples.map((TelemetrySample s) => s.chargingState).toList(),
      <BatteryChargingState>[
        BatteryChargingState.charging,
        BatteryChargingState.charging,
        BatteryChargingState.discharging,
      ],
    );
  });

  test('rolls back when the target session does not exist', () async {
    await expectLater(
      repository.appendSample(
        sessionId: 999,
        session: activeSession(),
        sample: sampleAt(t0),
      ),
      throwsA(isA<StateError>()),
    );

    expect(await database.telemetrySamples.count().getSingle(), 0);
    expect(await database.chargingSessions.count().getSingle(), 0);
  });

  test('stores unavailable metrics as null with their reasons', () async {
    final TelemetrySnapshot snapshot = TelemetrySnapshot.fromPlatformPayload(
      telemetryPayload(
        observedAtMillis: t0.millisecondsSinceEpoch,
        batteryLevel: telemetryReading(
          unit: TelemetryUnits.percent,
          availability: 'unsupported',
          reason: 'No level',
        ),
        voltage: telemetryReading(
          unit: TelemetryUnits.volts,
          availability: 'temporarily_unavailable',
          reason: 'No voltage',
        ),
        currentNow: telemetryReading(
          unit: TelemetryUnits.amperes,
          availability: 'unsupported',
          reason: 'No current',
        ),
      ),
    );
    final ChargingSession persisted = await repository.startSession(
      session: ChargingSession(
        startedAt: t0,
        lastObservedAt: t0,
        state: ChargingSessionState.active,
        sampleCount: 1,
      ),
      sample: TelemetrySample.fromSnapshot(snapshot),
    );

    final TelemetrySample read = (await repository.samplesForSession(
      persisted.id!,
    )).single;
    expect(read.batteryLevelPercent, isNull);
    expect(
      read.snapshot.batteryLevel.availability,
      TelemetryAvailability.unsupported,
    );
    expect(read.snapshot.batteryLevel.reason, 'No level');
    expect(read.voltageVolts, isNull);
    expect(
      read.snapshot.voltage.availability,
      TelemetryAvailability.temporarilyUnavailable,
    );
    expect(read.powerWatts, isNull);

    final TelemetrySampleRow row = await database
        .select(database.telemetrySamples)
        .getSingle();
    expect(row.batteryLevelPercent, isNull);
    expect(row.voltageVolts, isNull);
    expect(row.currentAmps, isNull);
    expect(row.powerWatts, isNull);
    expect(row.availabilityMetadata, contains('unsupported'));
  });

  test('ignores a duplicate sample at the same session timestamp', () async {
    final ChargingSession started = await repository.startSession(
      session: activeSession(),
      sample: sampleAt(t0),
    );
    final TelemetrySample duplicate = sampleAt(t0);

    await repository.appendSample(
      sessionId: started.id!,
      session: started,
      sample: duplicate,
    );

    expect(
      await database.telemetrySamples
          .count(where: (TelemetrySamples t) => t.sessionId.equals(started.id!))
          .getSingle(),
      1,
    );
  });

  test('reconciles duplicate active sessions on recovery', () async {
    final DateTime t1 = t0.add(const Duration(minutes: 1));
    final ChargingSession older = await repository.startSession(
      session: activeSession(),
      sample: sampleAt(t0),
    );
    final ChargingSession newer = await repository.startSession(
      session: activeSession(at: t1),
      sample: sampleAt(t1),
    );

    final ChargingSession? recovered = await repository.recoverActiveSession();
    expect(recovered!.id, newer.id);

    final ChargingSession? reconciled = await repository.sessionById(older.id!);
    expect(reconciled!.state, ChargingSessionState.interrupted);
    expect(reconciled.endedAt!.isAtSameMomentAs(t1), isTrue);
    expect(reconciled.hasSamplingGaps, isTrue);
  });

  test('deletes all sessions and their samples together', () async {
    await repository.startSession(
      session: activeSession(),
      sample: sampleAt(t0),
    );
    await repository.startSession(
      session: activeSession(at: t0.add(const Duration(minutes: 1))),
      sample: sampleAt(t0.add(const Duration(minutes: 1))),
    );

    expect(await repository.deleteAllSessions(), 2);
    expect(await database.chargingSessions.count().getSingle(), 0);
    expect(await database.telemetrySamples.count().getSingle(), 0);
  });

  test(
    'retains only the newest ended sessions and keeps active sessions',
    () async {
      final SessionRepository retentionRepository = SessionRepository(
        database,
        retention: const SessionRetentionPolicy(
          maxEndedSessions: 2,
          maxAge: Duration(days: 365),
          maxSamplesPerSession: 100,
        ),
        clock: () => t0.add(const Duration(hours: 10)),
      );

      final List<int> endedIds = <int>[];
      for (int i = 0; i < 3; i++) {
        final DateTime start = t0.add(Duration(hours: i));
        final ChargingSession started = await retentionRepository.startSession(
          session: activeSession(at: start),
          sample: sampleAt(start),
        );
        final DateTime end = start.add(const Duration(minutes: 1));
        final ChargingSession ended = started.copyWith(
          endedAt: end,
          endLevelPercent: 60,
          lastObservedAt: end,
          sampleCount: 2,
          state: ChargingSessionState.completed,
        );
        await retentionRepository.endSession(
          sessionId: started.id!,
          session: ended,
          sample: sampleAt(end, state: 'discharging', level: 60),
        );
        endedIds.add(started.id!);
      }

      expect(await database.chargingSessions.count().getSingle(), 2);
      expect(await retentionRepository.sessionById(endedIds[0]), isNull);
      expect(await retentionRepository.samplesForSession(endedIds[0]), isEmpty);
      expect(await retentionRepository.sessionById(endedIds[1]), isNotNull);
      expect(await retentionRepository.sessionById(endedIds[2]), isNotNull);

      final DateTime activeStart = t0.add(const Duration(hours: 5));
      final ChargingSession active = await retentionRepository.startSession(
        session: activeSession(at: activeStart),
        sample: sampleAt(activeStart),
      );
      await retentionRepository.enforceRetention(
        now: t0.add(const Duration(hours: 10)),
      );
      expect((await retentionRepository.recoverActiveSession())?.id, active.id);
    },
  );

  test('removes ended sessions older than the age bound', () async {
    final DateTime now = t0.add(const Duration(days: 10));
    final SessionRepository retentionRepository = SessionRepository(
      database,
      retention: const SessionRetentionPolicy(
        maxEndedSessions: 10,
        maxAge: Duration(days: 1),
        maxSamplesPerSession: 100,
      ),
      clock: () => now,
    );

    final ChargingSession old = await retentionRepository.startSession(
      session: activeSession(),
      sample: sampleAt(t0),
    );
    final DateTime oldEnd = t0.add(const Duration(minutes: 1));
    await retentionRepository.endSession(
      sessionId: old.id!,
      session: old.copyWith(
        endedAt: oldEnd,
        endLevelPercent: 60,
        lastObservedAt: oldEnd,
        sampleCount: 2,
        state: ChargingSessionState.completed,
      ),
      sample: sampleAt(oldEnd, state: 'discharging', level: 60),
    );

    expect(await retentionRepository.recentSessions(), isEmpty);
    expect(await retentionRepository.samplesForSession(old.id!), isEmpty);

    final DateTime recentStart = now.subtract(const Duration(hours: 1));
    final ChargingSession recent = await retentionRepository.startSession(
      session: activeSession(at: recentStart),
      sample: sampleAt(recentStart),
    );
    final DateTime recentEnd = recentStart.add(const Duration(minutes: 1));
    await retentionRepository.endSession(
      sessionId: recent.id!,
      session: recent.copyWith(
        endedAt: recentEnd,
        endLevelPercent: 70,
        lastObservedAt: recentEnd,
        sampleCount: 2,
        state: ChargingSessionState.completed,
      ),
      sample: sampleAt(recentEnd, state: 'discharging', level: 70),
    );

    expect(await retentionRepository.recentSessions(), hasLength(1));

    final DateTime longStart = now.subtract(const Duration(days: 2));
    final ChargingSession longSession = await retentionRepository.startSession(
      session: activeSession(at: longStart),
      sample: sampleAt(longStart),
    );
    await retentionRepository.endSession(
      sessionId: longSession.id!,
      session: longSession.copyWith(
        endedAt: now,
        endLevelPercent: 80,
        lastObservedAt: now,
        sampleCount: 2,
        state: ChargingSessionState.completed,
      ),
      sample: sampleAt(now, state: 'discharging', level: 80),
    );

    // The age bound is based on when the session ended, not when it started.
    expect(await retentionRepository.sessionById(longSession.id!), isNotNull);
    expect(await retentionRepository.recentSessions(), hasLength(2));
  });

  test(
    'caps stored samples per session and marks the sample list pruned',
    () async {
      final SessionRepository cappedRepository = SessionRepository(
        database,
        retention: const SessionRetentionPolicy(
          maxEndedSessions: 10,
          maxAge: Duration(days: 365),
          maxSamplesPerSession: 2,
        ),
        clock: () => t0.add(const Duration(hours: 1)),
      );
      final DateTime t1 = t0.add(const Duration(minutes: 1));
      final DateTime t2 = t0.add(const Duration(minutes: 2));

      final ChargingSession started = await cappedRepository.startSession(
        session: activeSession(level: 40),
        sample: sampleAt(t0, level: 40),
      );
      await cappedRepository.appendSample(
        sessionId: started.id!,
        session: started.copyWith(sampleCount: 2, lastObservedAt: t1),
        sample: sampleAt(t1, level: 41),
      );
      await cappedRepository.appendSample(
        sessionId: started.id!,
        session: started.copyWith(sampleCount: 3, lastObservedAt: t2),
        sample: sampleAt(t2, level: 42),
      );

      final List<TelemetrySample> samples = await cappedRepository
          .samplesForSession(started.id!);
      expect(samples, hasLength(2));
      expect(
        samples.map((TelemetrySample s) => s.batteryLevelPercent).toList(),
        <double>[41, 42],
      );
      final ChargingSession reloaded = (await cappedRepository.sessionById(
        started.id!,
      ))!;
      expect(reloaded.sampleCount, 3);
      expect(reloaded.samplesPruned, isTrue);

      // A later write from an in-memory session that does not know about
      // pruning must not clear the persistent flag.
      await cappedRepository.appendSample(
        sessionId: started.id!,
        session: started.copyWith(sampleCount: 3, lastObservedAt: t2),
        sample: sampleAt(t2, level: 42),
      );
      final ChargingSession stillPruned = (await cappedRepository.sessionById(
        started.id!,
      ))!;
      expect(stillPruned.samplesPruned, isTrue);
      expect(
        await cappedRepository.samplesForSession(started.id!),
        hasLength(2),
      );
    },
  );

  test(
    'reopens a file-backed v1 database and restores the active session',
    () async {
      final Directory directory = await Directory.systemTemp.createTemp(
        'voltly-reopen-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final File file = File(p.join(directory.path, 'voltly.sqlite'));

      VoltlyDatabase fileDatabase = VoltlyDatabase(NativeDatabase(file));
      SessionRepository fileRepository = SessionRepository(
        fileDatabase,
        clock: () => t0.add(const Duration(hours: 1)),
      );
      final ChargingSession started = await fileRepository.startSession(
        session: activeSession(level: 37),
        sample: sampleAt(t0, level: 37),
      );
      final int id = started.id!;
      await fileDatabase.close();

      fileDatabase = VoltlyDatabase(NativeDatabase(file));
      addTearDown(fileDatabase.close);
      fileRepository = SessionRepository(
        fileDatabase,
        clock: () => t0.add(const Duration(hours: 1)),
      );

      final ChargingSession? recovered = await fileRepository
          .recoverActiveSession();
      expect(recovered, isNotNull);
      expect(recovered!.id, id);
      expect(recovered.startLevelPercent, 37);
      expect(recovered.startedAt.isAtSameMomentAs(t0), isTrue);
      expect(await fileRepository.samplesForSession(id), hasLength(1));
    },
  );

  test('rejects a database written by a newer schema version', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'voltly-newer-schema-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final File file = File(p.join(directory.path, 'voltly.sqlite'));

    VoltlyDatabase fileDatabase = VoltlyDatabase(NativeDatabase(file));
    await fileDatabase.customSelect('SELECT 1').getSingle();
    await fileDatabase.customStatement('PRAGMA user_version = 2');
    await fileDatabase.close();

    fileDatabase = VoltlyDatabase(NativeDatabase(file));
    addTearDown(fileDatabase.close);
    final SessionRepository newerRepository = SessionRepository(fileDatabase);

    await expectLater(
      newerRepository.recoverActiveSession(),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
