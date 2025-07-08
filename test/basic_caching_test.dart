import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('RemoteCaching Basic Caching Tests', () {
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

    test('should cache and retrieve data', () async {
      final testData = {'name': 'John', 'age': 30};
      // First call should execute remote function
      final result1 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result1, equals(testData));
      // Second call should return cached data
      final result2 = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => {'different': 'data'}, // This should not be called
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(Map<String, dynamic>.from(result2), equals(testData));
    });

    test('should force refresh when requested', () async {
      final testData1 = {'name': 'John'};
      final testData2 = {'name': 'Jane'};
      // First call
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData1,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      // Force refresh
      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'test_key',
        remote: () async => testData2,
        forceRefresh: true,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(result, equals(testData2));
    });

    test('should cache and retrieve nested Map structures', () async {
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
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'nested_key',
        remote: () async => {
          'user': {'name': 'Other'},
        }, // fallback, shouldn't be used
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(Map<String, dynamic>.from(result), equals(complexData));
    });

    test('should overwrite cached data on second call', () async {
      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'overwrite_key',
        remote: () async => {'value': 1},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      await RemoteCaching.instance.call<Map<String, dynamic>>(
        'overwrite_key',
        remote: () async => {'value': 2},
        forceRefresh: true,
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'overwrite_key',
        remote: () async => {'value': 3},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      expect(Map<String, dynamic>.from(result), equals({'value': 2}));
    });
  });
}
