import 'package:sqflite_common/sqlite_api.dart';

/// Name of the database file created by RemoteCaching.
const String remoteCachingDatabaseName = 'remote_caching.db';

/// Returns the default database factory for the current platform.
DatabaseFactory defaultDatabaseFactory() =>
    throw UnsupportedError('RemoteCaching is not supported on this platform.');

/// Resolves the path of the RemoteCaching database.
Future<String> resolveDatabasePath(
  DatabaseFactory factory,
  String? databasePath,
) => throw UnsupportedError('RemoteCaching is not supported on this platform.');
