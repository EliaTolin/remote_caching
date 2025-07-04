import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models/test_models.dart';

void main() {
  group('RemoteCaching Tests', () {
    setUpAll(() async {
      // Initialize SQLite for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Clean up before each test
      await RemoteCaching.instance.dispose();
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.clearCache();
    });

    tearDown(() async {
      // Clean up after each test
      await RemoteCaching.instance.dispose();
    });

    test('should initialize with default cache duration', () async {
      await RemoteCaching.instance.init();
      expect(RemoteCaching.instance, isNotNull);
    });

    test('should initialize with custom cache duration', () async {
      const customDuration = Duration(minutes: 30);
      await RemoteCaching.instance.init(defaultCacheDuration: customDuration);
      expect(RemoteCaching.instance, isNotNull);
    });

    test('should cache and retrieve data', () async {
      await RemoteCaching.instance.init();
      final testData = {'name': 'John', 'age': 30};
      // First call should execute remote function
      final result1 = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => testData,
      );
      expect(result1, equals(testData));
      // Second call should return cached data
      final result2 = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => {'different': 'data'}, // This should not be called
      );
      expect(Map<String, dynamic>.from(result2), equals(testData));
    });

    test('should respect cache duration', () async {
      await RemoteCaching.instance.init();
      final testData = {'name': 'John'};
      // First call
      await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => testData,
        cacheDuration: const Duration(milliseconds: 100),
      );
      // Wait for cache to expire
      await Future.delayed(const Duration(milliseconds: 400));
      // This should call remote function again
      final newData = {'name': 'Jane'};
      final result = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => newData,
      );
      expect(result, equals(newData));
    });

    test('should force refresh when requested', () async {
      await RemoteCaching.instance.init();
      final testData1 = {'name': 'John'};
      final testData2 = {'name': 'Jane'};
      // First call
      await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => testData1,
      );
      // Force refresh
      final result = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => testData2,
        forceRefresh: true,
      );
      expect(result, equals(testData2));
    });

    test('should use custom cache duration', () async {
      await RemoteCaching.instance.init();
      final testData = {'name': 'John'};
      // Call with custom duration
      await RemoteCaching.instance.call<dynamic>(
        'test_key',
        cacheDuration: const Duration(milliseconds: 200),
        remote: () async => testData,
      );
      // Wait less than custom duration
      await Future.delayed(const Duration(milliseconds: 100));
      // Should still return cached data
      final result = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => {'different': 'data'},
      );
      expect(Map<String, dynamic>.from(result), equals(testData));
    });

    test('should clear specific cache key', () async {
      await RemoteCaching.instance.init();
      final testData1 = {'name': 'John'};
      final testData2 = {'name': 'Jane'};
      // Cache two different keys
      await RemoteCaching.instance.call<dynamic>(
        'key1',
        remote: () async => testData1,
      );
      await RemoteCaching.instance.call<dynamic>(
        'key2',
        remote: () async => testData2,
      );
      // Clear only key1
      await RemoteCaching.instance.clearCacheForKey('key1');
      // key1 should call remote function again
      final newData1 = {'name': 'New John'};
      final result1 = await RemoteCaching.instance.call<dynamic>(
        'key1',
        remote: () async => newData1,
      );
      expect(result1, equals(newData1));
      // key2 should still return cached data
      final result2 = await RemoteCaching.instance.call<dynamic>(
        'key2',
        remote: () async => {'different': 'data'},
      );
      expect(Map<String, dynamic>.from(result2), equals(testData2));
    });

    test('should clear all cache', () async {
      await RemoteCaching.instance.init();
      final testData1 = {'name': 'John'};
      final testData2 = {'name': 'Jane'};
      // Cache two different keys
      await RemoteCaching.instance.call<dynamic>(
        'key1',
        remote: () async => testData1,
      );
      await RemoteCaching.instance.call<dynamic>(
        'key2',
        remote: () async => testData2,
      );
      // Clear all cache
      await RemoteCaching.instance.clearCache();
      // Both keys should call remote function again
      final newData1 = {'name': 'New John'};
      final newData2 = {'name': 'New Jane'};
      final result1 = await RemoteCaching.instance.call<dynamic>(
        'key1',
        remote: () async => newData1,
      );
      final result2 = await RemoteCaching.instance.call<dynamic>(
        'key2',
        remote: () async => newData2,
      );
      expect(result1, equals(newData1));
      expect(result2, equals(newData2));
    });

    test('should handle different data types', () async {
      await RemoteCaching.instance.init();
      // Test with String
      final stringResult = await RemoteCaching.instance.call<dynamic>(
        'string_key',
        remote: () async => 'test string',
      );
      expect(stringResult, equals('test string'));
      // Test with int
      final intResult = await RemoteCaching.instance.call<dynamic>(
        'int_key',
        remote: () async => 42,
      );
      expect(intResult, equals(42));
      // Test with List
      final listResult = await RemoteCaching.instance.call<dynamic>(
        'list_key',
        remote: () async => [1, 2, 3],
      );
      expect(List<dynamic>.from(listResult), equals([1, 2, 3]));
      // Test with Map
      final mapResult = await RemoteCaching.instance.call<dynamic>(
        'map_key',
        remote: () async => {'key': 'value'},
      );
      expect(Map<String, dynamic>.from(mapResult), equals({'key': 'value'}));
    });

    test('should throw error if not initialized', () async {
      await RemoteCaching.instance.dispose();
      expect(
        () => RemoteCaching.instance.call<dynamic>(
          'test_key',
          remote: () async => 'data',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('should get cache statistics', () async {
      await RemoteCaching.instance.init();
      // Add some data to cache
      await RemoteCaching.instance.call<dynamic>(
        'key1',
        remote: () async => {'data': 'value1'},
      );
      await RemoteCaching.instance.call<dynamic>(
        'key2',
        remote: () async => {'data': 'value2'},
      );
      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.totalEntries, equals(2));
      expect(stats.totalSizeBytes, greaterThan(0));
      expect(stats.expiredEntries, equals(0));
    });

    test('should remove expired data automatically on access', () async {
      await RemoteCaching.instance.init();

      final testData = {'name': 'John'};
      await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => testData,
        cacheDuration: const Duration(milliseconds: 100),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final result = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => {'name': 'Jane'},
      );

      expect(result, equals({'name': 'Jane'}));

      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.expiredEntries, equals(0));
    });

    test('should remove expired data automatically on access', () async {
      await RemoteCaching.instance.init();

      final testData = {'name': 'John'};
      await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => testData,
        cacheDuration: const Duration(milliseconds: 100),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final result = await RemoteCaching.instance.call<dynamic>(
        'test_key',
        remote: () async => {'name': 'Jane'},
      );

      expect(result, equals({'name': 'Jane'}));

      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.expiredEntries, equals(0));
    });

    test('should deserialize primitive types without fromJson', () async {
      await RemoteCaching.instance.init();

      final result1 = await RemoteCaching.instance.call<String>(
        'primitive_key',
        remote: () async => 'hello world',
      );

      expect(result1, equals('hello world'));

      final result2 = await RemoteCaching.instance.call<int>(
        'int_key',
        remote: () async => 123,
      );

      expect(result2, equals(123));
    });
    test('should allow multiple init calls without crashing', () async {
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.init();

      expect(RemoteCaching.instance, isNotNull);
    });

    test('should not crash when clearing non-existent key', () async {
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.clearCacheForKey('non_existent_key');
      // Should not throw or crash
      expect(true, isTrue);
    });

    test('should cache and retrieve nested Map structures', () async {
      await RemoteCaching.instance.init();

      final complexData = {
        'user': {
          'name': 'Elia',
          'settings': {'theme': 'dark', 'language': 'it'},
        },
        'items': [1, 2, 3],
      };

      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'nested_key',
        remote: () async => complexData,
      );

      final result = await RemoteCaching.instance.call<dynamic>(
        'nested_key',
        remote: () async => {
          'user': {'name': 'Other'},
        }, // fallback, shouldn't be used
      );

      expect(Map<String, dynamic>.from(result), equals(complexData));
    });

    test('should overwrite cached data on second call', () async {
      await RemoteCaching.instance.init();

      await RemoteCaching.instance.call<dynamic>(
        'overwrite_key',
        remote: () async => {'value': 1},
      );

      await RemoteCaching.instance.call<dynamic>(
        'overwrite_key',
        remote: () async => {'value': 2},
        forceRefresh: true,
      );

      final result = await RemoteCaching.instance.call<dynamic>(
        'overwrite_key',
        remote: () async => {'value': 3},
      );

      expect(Map<String, dynamic>.from(result), equals({'value': 2}));
    });

    group('TestData Tests', () {
      test('should serialize and deserialize', () async {
        const testData = TestData(name: 'John', age: 30);
        final result = await RemoteCaching.instance.call<TestData>(
          'test_key',
          remote: () async => testData,
        );
        expect(result, equals(testData));
      });

      test('TestData should use custom cache duration', () async {
        await RemoteCaching.instance.init();
        const testData = TestData(name: 'John', age: 30);

        await RemoteCaching.instance.call<TestData>(
          'test_key',
          cacheDuration: const Duration(milliseconds: 200),
          remote: () async => testData,
          fromJson: (json) => TestData.fromJson(json! as Map<String, dynamic>),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final result = await RemoteCaching.instance.call<TestData>(
          'test_key',
          remote: () async => const TestData(name: 'Jane', age: 25),
          fromJson: (json) => TestData.fromJson(json! as Map<String, dynamic>),
        );

        expect(result, equals(testData));
      });
    });

    test(
      'If deserialization fails, cache is ignored and remote is called',
      () async {
        var remoteCalls = 0;
        await RemoteCaching.instance.call<BadSerializable>(
          'test_deser',
          remote: () async {
            remoteCalls++;
            return BadSerializable('ok');
          },
          fromJson: (json) => BadSerializable.fromJson(),
          cacheDuration: const Duration(minutes: 5),
        );
        // Second call: deserialization fails, so remote is called again
        await RemoteCaching.instance.call<BadSerializable>(
          'test_deser',
          remote: () async {
            remoteCalls++;
            return BadSerializable('ok2');
          },
          fromJson: (json) => BadSerializable.fromJson(),
          cacheDuration: const Duration(minutes: 5),
        );
        expect(remoteCalls, 2);
      },
    );

    test('clear all and get stats', () async {
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.call<dynamic>(
        'test_key1',
        remote: () async => 'test',
      );
      await RemoteCaching.instance.call<dynamic>(
        'test_key2',
        remote: () async => 'test',
      );
      await RemoteCaching.instance.clearCache();
      final stats = await RemoteCaching.instance.getCacheStats();
      expect(stats.totalEntries, equals(0));
      expect(stats.totalSizeBytes, equals(0));
      expect(stats.expiredEntries, equals(0));
    });

    test(
      'If serialization fails, data is not saved in cache but remote result is still returned',
      () async {
        var remoteCalls = 0;
        final result = await RemoteCaching.instance.call<BadSerializable>(
          'test_ser',
          remote: () async {
            remoteCalls++;
            return BadSerializable('fail');
          },
          fromJson: (json) => BadSerializable.fromJson(),
          cacheDuration: const Duration(minutes: 5),
        );
        expect(result.value, 'fail');
        // Second call: nothing found in cache, remote is called again
        final result2 = await RemoteCaching.instance.call<BadSerializable>(
          'test_ser',
          remote: () async {
            remoteCalls++;
            return BadSerializable('fail2');
          },
          fromJson: (json) => BadSerializable.fromJson(),
          cacheDuration: const Duration(minutes: 5),
        );
        expect(result2.value, 'fail2');
        expect(remoteCalls, 2);
      },
    );
  });

  test('should cache a list of objects with fromJson', () async {
    await RemoteCaching.instance.init();
    final list = [
      const TestData(name: 'John', age: 30),
      const TestData(name: 'Jane', age: 25),
    ];

    await RemoteCaching.instance.call<List<TestData>>(
      'test_list',
      remote: () async => list,
      fromJson: (json) => (json! as List)
          .map((item) => TestData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    final result2 = await RemoteCaching.instance.call<List<TestData>>(
      'test_list',
      remote: () async => throw Exception('Should not call remote'),
      fromJson: (json) => (json! as List)
          .map((item) => TestData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    expect(result2, equals(list));
  });

  test('should throw error if not initialized', () async {
    await RemoteCaching.instance.dispose();
    expect(
      () => RemoteCaching.instance.call<TestDataNonSerializable>(
        'test_key',
        remote: () async =>
            const TestDataNonSerializable(name: 'John', age: 30),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('should serialize and deserialize', () async {
    await RemoteCaching.instance.init();
    const testData = TestDataNonSerializable(name: 'John', age: 30);
    final result = await RemoteCaching.instance.call<TestDataNonSerializable>(
      'test_key',
      remote: () async => testData,
    );
    expect(result, equals(testData));

    final result2 = await RemoteCaching.instance.call<TestDataNonSerializable>(
      'test_key',
      remote: () async => const TestDataNonSerializable(name: 'Jane', age: 25),
    );
    expect(result2, isNot(equals(testData)));
  });

  test('should throw error if fromJson is not provided for List', () async {
    await RemoteCaching.instance.init();
     final list = [
      const TestData(name: 'John', age: 30),
      const TestData(name: 'Jane', age: 25),
    ];

    expect(
      () => RemoteCaching.instance.call<List<TestData>>(
        'test_key',
        remote: () async => list,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
