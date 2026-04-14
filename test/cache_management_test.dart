import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('RemoteCaching Cache Management Tests', () {
    setUpAll(() async {
      // Initialize SQLite for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Clean up before each test
      await RemoteCaching.instance.init(
        databasePath: getInMemoryDatabasePath(),
      );
    });

    tearDown(() async {
      // Clean up after each test
      await RemoteCaching.instance.clearCache();
      await RemoteCaching.instance.dispose();
    });

    test('should clear specific cache key', () async {
      final testData1 = {'name': 'John'};
      final testData2 = {'name': 'Jane'};
      // Cache two different keys
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key1',
        remote: () async => testData1,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key2',
        remote: () async => testData2,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      // Clear only key1
      await RemoteCaching.instance.clearCacheForKey('key1');
      // key1 should call remote function again
      final newData1 = {'name': 'New John'};
      final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key1',
        remote: () async => newData1,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result1, equals(newData1));
      // key2 should still return cached data
      final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key2',
        remote: () async => {'different': 'data'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(Map<String, dynamic>.from(result2), equals(testData2));
    });

    test('should clear all cache', () async {
      final testData1 = {'name': 'John'};
      final testData2 = {'name': 'Jane'};
      // Cache two different keys
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key1',
        remote: () async => testData1,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key2',
        remote: () async => testData2,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      // Clear all cache
      await RemoteCaching.instance.clearCache();
      // Both keys should call remote function again
      final newData1 = {'name': 'New John'};
      final newData2 = {'name': 'New Jane'};
      final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key1',
        remote: () async => newData1,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key2',
        remote: () async => newData2,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result1, equals(newData1));
      expect(result2, equals(newData2));
    });

    test('should get cache statistics', () async {
      // Add some data to cache
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key1',
        remote: () async => {'data': 'value1'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'key2',
        remote: () async => {'data': 'value2'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.totalEntries, equals(2));
      expect(stats.totalSizeBytes, greaterThan(0));
      expect(stats.expiredEntries, equals(0));
    });

    test('should not crash when clearing non-existent key', () async {
      await RemoteCaching.instance.clearCacheForKey('non_existent_key');
      // Should not throw or crash
      expect(true, isTrue);
    });

    test('clear all and get stats', () async {
      await RemoteCaching.instance.call<String>(
        'test_key1',
        remote: () async => 'test',
        fromJson: (json) => json! as String,
      );
      await RemoteCaching.instance.call<String>(
        'test_key2',
        remote: () async => 'test',
        fromJson: (json) => json! as String,
      );
      await RemoteCaching.instance.clearCache();
      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.totalEntries, equals(0));
      expect(stats.totalSizeBytes, equals(0));
      expect(stats.expiredEntries, equals(0));
    });

    test('should clear cache entries by prefix', () async {
      // Cache entries with different prefixes
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'user_123',
        remote: () async => {'id': 123, 'name': 'John'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'user_456',
        remote: () async => {'id': 456, 'name': 'Jane'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'product_001',
        remote: () async => {'id': '001', 'name': 'Widget'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      // Clear only user_ prefixed entries
      final deleted = await RemoteCaching.instance.clearCacheByPrefix('user_');

      expect(deleted, equals(2));

      // Verify user entries are cleared (will call remote again)
      final newUserData = {'id': 999, 'name': 'New User'};
      final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'user_123',
        remote: () async => newUserData,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result1, equals(newUserData));

      // Verify product entry is still cached
      final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'product_001',
        remote: () async => {'different': 'data'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result2['name'], equals('Widget'));
    });

    test('should return 0 when clearing non-existent prefix', () async {
      await RemoteCaching.instance.call<String>(
        'key1',
        remote: () async => 'value',
        fromJson: (json) => json! as String,
      );

      final deleted =
          await RemoteCaching.instance.clearCacheByPrefix('nonexistent_');

      expect(deleted, equals(0));

      // Verify original entry still exists
      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.totalEntries, equals(1));
    });

    test('isCached should return true for a valid cached key', () async {
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'user_123',
        remote: () async => {'name': 'John'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      final result = await RemoteCaching.instance.isCached('user_123');
      expect(result, isTrue);
    });

    test('isCached should return false for a non-existent key', () async {
      final result = await RemoteCaching.instance.isCached('non_existent_key');
      expect(result, isFalse);
    });

    test('isCached should return false for an expired key', () async {
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'expired_key',
        cacheExpiring: DateTime.now().subtract(const Duration(seconds: 1)),
        remote: () async => {'name': 'John'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      final result = await RemoteCaching.instance.isCached('expired_key');
      expect(result, isFalse);
    });

    test('isCached should return false after clearing the key', () async {
      await RemoteCaching.instance.call<String>(
        'to_clear',
        remote: () async => 'value',
        fromJson: (json) => json! as String,
      );

      expect(await RemoteCaching.instance.isCached('to_clear'), isTrue);

      await RemoteCaching.instance.clearCacheForKey('to_clear');

      expect(await RemoteCaching.instance.isCached('to_clear'), isFalse);
    });

    test('isCached should return false after clearCache', () async {
      await RemoteCaching.instance.call<String>(
        'key_a',
        remote: () async => 'value_a',
        fromJson: (json) => json! as String,
      );
      await RemoteCaching.instance.call<String>(
        'key_b',
        remote: () async => 'value_b',
        fromJson: (json) => json! as String,
      );

      expect(await RemoteCaching.instance.isCached('key_a'), isTrue);
      expect(await RemoteCaching.instance.isCached('key_b'), isTrue);

      await RemoteCaching.instance.clearCache();

      expect(await RemoteCaching.instance.isCached('key_a'), isFalse);
      expect(await RemoteCaching.instance.isCached('key_b'), isFalse);
    });

    test('isCached should return false after clearCacheByPrefix', () async {
      await RemoteCaching.instance.call<String>(
        'user_1',
        remote: () async => 'alice',
        fromJson: (json) => json! as String,
      );
      await RemoteCaching.instance.call<String>(
        'product_1',
        remote: () async => 'widget',
        fromJson: (json) => json! as String,
      );

      await RemoteCaching.instance.clearCacheByPrefix('user_');

      expect(await RemoteCaching.instance.isCached('user_1'), isFalse);
      expect(await RemoteCaching.instance.isCached('product_1'), isTrue);
    });

    test('isCached should return false when not initialized', () async {
      await RemoteCaching.instance.dispose();

      final result = await RemoteCaching.instance.isCached('any_key');
      expect(result, isFalse);

      // Re-initialize for tearDown
      await RemoteCaching.instance.init(
        databasePath: getInMemoryDatabasePath(),
      );
    });

    test('should clear all entries when prefix matches all keys', () async {
      const length = 100;
      for (var i = 0; i < length; i++) {
        await RemoteCaching.instance.call<String>(
          'cache_item$i',
          remote: () async => 'value$i',
          fromJson: (json) => json! as String,
        );
      }

      final deleted =
          await RemoteCaching.instance.clearCacheByPrefix('cache_');

      expect(deleted, equals(length));

      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.totalEntries, equals(0));
    });
  });
}
