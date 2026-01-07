/// Defines the caching strategy for remote API calls.
///
/// This enum allows developers to control the behavior of how data is
/// retrieved from cache vs remote source.
///
/// ## Strategies
/// - [cacheFirst] - Uses cached data if available and valid, otherwise fetches from network.
///   This is the default strategy and provides the fastest response time for cached data.
/// - [networkFirst] - Always tries network first, falls back to cache if network fails.
///   Use this when fresh data is preferred but offline support is still needed.
///
/// ## Example
/// ```dart
/// // Use cache-first strategy (default)
/// final user = await RemoteCaching.instance.call<User>(
///   'user_profile',
///   strategy: CacheStrategy.cacheFirst,
///   remote: () async => await fetchUserProfile(),
///   fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
/// );
///
/// // Use network-first strategy for fresh data
/// final news = await RemoteCaching.instance.call<News>(
///   'latest_news',
///   strategy: CacheStrategy.networkFirst,
///   remote: () async => await fetchLatestNews(),
///   fromJson: (json) => News.fromJson(json as Map<String, dynamic>),
/// );
/// ```
enum CacheStrategy {
  /// Uses cached data if available and valid, otherwise fetches from network.
  ///
  /// This is the default strategy. It provides:
  /// - Fastest response time when cache is valid
  /// - Reduced network usage
  /// - Works well for data that doesn't change frequently
  ///
  /// Flow:
  /// 1. Check if valid cache exists
  /// 2. If yes, return cached data immediately
  /// 3. If no, fetch from network and cache the result
  cacheFirst,

  /// Always tries network first, falls back to cache if network fails.
  ///
  /// Use this strategy when:
  /// - Fresh data is preferred
  /// - The app should work offline when network fails
  /// - Data changes frequently and users expect the latest version
  ///
  /// Flow:
  /// 1. Try to fetch from network
  /// 2. If successful, cache and return the data
  /// 3. If network fails, return cached data (even if expired)
  /// 4. If no cache exists, rethrow the network error
  networkFirst,
}
