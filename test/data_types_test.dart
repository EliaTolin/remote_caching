import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models/test_models.dart';

void main() {
  group('RemoteCaching Data Types Tests', () {
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

    test('should handle different data types', () async {
      // Test with String
      final stringResult = await RemoteCaching.instance.call<String>(
        'string_key',
        remote: () async => 'test string',
        fromJson: (json) => json! as String,
      );
      expect(stringResult, equals('test string'));
      // Test with int
      final intResult = await RemoteCaching.instance.call<int>(
        'int_key',
        remote: () async => 42,
        fromJson: (json) => json! as int,
      );
      expect(intResult, equals(42));
      // Test with List
      final listResult = await RemoteCaching.instance.call<List<dynamic>>(
        'list_key',
        remote: () async => [1, 2, 3],
        fromJson: (json) => List<dynamic>.from(json! as List),
      );
      expect(List<dynamic>.from(listResult), equals([1, 2, 3]));
      // Test with Map
      final mapResult = await RemoteCaching.instance.call<Map<String, dynamic>>(
        'map_key',
        remote: () async => {'key': 'value'},
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );
      expect(Map<String, dynamic>.from(mapResult), equals({'key': 'value'}));
    });

    test('should deserialize primitive types without fromJson', () async {
      final result1 = await RemoteCaching.instance.call<String>(
        'primitive_key',
        remote: () async => 'hello world',
        fromJson: (json) => json! as String,
      );

      expect(result1, equals('hello world'));

      final result2 = await RemoteCaching.instance.call<int>(
        'int_key',
        remote: () async => 123,
        fromJson: (json) => json! as int,
      );

      expect(result2, equals(123));
    });

    test('should cache a list of objects with fromJson', () async {
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
  });
}
