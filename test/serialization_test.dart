import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models/test_models.dart';

void main() {
  group('RemoteCaching Serialization Tests', () {
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

    group('TestData Tests', () {
      test('should serialize and deserialize', () async {
        const testData = TestData(name: 'John', age: 30);
        const testData2 = TestData(name: 'Jane', age: 25);
        final result = await RemoteCaching.instance.call<TestData>(
          'test_key',
          remote: () async => testData,
          fromJson: (json) => TestData.fromJson(json! as Map<String, dynamic>),
        );
        final result2 = await RemoteCaching.instance.call<TestData>(
          'test_key',
          remote: () async => testData2,
          fromJson: (json) => TestData.fromJson(json! as Map<String, dynamic>),
        );
        expect(result, equals(testData));
        expect(result2, equals(testData));
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
}
