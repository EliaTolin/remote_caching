/// A Flutter package for caching remote API calls with configurable duration.
///
/// This library provides a simple yet powerful way to cache remote API responses
/// locally using SQLite, with support for automatic expiration, custom serialization,
/// and intelligent cache management.
///
/// ## Quick Start
/// ```dart
/// import 'package:remote_caching/remote_caching.dart';
///
/// // Initialize the cache system
/// await RemoteCaching.instance.init();
///
/// // Cache a remote API call
/// final data = await RemoteCaching.instance.call<MyData>(
///   'cache_key',
///   remote: () async => await fetchData(),
///   fromJson: (json) => MyData.fromJson(json as Map<String, dynamic>),
/// );
/// ```
///
/// ## Exported Classes and Functions
/// - [RemoteCaching] - The main class for managing remote caching operations
/// - [CachingStats] - Statistics about the current cache state
/// - [getInMemoryDatabasePath] - Utility for creating in-memory databases (testing)
///
/// For detailed documentation and examples, see the individual class documentation.
library remote_caching;

import 'package:remote_caching/remote_caching.dart';

export 'src/common/get_in_memory_database.dart' show getInMemoryDatabasePath;
export 'src/models/caching_stats.dart' show CachingStats;
export 'src/remote_caching_impl.dart' show RemoteCaching;
