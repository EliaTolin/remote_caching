/// Represents an error that occurred during cache operations.
///
/// This class provides detailed information about serialization or
/// deserialization errors that occur during caching, allowing developers
/// to handle them appropriately.
///
/// ## Example
/// ```dart
/// final user = await RemoteCaching.instance.call<User>(
///   'user_profile',
///   remote: () async => await fetchUser(),
///   fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
///   onError: (error) {
///     print('Cache error for ${error.key}: ${error.message}');
///     // Log to analytics, retry, etc.
///   },
/// );
/// ```
class CacheError {
  /// Creates a new [CacheError] instance.
  const CacheError({
    required this.key,
    required this.type,
    required this.error,
    required this.stackTrace,
    this.rawData,
  });

  /// The cache key associated with this error.
  final String key;

  /// The type of cache error that occurred.
  final CacheErrorType type;

  /// The underlying error/exception that was caught.
  final Object error;

  /// The stack trace when the error occurred.
  final StackTrace stackTrace;

  /// The raw data that failed to serialize/deserialize (if available).
  ///
  /// For serialization errors, this is the original object.
  /// For deserialization errors, this is the JSON string from cache.
  final Object? rawData;

  /// A human-readable message describing the error.
  String get message {
    switch (type) {
      case CacheErrorType.serialization:
        return 'Failed to serialize data for key "$key": $error';
      case CacheErrorType.deserializationJson:
        return 'Failed to decode JSON from cache for key "$key": $error';
      case CacheErrorType.deserializationFromJson:
        return 'Failed to convert JSON to object for key "$key": $error';
    }
  }

  @override
  String toString() => 'CacheError($message)';
}

/// The type of cache error that occurred.
enum CacheErrorType {
  /// Error during JSON encoding (jsonEncode failed).
  ///
  /// This occurs when the data returned from remote() cannot be
  /// converted to JSON for storage in the cache.
  serialization,

  /// Error during JSON decoding (jsonDecode failed).
  ///
  /// This occurs when the cached JSON string cannot be parsed.
  /// This might indicate corrupted cache data.
  deserializationJson,

  /// Error during fromJson conversion.
  ///
  /// This occurs when the JSON was decoded successfully but
  /// the fromJson function threw an error during conversion.
  deserializationFromJson,
}
