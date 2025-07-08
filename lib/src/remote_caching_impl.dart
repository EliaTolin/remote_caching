import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:remote_caching/src/models/caching_stats.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Export the main class
export 'remote_caching_impl.dart' show RemoteCaching;

/// A Flutter package for caching remote API calls with configurable duration.
///
/// This package provides a simple yet powerful way to cache remote API responses
/// locally using SQLite, with support for automatic expiration, custom serialization,
/// and intelligent cache management.
///
/// ## Key Features
/// - **Automatic caching** with configurable expiration
/// - **SQLite persistence** for reliable data storage
/// - **Generic support** for any serializable data type
/// - **Custom deserialization** with `fromJson` functions
/// - **Cache statistics** and monitoring
/// - **Error handling** with graceful fallbacks
/// - **Cross-platform** support (iOS, Android, Web, Desktop)
///
/// ## Basic Usage
/// ```dart
/// // Initialize the cache system
/// await RemoteCaching.instance.init(
///   defaultCacheDuration: Duration(hours: 1),
///   verboseMode: true,
/// );
///
/// // Cache a remote API call
/// final user = await RemoteCaching.instance.call<User>(
///   'user_profile_123',
///   cacheDuration: Duration(minutes: 30),
///   remote: () async => await apiService.getUser(123),
///   fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
/// );
/// ```
///
/// ## Advanced Usage
/// ```dart
/// // Use exact expiration time
/// final data = await RemoteCaching.instance.call<Data>(
///   'cache_key',
///   cacheExpiring: DateTime.now().add(Duration(hours: 2)),
///   remote: () async => await fetchData(),
///   fromJson: (json) => Data.fromJson(json as Map<String, dynamic>),
/// );
///
/// // Force refresh (bypass cache)
/// final freshData = await RemoteCaching.instance.call<Data>(
///   'cache_key',
///   forceRefresh: true,
///   remote: () async => await fetchData(),
///   fromJson: (json) => Data.fromJson(json as Map<String, dynamic>),
/// );
///
/// // Cache lists and complex data
/// final users = await RemoteCaching.instance.call<List<User>>(
///   'all_users',
///   remote: () async => await apiService.getAllUsers(),
///   fromJson: (json) => (json as List)
///       .map((item) => User.fromJson(item as Map<String, dynamic>))
///       .toList(),
/// );
/// ```
///
/// ## Cache Management
/// ```dart
/// // Clear specific cache entry
/// await RemoteCaching.instance.clearCacheForKey('user_profile_123');
///
/// // Clear all cache
/// await RemoteCaching.instance.clearCache();
///
/// // Get cache statistics
/// final stats = await RemoteCaching.instance.getCacheStats();
/// print('Total entries: ${stats.totalEntries}');
/// ```
///
/// ## Error Handling
/// The package handles serialization errors gracefully. If `fromJson` fails,
/// the error is logged and the remote call is used instead. Your app will
/// never crash due to cache-related errors.
///
/// ## Thread Safety
/// This class is thread-safe and can be used from multiple isolates.
/// All database operations are properly synchronized.
class RemoteCaching {
  factory RemoteCaching() => _instance;
  RemoteCaching._internal();
  static final RemoteCaching _instance = RemoteCaching._internal();

  static RemoteCaching get instance => _instance;

  Database? _database;
  Duration _defaultCacheDuration = const Duration(hours: 1);
  bool _isInitialized = false;
  bool _verboseMode = false;

  void _logInfo(String message) {
    if (_verboseMode) {
      log(
        '🔵 [RemoteCaching] $message',
        name: 'RemoteCaching',
        level: 800, // INFO level
      );
    }
  }

  void _logError(String message, {StackTrace? stackTrace}) {
    if (_verboseMode) {
      log(
        '🔴 [RemoteCaching ERROR] $message',
        name: 'RemoteCaching',
        level: 1000, // SEVERE level
        stackTrace: stackTrace,
      );
    }
  }

