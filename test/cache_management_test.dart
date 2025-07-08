import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:remote_caching/src/common/get_in_memory_database.dart';
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
  });
}
