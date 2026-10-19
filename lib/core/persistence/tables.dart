import 'package:drift/drift.dart';

import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Persisted charging-session summary.
///
/// Rows are ordered by [startedAt]; the state/start index supports finding the
/// active session and recent history without scanning the table.
@TableIndex(name: 'idx_charging_sessions_started_at', columns: {#startedAt})
@TableIndex(
  name: 'idx_charging_sessions_state_started_at',
  columns: {#sessionState, #startedAt},
)
@DataClassName('ChargingSessionRow')
class ChargingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get lastObservedAt => dateTime().nullable()();
  RealColumn get startLevelPercent => real().nullable()();
  RealColumn get endLevelPercent => real().nullable()();
  TextColumn get sessionState => textEnum<ChargingSessionState>()();
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();
  IntColumn get maxSamplingGapMs => integer().nullable()();
  BoolColumn get hasSamplingGaps =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get samplesPruned =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => <String>[
    'CHECK (sample_count >= 0)',
    'CHECK (start_level_percent IS NULL OR '
        '(start_level_percent >= 0 AND start_level_percent <= 100))',
    'CHECK (end_level_percent IS NULL OR '
        '(end_level_percent >= 0 AND end_level_percent <= 100))',
    'CHECK (max_sampling_gap_ms IS NULL OR max_sampling_gap_ms >= 0)',
  ];
}

/// Persisted telemetry observation. Values are nullable when the device did not
/// provide a usable reading; [availabilityMetadata] records why.
@TableIndex(
  name: 'idx_telemetry_samples_session_observed_at',
  columns: {#sessionId, #observedAt},
  unique: true,
)
@TableIndex(name: 'idx_telemetry_samples_observed_at', columns: {#observedAt})
@DataClassName('TelemetrySampleRow')
class TelemetrySamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().nullable().references(
    ChargingSessions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get observedAt => dateTime()();
  RealColumn get batteryLevelPercent => real().nullable()();
  TextColumn get chargingState => textEnum<BatteryChargingState>().nullable()();
  TextColumn get plugSource => textEnum<BatteryPlugSource>().nullable()();
  RealColumn get voltageVolts => real().nullable()();
  RealColumn get currentAmps => real().nullable()();
  RealColumn get currentAverageAmps => real().nullable()();
  RealColumn get temperatureCelsius => real().nullable()();
  RealColumn get chargeCounterMah => real().nullable()();
  RealColumn get powerWatts => real().nullable()();
  IntColumn get snapshotSchemaVersion =>
      integer().withDefault(const Constant(1))();

  /// JSON map of per-metric availability, provenance, observation time, unit
  /// and reason. Scalar values remain in their own columns for querying.
  TextColumn get availabilityMetadata => text()();
  TextColumn get sourceMetadata => text().nullable()();
}