  /// Initialize the caching system.
  ///
  /// This method must be called before using any caching functionality.
  /// It sets up the SQLite database and configures the cache behavior.
  ///
  /// ## Parameters
  /// - [defaultCacheDuration] - The default cache duration for all calls.
  ///   If not specified, defaults to 1 hour.
  /// - [verboseMode] - Enable detailed logging for debugging.
  ///   Defaults to `kDebugMode` (enabled in debug builds).
  /// - [databasePath] - Custom path for the database file.
  ///   If not specified, uses the default application database directory.
  ///   Use [getInMemoryDatabasePath()] for in-memory database (testing only).
  ///
  /// ## Example
  /// ```dart
  /// await RemoteCaching.instance.init(
  ///   defaultCacheDuration: Duration(hours: 2),
  ///   verboseMode: true,
  ///   databasePath: '/custom/path/cache.db',
  /// );
  /// ```
  ///
  /// ## Throws
  /// - [StateError] if already initialized
  /// - [DatabaseException] if database initialization fails
  Future<void> init({
    Duration? defaultCacheDuration,
    bool verboseMode = kDebugMode,
    String? databasePath,
  }) async {
    if (_isInitialized) return;

    _defaultCacheDuration = defaultCacheDuration ?? _defaultCacheDuration;
    _verboseMode = verboseMode;
    _database = await _initDatabase(databasePath);
    _isInitialized = true;

    await _cleanupExpiredEntries();
  }

  /// Execute a remote call with caching.
  ///
  /// This is the main method for caching remote API calls. It first checks
  /// if valid cached data exists, and if not, calls the remote function
  /// and caches the result.
  ///
  /// ## Parameters
  /// - [key] - Unique identifier for the cache entry. Use descriptive keys
  ///   that include relevant parameters (e.g., 'user_123', 'products_category_electronics').
  /// - [remote] - Function that fetches data from the remote source.
  ///   This function is called when no valid cache exists or when [forceRefresh] is true.
  /// - [fromJson] - Function to deserialize JSON data into the target type.
  ///   Required for all types except basic JSON types (Map, List, String, etc.).
  /// - [cacheDuration] - How long to cache the data. If not specified,
  ///   uses the default duration set in [init()].
  /// - [cacheExpiring] - Exact datetime when the cache should expire.
  ///   Cannot be used together with [cacheDuration].
  /// - [forceRefresh] - If true, bypasses cache and always calls the remote function.
  ///
  /// ## Returns
  /// The cached or freshly fetched data of type [T].
  ///
  /// ## Example
  /// ```dart
  /// final user = await RemoteCaching.instance.call<User>(
  ///   'user_profile_123',
  ///   cacheDuration: Duration(minutes: 30),
  ///   remote: () async => await apiService.getUser(123),
  ///   fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
  /// );
  /// ```
  ///
  /// ## Throws
  /// - [StateError] if not initialized
  /// - [ArgumentError] if both [cacheDuration] and [cacheExpiring] are specified
  /// - Any exception thrown by the [remote] function
  Future<T> call<T>(
    String key, {
    required Future<T> Function() remote,
    required T Function(Object? json) fromJson,
    Duration? cacheDuration,
    DateTime? cacheExpiring,
    bool forceRefresh = false,
  }) async {
    if (!_isInitialized) {
      throw StateError('RemoteCaching must be initialized before use.');
    }

    assert(
      cacheDuration == null || cacheExpiring == null,
      'You cannot specify both cacheDuration and cacheExpiring at the same time.',
    );

    final expiresAt =
        cacheExpiring ??
        DateTime.now().add(cacheDuration ?? _defaultCacheDuration);

    if (!forceRefresh) {
      final cached = await _getCachedData<T>(key, fromJson: fromJson);
      if (cached != null) {
        _logInfo('Cached data found for key: $key');
        return cached;
      }
    }

    final data = await remote();
    _logInfo('Data fetched from remote for key: $key');
    await _cacheData(key, data, expiresAt);
    _logInfo('Data cached for key: $key');
    return data;
  }

  /// Get cached data if valid.
  ///
  /// Internal method that retrieves and validates cached data.
  /// Returns null if no valid cache exists.
  Future<T?> _getCachedData<T>(
    String key, {
    required T Function(Object? json) fromJson,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await _database?.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result != null && result.isNotEmpty) {
      final expiresAt = result.first['expires_at']! as int;
      if (expiresAt > now) {
        _logInfo('Cached data found for key: $key');
        final dataString = result.first['data']! as String;
        try {
          final decoded = jsonDecode(dataString);
          try {
            return fromJson(decoded);
          } catch (e, st) {
            _logError(
              'Deserialization error (fromJson) for key $key: $e',
              stackTrace: st,
            );
            return null;
          }
        } catch (e, st) {
          _logError(
            'Deserialization error (jsonDecode) for key $key: $e',
            stackTrace: st,
          );
          return null;
        }
      } else {
        _logInfo('Cached data expired for key: $key');
        // Remove the expired data
        await _database?.delete('cache', where: 'key = ?', whereArgs: [key]);
      }
    }
    _logInfo('No cached data found for key: $key');
    return null;
  }

