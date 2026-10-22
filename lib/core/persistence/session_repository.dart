import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:voltly/core/persistence/app_database.dart';
import 'package:voltly/core/persistence/sample_mapper.dart';
import 'package:voltly/core/persistence/sample_metadata.dart';
import 'package:voltly/core/persistence/session_retention_policy.dart';
import 'package:voltly/core/persistence/session_store.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Transactional persistence for charging sessions and their samples.
///
/// A session summary and its sample are always written in one transaction. The
/// repository never invents values: unavailable readings are stored as null and
/// their availability/reason metadata is preserved.
class SessionRepository implements SessionStore {
  SessionRepository(
    this.database, {
    this.retention = const SessionRetentionPolicy(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    retention.validate();
  }

  final VoltlyDatabase database;
  final SessionRetentionPolicy retention;
  final DateTime Function() _clock;

  /// Inserts a new active session and its first sample, returning the persisted
  /// session with its database id.
  @override
  Future<ChargingSession> startSession({
    required ChargingSession session,
    required TelemetrySample sample,
  }) async {
    if (!session.isActive) {
      throw ArgumentError.value(session, 'session', 'Session must be active.');
    }
    if (session.id != null) {
      throw ArgumentError.value(
        session,
        'session',
        'A new session must not already have an id.',
      );
    }

    return database.transaction(() async {
      final DateTime now = _clock().toUtc();
      final int id = await database
          .into(database.chargingSessions)
          .insert(_insertCompanion(session, now));
      await _insertSample(id, sample);
      await _applySampleCap(id, retention.maxSamplesPerSession);
      await _enforceRetention(now);
      return session.copyWith(id: id);
    });
  }

  /// Appends a sample and updates the active session summary atomically.
  @override
  Future<void> appendSample({
    required int sessionId,
    required ChargingSession session,
    required TelemetrySample sample,
  }) async {
    if (!session.isActive) {
      throw ArgumentError.value(session, 'session', 'Session must be active.');
    }
    await _persistUpdate(sessionId, session, sample);
  }

  /// Writes the final sample and the terminal session state atomically.
  @override
  Future<void> endSession({
    required int sessionId,
    required ChargingSession session,
    required TelemetrySample sample,
  }) async {
    if (session.isActive) {
      throw ArgumentError.value(
        session,
        'session',
        'An ending session must have a terminal state.',
      );
    }
    await _persistUpdate(sessionId, session, sample);
  }

  /// Returns the newest active session, reconciling any duplicate active rows.
  ///
  /// A process crash or external database edit could leave more than one active
  /// row. The newest is retained; older rows are marked interrupted at the
  /// newest session's start and their gap flag is set, preventing a false claim
  /// of continuous coverage.
  @override
  Future<ChargingSession?> recoverActiveSession() {
    return database.transaction(() async {
      final List<ChargingSessionRow> rows =
          await (database.select(database.chargingSessions)
                ..where(
                  (ChargingSessions t) =>
                      t.sessionState.equals(ChargingSessionState.active.name),
                )
                ..orderBy(<OrderingTerm Function(ChargingSessions)>[
                  (ChargingSessions t) => OrderingTerm.desc(t.startedAt),
                  (ChargingSessions t) => OrderingTerm.desc(t.id),
                ]))
              .get();

      if (rows.isEmpty) return null;

      final ChargingSessionRow newest = rows.first;
      if (rows.length > 1) {
        final DateTime now = _clock().toUtc();
        for (final ChargingSessionRow older in rows.skip(1)) {
          await (database.update(
            database.chargingSessions,
          )..where((ChargingSessions t) => t.id.equals(older.id))).write(
            ChargingSessionsCompanion(
              sessionState: const Value(ChargingSessionState.interrupted),
              endedAt: Value(older.endedAt ?? newest.startedAt),
              hasSamplingGaps: const Value(true),
              updatedAt: Value(now),
            ),
          );
        }
      }
      return _toDomain(newest);
    });
  }

  Future<ChargingSession?> sessionById(int id) async {
    final ChargingSessionRow? row = await (database.select(
      database.chargingSessions,
    )..where((ChargingSessions t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<ChargingSession>> recentSessions({int limit = 20}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Limit must be positive.');
    }
    return (database.select(database.chargingSessions)
          ..orderBy(<OrderingTerm Function(ChargingSessions)>[
            (ChargingSessions t) => OrderingTerm.desc(t.startedAt),
            (ChargingSessions t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get()
        .then(
          (List<ChargingSessionRow> rows) =>
              rows.map(_toDomain).toList(growable: false),
        );
  }

  /// Returns stored samples in observation order. Missing metadata becomes an
  /// invalid reading rather than an invented value.
  @override
  Future<List<TelemetrySample>> samplesForSession(int sessionId) async {
    final List<TelemetrySampleRow> rows =
        await (database.select(database.telemetrySamples)
              ..where((TelemetrySamples t) => t.sessionId.equals(sessionId))
              ..orderBy(<OrderingTerm Function(TelemetrySamples)>[
                (TelemetrySamples t) => OrderingTerm.asc(t.observedAt),
                (TelemetrySamples t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    return rows.map(sampleFromRow).toList(growable: false);
  }

  /// Removes all local session history and returns the number of sessions
  /// deleted. Samples are deleted in the same transaction.
  @override
  Future<int> deleteAllSessions() {
    return database.transaction(() async {
      final int count = await database.chargingSessions.count().getSingle();

      await database.delete(database.telemetrySamples).go();
      await database.delete(database.chargingSessions).go();
      return count;
    });
  }

  /// Applies age and count bounds to ended sessions. Active sessions are kept.
  @override
  Future<void> enforceRetention({DateTime? now}) {
    return database.transaction(
      () => _enforceRetention((now ?? _clock()).toUtc()),
    );
  }

  Future<void> _persistUpdate(
    int sessionId,
    ChargingSession session,
    TelemetrySample sample,
  ) async {
    if (session.id != null && session.id != sessionId) {
      throw ArgumentError.value(
        session,
        'session',
        'Session id ${session.id} does not match $sessionId.',
      );
    }

    await database.transaction(() async {
      final DateTime now = _clock().toUtc();
      final int updated =
          await (database.update(database.chargingSessions)
                ..where((ChargingSessions t) => t.id.equals(sessionId)))
              .write(_updateCompanion(session, now));
      if (updated != 1) {
        throw StateError('Session $sessionId was not found.');
      }

      await _insertSample(sessionId, sample);
      await _applySampleCap(sessionId, retention.maxSamplesPerSession);
      await _enforceRetention(now);
    });
  }

  ChargingSessionsCompanion _insertCompanion(
    ChargingSession session,
    DateTime now,
  ) {
    return ChargingSessionsCompanion.insert(
      startedAt: session.startedAt.toUtc(),
      endedAt: Value(session.endedAt?.toUtc()),
      lastObservedAt: Value(session.lastObservedAt?.toUtc()),
      startLevelPercent: Value(session.startLevelPercent),
      endLevelPercent: Value(session.endLevelPercent),
      sessionState: session.state,
      sampleCount: Value(session.sampleCount),
      maxSamplingGapMs: Value(session.maxSamplingGap?.inMilliseconds),
      hasSamplingGaps: Value(session.hasSamplingGaps),
      samplesPruned: Value(session.samplesPruned),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  ChargingSessionsCompanion _updateCompanion(
    ChargingSession session,
    DateTime now,
  ) {
    return ChargingSessionsCompanion(
      endedAt: Value(session.endedAt?.toUtc()),
      lastObservedAt: Value(session.lastObservedAt?.toUtc()),
      startLevelPercent: Value(session.startLevelPercent),
      endLevelPercent: Value(session.endLevelPercent),
      sessionState: Value(session.state),
      sampleCount: Value(session.sampleCount),
      maxSamplingGapMs: Value(session.maxSamplingGap?.inMilliseconds),
      hasSamplingGaps: Value(session.hasSamplingGaps),
      samplesPruned: session.samplesPruned
          ? const Value(true)
          : const Value.absent(),
      updatedAt: Value(now),
    );
  }

  Future<void> _insertSample(int sessionId, TelemetrySample sample) async {
    final TelemetrySnapshot snapshot = sample.snapshot;
    final TelemetryReading<double> power = calculateBatteryPower(snapshot);

    await database
        .into(database.telemetrySamples)
        .insert(
          TelemetrySamplesCompanion.insert(
            sessionId: Value(sessionId),
            observedAt: sample.observedAt.toUtc(),
            batteryLevelPercent: Value(_availableValue(snapshot.batteryLevel)),
            chargingState: Value(_availableValue(snapshot.chargingState)),
            plugSource: Value(_availableValue(snapshot.plugSource)),
            voltageVolts: Value(_availableValue(snapshot.voltage)),
            currentAmps: Value(_availableValue(snapshot.currentNow)),
            currentAverageAmps: Value(_availableValue(snapshot.currentAverage)),
            temperatureCelsius: Value(_availableValue(snapshot.temperature)),
            chargeCounterMah: Value(_availableValue(snapshot.chargeCounter)),
            powerWatts: Value(power.isAvailable ? power.value : null),
            snapshotSchemaVersion: Value(snapshot.schemaVersion),
            availabilityMetadata: jsonEncode(
              encodeAvailabilityMetadata(snapshot),
            ),
            sourceMetadata: Value(jsonEncode(encodeSourceMetadata(snapshot))),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  T? _availableValue<T extends Object>(TelemetryReading<T> reading) =>
      reading.isAvailable ? reading.value : null;

  Future<bool> _applySampleCap(int sessionId, int maxSamples) async {
    final int count = await database.telemetrySamples
        .count(where: (TelemetrySamples t) => t.sessionId.equals(sessionId))
        .getSingle();
    if (count <= maxSamples) return false;

    final int excess = count - maxSamples;
    final Expression<int> idExpression = database.telemetrySamples.id;
    final List<int> oldestIds =
        await (database.selectOnly(database.telemetrySamples)
              ..addColumns(<Expression<Object>>[idExpression])
              ..where(database.telemetrySamples.sessionId.equals(sessionId))
              ..orderBy(<OrderingTerm>[
                OrderingTerm.asc(database.telemetrySamples.observedAt),
                OrderingTerm.asc(database.telemetrySamples.id),
              ])
              ..limit(excess))
            .map((TypedResult row) => row.read(idExpression)!)
            .get();

    if (oldestIds.isEmpty) return false;
    await (database.delete(
      database.telemetrySamples,
    )..where((TelemetrySamples t) => t.id.isIn(oldestIds))).go();
    await (database.update(database.chargingSessions)
          ..where((ChargingSessions t) => t.id.equals(sessionId)))
        .write(const ChargingSessionsCompanion(samplesPruned: Value(true)));
    return true;
  }

  Future<void> _enforceRetention(DateTime nowUtc) async {
    final DateTime cutoff = nowUtc.subtract(retention.maxAge);
    final Expression<bool> ended =
        database.chargingSessions.sessionState.equalsValue(
          ChargingSessionState.completed,
        ) |
        database.chargingSessions.sessionState.equalsValue(
          ChargingSessionState.interrupted,
        );

    await (database.delete(database.chargingSessions)..where(
          (ChargingSessions t) => ended & t.endedAt.isSmallerThanValue(cutoff),
        ))
        .go();

    final int endedCount = await database.chargingSessions
        .count(where: (ChargingSessions t) => ended)
        .getSingle();
    if (endedCount <= retention.maxEndedSessions) return;

    final int excess = endedCount - retention.maxEndedSessions;
    final Expression<int> idExpression = database.chargingSessions.id;
    final List<int> oldestIds =
        await (database.selectOnly(database.chargingSessions)
              ..addColumns(<Expression<Object>>[idExpression])
              ..where(ended)
              ..orderBy(<OrderingTerm>[
                OrderingTerm.asc(database.chargingSessions.startedAt),
                OrderingTerm.asc(database.chargingSessions.id),
              ])
              ..limit(excess))
            .map((TypedResult row) => row.read(idExpression)!)
            .get();

    if (oldestIds.isEmpty) return;
    await (database.delete(
      database.chargingSessions,
    )..where((ChargingSessions t) => t.id.isIn(oldestIds))).go();
  }

  ChargingSession _toDomain(ChargingSessionRow row) {
    final int? gapMs = row.maxSamplingGapMs;
    return ChargingSession(
      id: row.id,
      startedAt: row.startedAt.toUtc(),
      endedAt: row.endedAt?.toUtc(),
      lastObservedAt: row.lastObservedAt?.toUtc(),
      startLevelPercent: row.startLevelPercent,
      endLevelPercent: row.endLevelPercent,
      state: row.sessionState,
      sampleCount: row.sampleCount,
      maxSamplingGap: gapMs == null ? null : Duration(milliseconds: gapMs),
      hasSamplingGaps: row.hasSamplingGaps,
      samplesPruned: row.samplesPruned,
    );
  }
}
