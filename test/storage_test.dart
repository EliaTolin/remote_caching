// Storage tests run on every platform (`flutter test` and
// `flutter test --platform chrome [--wasm]`): they exercise the real
// persistent backend of the platform (a SQLite file on native, SQLite
// WebAssembly persisted in IndexedDB on the web).
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';

import 'helpers/platform_helpers.dart';

Future<Map<String, dynamic>> _cachedMap(
  String key,
  Map<String, dynamic> value, {
  Duration? cacheDuration,
  DateTime? cacheExpiring,
}) {
  return RemoteCaching.instance.call<Map<String, dynamic>>(
    key,
    cacheDuration: cacheDuration,
    cacheExpiring: cacheExpiring,
    remote: () async => value,
    fromJson: (json) => Map<String, dynamic>.from(json! as Map),
  );
}

void main() {
  final cache = RemoteCaching.instance;

  tearDown(() async {
    await cache.dispose();
  });

  group('Persistent storage', () {
    test('data survives dispose and re-init on the same path', () async {
      final path = uniqueDatabasePath('persist');

      await cache.init(databasePath: path);
      await _cachedMap('user', {'name': 'Ada'});
      expect(await cache.isCached('user'), isTrue);
      await cache.dispose();

      await cache.init(databasePath: path);
      expect(await cache.isCached('user'), isTrue);
      final result = await _cachedMap('user', {'name': 'SHOULD NOT BE USED'});
      expect(result, {'name': 'Ada'});
      expect((await cache.getCacheStats()).totalEntries, 1);
    });

    test('different database paths are isolated from each other', () async {
      final pathA = uniqueDatabasePath('iso_a');
      final pathB = uniqueDatabasePath('iso_b');

      await cache.init(databasePath: pathA);
      await _cachedMap('shared_key', {'db': 'A'});
      await cache.dispose();

      await cache.init(databasePath: pathB);
      expect(await cache.isCached('shared_key'), isFalse);
      await _cachedMap('shared_key', {'db': 'B'});
      await cache.dispose();

      await cache.init(databasePath: pathA);
      expect(await _cachedMap('shared_key', {'db': 'X'}), {'db': 'A'});
    });

    test('clearCache is persisted', () async {
      final path = uniqueDatabasePath('clear');

      await cache.init(databasePath: path);
      await _cachedMap('a', {'v': 1});
      await _cachedMap('b', {'v': 2});
      await cache.clearCache();
      await cache.dispose();

      await cache.init(databasePath: path);
      expect((await cache.getCacheStats()).totalEntries, 0);
    });

    test('clearCacheByPrefix is persisted', () async {
      final path = uniqueDatabasePath('prefix');

      await cache.init(databasePath: path);
      await _cachedMap('user_1', {'v': 1});
      await _cachedMap('user_2', {'v': 2});
      await _cachedMap('product_1', {'v': 3});
      expect(await cache.clearCacheByPrefix('user_'), 2);
      await cache.dispose();

      await cache.init(databasePath: path);
      expect(await cache.isCached('user_1'), isFalse);
      expect(await cache.isCached('user_2'), isFalse);
      expect(await cache.isCached('product_1'), isTrue);
    });

    test('expired entries are removed on re-init', () async {
      final path = uniqueDatabasePath('expired');

      await cache.init(databasePath: path);
      await _cachedMap('short', {
        'v': 1,
      }, cacheDuration: const Duration(milliseconds: 200));
      await _cachedMap('long', {
        'v': 2,
      }, cacheDuration: const Duration(hours: 1));
      await cache.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 300));

      await cache.init(databasePath: path);
      final stats = await cache.getCacheStats();
      expect(stats.totalEntries, 1);
      expect(stats.expiredEntries, 0);
      expect(await cache.isCached('long'), isTrue);
    });

    test('init without databasePath uses the default location', () async {
      await cache.init();
      await cache.clearCache();
      await _cachedMap('default_location', {'ok': true});
      await cache.dispose();

      await cache.init();
      expect(await cache.isCached('default_location'), isTrue);
      await cache.clearCache();
    });
  });

  group('In-memory database', () {
    test('in-memory data is not persisted across re-init', () async {
      await cache.init(databasePath: getInMemoryDatabasePath());
      await _cachedMap('volatile', {'v': 1});
      expect(await cache.isCached('volatile'), isTrue);
      await cache.dispose();

      await cache.init(databasePath: getInMemoryDatabasePath());
      expect(await cache.isCached('volatile'), isFalse);
      expect((await cache.getCacheStats()).totalEntries, 0);
    });
  });

  group('Data fidelity', () {
    setUp(() async {
      await cache.init(databasePath: uniqueDatabasePath('fidelity'));
    });

    test('unicode and emoji round-trip', () async {
      final value = {
        'it': 'Perché è così?',
        'ja': 'キャッシュ',
        'emoji': '🚀🔥👍🏽',
        'rtl': 'مرحبا',
      };
      await _cachedMap('unicode', value);
      expect(await _cachedMap('unicode', {}), value);
    });

    test('large payload (~1 MB) round-trips', () async {
      final big = List.generate(20000, (i) => 'item_$i' * 5).join(',');
      await RemoteCaching.instance.call<String>(
        'big',
        remote: () async => big,
        fromJson: (json) => json! as String,
      );
      final result = await RemoteCaching.instance.call<String>(
        'big',
        remote: () async => 'SHOULD NOT BE USED',
        fromJson: (json) => json! as String,
      );
      expect(result.length, big.length);
      expect(result, big);
      expect(
        (await cache.getCacheStats()).totalSizeBytes,
        greaterThan(big.length),
      );
    });

    test('large integers and doubles keep their precision', () async {
      // 2^53 - 1: the largest integer exactly representable in JavaScript.
      const value = {
        'maxSafeInt': 9007199254740991,
        'negative': -9007199254740991,
        'double': 3.141592653589793,
        'tiny': 1e-300,
      };
      await _cachedMap('numbers', value);
      final result = await _cachedMap('numbers', {});
      expect(result, value);
      expect(result['maxSafeInt'], isA<int>());
    });

    test('far future expiration date is stored correctly', () async {
      await _cachedMap('far_future', {
        'v': 1,
      }, cacheExpiring: DateTime(2999, 12, 31));
      expect(await cache.isCached('far_future'), isTrue);
      final stats = await cache.getCacheStats();
      expect(stats.totalEntries, 1);
      expect(stats.expiredEntries, 0);
    });

    test('stats return integer values', () async {
      await _cachedMap('a', {'v': 1});
      await _cachedMap('b', {'v': 2});
      final stats = await cache.getCacheStats();
      expect(stats.totalEntries, isA<int>());
      expect(stats.totalSizeBytes, isA<int>());
      expect(stats.expiredEntries, isA<int>());
      expect(stats.totalEntries, 2);
    });

    test('keys with SQL special characters are handled safely', () async {
      const keys = [
        "it's",
        'a"b',
        'drop; DROP TABLE cache; --',
        '100%_done',
        'path/with/slashes',
      ];
      for (final key in keys) {
        await _cachedMap(key, {'key': key});
      }
      for (final key in keys) {
        expect(await cache.isCached(key), isTrue, reason: key);
        expect(await _cachedMap(key, {}), {'key': key});
      }
      expect((await cache.getCacheStats()).totalEntries, keys.length);
    });
  });

  group('Concurrency', () {
    setUp(() async {
      await cache.init(databasePath: uniqueDatabasePath('concurrency'));
    });

    test('many parallel calls on different keys are all cached', () async {
      final results = await Future.wait(
        List.generate(100, (i) => _cachedMap('key_$i', {'i': i})),
      );
      for (var i = 0; i < 100; i++) {
        expect(results[i], {'i': i});
      }
      expect((await cache.getCacheStats()).totalEntries, 100);
    });

    test('parallel writes and reads on the same key stay consistent', () async {
      await Future.wait(
        List.generate(
          20,
          (i) => _cachedMap('same', {
            'i': i,
          }, cacheDuration: const Duration(hours: 1)),
        ),
      );
      final stats = await cache.getCacheStats();
      expect(stats.totalEntries, 1);
      final cached = await _cachedMap('same', {'i': -1});
      expect(cached['i'], isA<int>());
      expect(cached['i'], isNot(-1));
    });
  });

  test('platform helper matches the running platform', () {
    expect(isWebTest, kIsWeb);
  });
}
