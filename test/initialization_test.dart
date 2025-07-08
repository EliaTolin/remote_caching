import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:remote_caching/src/common/get_in_memory_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('RemoteCaching Initialization Tests', () {
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

    test('should initialize with default cache duration', () async {
      expect(RemoteCaching.instance, isNotNull);
    });

    test('should initialize with custom cache duration', () async {
      const customDuration = Duration(minutes: 30);
      await RemoteCaching.instance.dispose();
      await RemoteCaching.instance.init(defaultCacheDuration: customDuration);
      expect(RemoteCaching.instance, isNotNull);
    });

    test('should allow multiple init calls without crashing', () async {
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.init();
      await RemoteCaching.instance.init();

      expect(RemoteCaching.instance, isNotNull);
    });

    test('should throw error if not initialized', () async {
      await RemoteCaching.instance.dispose();
      expect(
        () => RemoteCaching.instance.call<String>(
          'test_key',
          remote: () async => 'data',
          fromJson: (json) => json! as String,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
