import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:voltly/core/persistence/tables.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// Voltly's local SQLite database.
///
/// Schema v1 contains charging-session summaries and their telemetry samples.
/// No network access or cloud sync is involved.
@DriftDatabase(tables: <Type>[ChargingSessions, TelemetrySamples])
class VoltlyDatabase extends _$VoltlyDatabase {
  VoltlyDatabase(super.executor);

  static const int currentSchemaVersion = 1;
  static const String defaultFileName = 'voltly.sqlite';

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from > to) {
        throw UnsupportedError(
          'Database schema version $from is newer than the supported version '
          '$to. Voltly will not mutate newer data.',
        );
      }
      if (from < 1) {
        await m.createAll();
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Opens the on-device database lazily in the application support directory.
///
/// The file is created only when the first query runs. Callers own the returned
/// database and must close it when the app no longer needs it.
VoltlyDatabase openVoltlyDatabase({
  String fileName = VoltlyDatabase.defaultFileName,
}) {
  return VoltlyDatabase(
    LazyDatabase(() async {
      final Directory directory = await getApplicationSupportDirectory();
      final File file = File(p.join(directory.path, fileName));
      return NativeDatabase.createInBackground(file);
    }),
  );
}