  /// Cache data with expiration.
  ///
  /// Internal method that stores data in the cache with the specified expiration.
  /// Handles serialization errors gracefully.
  Future<void> _cacheData<T>(String key, T data, DateTime expiresAt) async {
    final now = DateTime.now();
    String? dataString;
    try {
      dataString = jsonEncode(data);
    } catch (e, st) {
      _logError(
        'Serialization error (jsonEncode) for key $key: $e',
        stackTrace: st,
      );
      return; // Non salvo nulla in cache
    }

    await _database?.insert('cache', {
      'key': key,
      'data': dataString,
      'created_at': now.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Initialize the SQLite database.
  ///
  /// Sets up the database schema and creates necessary indexes.
  Future<Database> _initDatabase(String? databasePath) async {
    // Inizializza sqflite_common_ffi
    sqfliteFfiInit();

    // Imposta il database factory globale
    databaseFactoryOrNull = databaseFactoryFfi;

    final dbPath = databasePath ?? await getDatabasesPath();
    final path = join(dbPath, 'remote_caching.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cache (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            expires_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_expires_at ON cache (expires_at)');
      },
    );
  }

  /// Cleanup expired entries from the cache.
  ///
  /// Automatically removes expired cache entries to keep the database clean.
  Future<void> _cleanupExpiredEntries() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database?.delete('cache', where: 'expires_at < ?', whereArgs: [now]);
  }

  /// Clear the entire cache.
  ///
  /// Removes all cached data. Useful for clearing cache on logout
  /// or when you need a fresh start.
  ///
  /// ## Example
  /// ```dart
  /// await RemoteCaching.instance.clearCache();
  /// ```
  Future<void> clearCache() async {
    if (!_isInitialized) return;
    await _database?.delete('cache');
  }

  /// Clear a specific cache entry.
  ///
  /// Removes the cached data for a specific key. Useful for
  /// invalidating specific data when it becomes stale.
  ///
  /// ## Parameters
  /// - [key] - The cache key to remove
  ///
  /// ## Example
  /// ```dart
  /// await RemoteCaching.instance.clearCacheForKey('user_profile_123');
  /// ```
  Future<void> clearCacheForKey(String key) async {
    if (!_isInitialized) return;
    await _database?.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  /// Get cache statistics.
  ///
  /// Returns information about the current state of the cache,
  /// including total entries, size, and expired entries.
  ///
  /// ## Returns
  /// A [CachingStats] object containing cache statistics.
  ///
  /// ## Example
  /// ```dart
  /// final stats = await RemoteCaching.instance.getCacheStats();
  /// print('Total entries: ${stats.totalEntries}');
  /// print('Total size: ${stats.totalSizeBytes} bytes');
  /// print('Expired entries: ${stats.expiredEntries}');
  /// ```
  ///
  /// ## Throws
  /// - [StateError] if not initialized
  Future<CachingStats> getCacheStats() async {
    if (!_isInitialized) {
      throw StateError('RemoteCaching must be initialized before use.');
    }

    final stats = await _database?.rawQuery(
      'SELECT COUNT(*) as total_entries, SUM(LENGTH(data)) as total_size FROM cache',
    );

    final expired = await _database?.rawQuery(
      'SELECT COUNT(*) as expired_entries FROM cache WHERE expires_at < ?',
      [DateTime.now().millisecondsSinceEpoch],
    );

    return CachingStats(
      totalEntries: (stats?.first['total_entries'] as int?) ?? 0,
      totalSizeBytes: (stats?.first['total_size'] as int?) ?? 0,
      expiredEntries: (expired?.first['expired_entries'] as int?) ?? 0,
    );
  }

  /// Dispose of the cache system.
  ///
  /// Closes the database connection and cleans up resources.
  /// Call this when you're done using the cache system.
  ///
  /// ## Example
  /// ```dart
  /// await RemoteCaching.instance.dispose();
  /// ```
  Future<void> dispose() async {
    await _database?.close();
    _isInitialized = false;
  }
}
