import 'package:sqflite/sqflite.dart';

/// Returns the path for an in-memory database.
///
/// This function provides a special database path that creates an in-memory
/// SQLite database. In-memory databases are not persisted to disk and are
/// lost when the application terminates.
///
/// ## Use Cases
/// - **Testing**: Use in-memory databases for unit tests to avoid file system dependencies
/// - **Temporary caching**: When you need temporary cache that doesn't persist
/// - **Performance testing**: To isolate cache performance from disk I/O
///
/// ## Example
/// ```dart
/// await RemoteCaching.instance.init(
///   databasePath: getInMemoryDatabasePath(),
///   verboseMode: true,
/// );
/// ```
///
/// ## Warning
/// ⚠️ **Important**: In-memory databases are lost on app restart. Avoid storing
/// large datasets in memory, especially on mobile devices where RAM is limited.
///
/// ## Returns
/// A string representing the in-memory database path.
String getInMemoryDatabasePath() {
  return inMemoryDatabasePath;
}
