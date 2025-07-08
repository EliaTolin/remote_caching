/// Statistics about the current state of the cache.
///
/// This class provides information about the cache's current state,
/// including the number of entries, total size, and expired entries.
/// Useful for monitoring cache performance and debugging.
///
/// ## Example
/// ```dart
/// final stats = await RemoteCaching.instance.getCacheStats();
/// print('Cache has ${stats.totalEntries} entries');
/// print('Total size: ${stats.totalSizeBytes} bytes');
/// print('Expired entries: ${stats.expiredEntries}');
/// ```
///
/// ## Fields
/// - [totalEntries] - Total number of cached entries (including expired ones)
/// - [totalSizeBytes] - Total size of all cached data in bytes
/// - [expiredEntries] - Number of entries that have expired but not yet cleaned up
class CachingStats {
  /// Creates a new [CachingStats] instance.
  ///
  /// ## Parameters
  /// - [totalEntries] - The total number of cache entries
  /// - [totalSizeBytes] - The total size of cached data in bytes
  /// - [expiredEntries] - The number of expired cache entries
  CachingStats({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.expiredEntries,
  });

  /// Total number of cached entries.
  ///
  /// This includes both valid and expired entries that haven't been
  /// cleaned up yet.
  final int totalEntries;

  /// Total size of all cached data in bytes.
  ///
  /// This represents the raw size of the JSON data stored in the cache,
  /// not including database overhead.
  final int totalSizeBytes;

  /// Number of expired cache entries.
  ///
  /// These are entries that have passed their expiration time but
  /// haven't been automatically cleaned up yet. They will be removed
  /// during the next cleanup operation.
  final int expiredEntries;

  /// Returns a string representation of the cache statistics.
  ///
  /// Useful for debugging and logging purposes.
  @override
  String toString() {
    return 'CachingStats(totalEntries: $totalEntries, totalSizeBytes: $totalSizeBytes, expiredEntries: $expiredEntries)';
  }
}
