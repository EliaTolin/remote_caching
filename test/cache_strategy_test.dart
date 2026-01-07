import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('CacheStrategy Tests', () {
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      await RemoteCaching.instance.init(
        databasePath: getInMemoryDatabasePath(),
      );
    });

    tearDown(() async {
      await RemoteCaching.instance.clearCache();
      await RemoteCaching.instance.dispose();
    });

    group('CacheStrategy.cacheFirst', () {
      test('should return cached data when available', () async {
        final testData = {'name': 'John', 'age': 30};
        var remoteCalls = 0;

        // First call - should fetch from remote (cacheFirst is default)
        final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'cache_first_key',
          // ignore: avoid_redundant_argument_values
          strategy: CacheStrategy.cacheFirst,
          remote: () async {
            remoteCalls++;
            return testData;
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(result1, equals(testData));
        expect(remoteCalls, equals(1));

        // Second call - should return from cache
        final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'cache_first_key',
          // ignore: avoid_redundant_argument_values
          strategy: CacheStrategy.cacheFirst,
          remote: () async {
            remoteCalls++;
            return {'different': 'data'};
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(Map<String, dynamic>.from(result2), equals(testData));
        expect(remoteCalls, equals(1)); // Remote should not be called again
      });

      test('should fetch from remote when no cache exists', () async {
        final testData = {'name': 'Jane'};
        var remoteCalls = 0;

        final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'no_cache_key',
          // ignore: avoid_redundant_argument_values
          strategy: CacheStrategy.cacheFirst,
          remote: () async {
            remoteCalls++;
            return testData;
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(result, equals(testData));
        expect(remoteCalls, equals(1));
      });

      test('should work as default strategy', () async {
        final testData = {'value': 'default_strategy'};

        // Call without specifying strategy (should default to cacheFirst)
        final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'default_strategy_key',
          remote: () async => testData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(result1, equals(testData));

        // Second call should return cached data
        final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'default_strategy_key',
          remote: () async => {'different': 'data'},
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(Map<String, dynamic>.from(result2), equals(testData));
      });
    });

    group('CacheStrategy.networkFirst', () {
      test('should always try network first when available', () async {
        final data1 = {'version': 1};
        final data2 = {'version': 2};
        var remoteCalls = 0;

        // First call
        final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'network_first_key',
          strategy: CacheStrategy.networkFirst,
          remote: () async {
            remoteCalls++;
            return data1;
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(result1, equals(data1));
        expect(remoteCalls, equals(1));

        // Second call - should still fetch from network
        final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'network_first_key',
          strategy: CacheStrategy.networkFirst,
          remote: () async {
            remoteCalls++;
            return data2;
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(result2, equals(data2));
        expect(remoteCalls, equals(2)); // Remote should be called again
      });

      test('should fall back to cache when network fails', () async {
        final cachedData = {'cached': 'data'};
        var remoteCalls = 0;

        // First call - cache the data
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'fallback_key',
          strategy: CacheStrategy.networkFirst,
          remote: () async {
            remoteCalls++;
            return cachedData;
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(remoteCalls, equals(1));

        // Second call - network fails, should return cached data
        final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'fallback_key',
          strategy: CacheStrategy.networkFirst,
          remote: () async {
            remoteCalls++;
            throw Exception('Network error');
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(Map<String, dynamic>.from(result), equals(cachedData));
        expect(remoteCalls, equals(2));
      });

      test('should rethrow error when network fails and no cache exists',
          () async {
        expect(
          () => RemoteCaching.instance.call<Map<String, dynamic>>(
            'no_cache_network_fail_key',
            strategy: CacheStrategy.networkFirst,
            remote: () async {
              throw Exception('Network error');
            },
            fromJson: (json) => Map<String, dynamic>.from(json! as Map),
          ),
          throwsException,
        );
      });

      test('should fall back to expired cache when network fails', () async {
        final cachedData = {'expired': 'data'};

        // First call - cache the data with very short duration
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'expired_fallback_key',
          cacheDuration: const Duration(milliseconds: 1),
          strategy: CacheStrategy.networkFirst,
          remote: () async => cachedData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 10));

        // Network fails - should still return expired cached data
        final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'expired_fallback_key',
          strategy: CacheStrategy.networkFirst,
          remote: () async {
            throw Exception('Network error');
          },
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(Map<String, dynamic>.from(result), equals(cachedData));
      });
    });

    group('Strategy comparison', () {
      test('cacheFirst vs networkFirst behavior difference', () async {
        final initialData = {'version': 'initial'};
        final updatedData = {'version': 'updated'};

        // Set up: Cache initial data using cacheFirst
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'comparison_cache_first',
          // ignore: avoid_redundant_argument_values
          strategy: CacheStrategy.cacheFirst,
          remote: () async => initialData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'comparison_network_first',
          strategy: CacheStrategy.networkFirst,
          remote: () async => initialData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // Test cacheFirst - should return cached data (initial)
        final cacheFirstResult =
            await RemoteCaching.instance.call<Map<String, dynamic>>(
          'comparison_cache_first',
          // ignore: avoid_redundant_argument_values
          strategy: CacheStrategy.cacheFirst,
          remote: () async => updatedData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // Test networkFirst - should return updated data
        final networkFirstResult =
            await RemoteCaching.instance.call<Map<String, dynamic>>(
          'comparison_network_first',
          strategy: CacheStrategy.networkFirst,
          remote: () async => updatedData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        expect(
          Map<String, dynamic>.from(cacheFirstResult),
          equals(initialData),
        ); // Returns cached
        expect(networkFirstResult, equals(updatedData)); // Returns fresh
      });
    });
  });
}
