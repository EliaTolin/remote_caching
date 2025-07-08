import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('RemoteCaching Duration and Expiration Tests', () {
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
    test('should respect cache duration', () async {
      final testData = {'name': 'John'};
      // First call
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData,
        cacheDuration: const Duration(milliseconds: 100),
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      // Wait for cache to expire
      await Future.delayed(const Duration(milliseconds: 400));
      // This should call remote function again
      final newData = {'name': 'Jane'};
      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => newData,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result, equals(newData));
    });

    test('should not call remote before cache duration', () async {
      final testData = {'name': 'John'};

      // First call to cache data
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData,
        cacheDuration: const Duration(milliseconds: 100),
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      // Second call without waiting for expiration
      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async {
          throw StateError('Remote should NOT be called before cache expires');
        },
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(result, equals(testData));
    });

    test('should respect cache expiration', () async {
      final testData = {'name': 'John'};
      // First call
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData,
        cacheExpiring: DateTime.now().add(const Duration(milliseconds: 100)),
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      // Wait for cache to expire
      await Future.delayed(const Duration(milliseconds: 400));
      // This should call remote function again
      final newData = {'name': 'Jane'};
      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => newData,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(result, equals(newData));
    });

    test('should not call remote before cache expiration', () async {
      final testData = {'name': 'John'};

      // First call to cache data
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData,
        cacheExpiring: DateTime.now().add(const Duration(milliseconds: 100)),
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      // Second call without waiting for expiration
      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async {
          throw StateError('Remote should NOT be called before cache expires');
        },
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(result, equals(testData));
    });

    test(
      'should throw AssertionError if both cacheDuration and cacheExpiring are provided',
      () async {
        final testData = {'name': 'Test'};

        expect(() async {
          await RemoteCaching.instance.call<Map<String, dynamic>>(
            'test_key_assert',
            remote: () async => testData,
            cacheDuration: const Duration(seconds: 1),
            cacheExpiring: DateTime.now().add(const Duration(seconds: 1)),
            fromJson: (json) => Map<String, dynamic>.from(json! as Map),
          );
        }, throwsA(isA<AssertionError>()));
      },
    );

    test('should use custom cache duration', () async {
      final testData = {'name': 'John'};
      // Call with custom duration
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        cacheDuration: const Duration(milliseconds: 200),
        remote: () async => testData,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      // Wait less than custom duration
      await Future.delayed(const Duration(milliseconds: 100));
      // Should still return cached data
      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => {'different': 'data'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(Map<String, dynamic>.from(result), equals(testData));
    });

    test('should remove expired data automatically on access', () async {
      final testData = {'name': 'John'};
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData,
        cacheDuration: const Duration(milliseconds: 100),
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => {'name': 'Jane'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(result, equals({'name': 'Jane'}));

      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.expiredEntries, equals(0));
    });
  });
}
