import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Name of the database file created by RemoteCaching.
const String remoteCachingDatabaseName = 'remote_caching.db';

/// Returns the default database factory for the web.
///
/// SQLite (WebAssembly) runs in a shared worker and the database is persisted
/// in IndexedDB. The app must serve `sqlite3.wasm` and `sqflite_sw.js` next to
/// its `index.html` (run `dart run sqflite_common_ffi_web:setup`).
DatabaseFactory defaultDatabaseFactory() => databaseFactoryFfiWeb;

/// Resolves the path of the RemoteCaching database.
///
/// There is no file system on the web: [databasePath] is a virtual folder
/// (a namespace inside IndexedDB). `null` stores the database at the root.
/// [inMemoryDatabasePath] is returned unchanged.
Future<String> resolveDatabasePath(
  DatabaseFactory factory,
  String? databasePath,
) async {
  if (databasePath == inMemoryDatabasePath) return inMemoryDatabasePath;
  if (databasePath == null || databasePath.isEmpty) {
    return remoteCachingDatabaseName;
  }
  return p.url.join(databasePath, remoteCachingDatabaseName);
}
