import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/core/persistence/app_database.dart';
import 'package:voltly/core/persistence/session_repository.dart';
import 'package:voltly/core/persistence/session_store.dart';

/// The single app-scoped database. The file itself is opened lazily on the first
/// query, and the connection is closed when the provider scope is disposed.
final Provider<VoltlyDatabase> databaseProvider = Provider<VoltlyDatabase>((
  Ref ref,
) {
  final VoltlyDatabase database = openVoltlyDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

/// One repository shared by session tracking and history screens.
final Provider<SessionStore> sessionRepositoryProvider = Provider<SessionStore>(
  (Ref ref) => SessionRepository(ref.watch(databaseProvider)),
);
