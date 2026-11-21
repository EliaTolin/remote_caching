import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Name of the database file created by RemoteCaching.
const String remoteCachingDatabaseName = 'remote_caching.db';

/// Returns the default database factory for native platforms (SQLite via FFI).
///
/// The SQLite library is bundled by `package:sqlite3` build hooks.
DatabaseFactory defaultDatabaseFactory() {
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

/// Resolves the path of the RemoteCaching database.
///
/// [databasePath] is a directory: the database file is created inside it,
/// creating the directory if needed. `null` uses the factory default
/// databases directory. [inMemoryDatabasePath] is returned unchanged.
Future<String> resolveDatabasePath(
  DatabaseFactory factory,
  String? databasePath,
) async {
  final dir = databasePath ?? await factory.getDatabasesPath();
  if (dir == inMemoryDatabasePath) return inMemoryDatabasePath;

  final directory = Directory(dir);
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }
  return p.join(dir, remoteCachingDatabaseName);
}
