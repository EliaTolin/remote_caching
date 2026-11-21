// Web-only: RemoteCaching with a custom factory (no web worker, SQLite runs in
// the page). Kept in its own file because a page must not mix worker and
// no-worker sqflite web factories.
@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'helpers/platform_helpers.dart';

void main() {
  final cache = RemoteCaching.instance;
  final factory = databaseFactoryFfiWebNoWebWorker;

  tearDown(() async {
    await cache.dispose();
  });

  test('full cache lifecycle with a custom databaseFactory', () async {
    final path = uniqueDatabasePath('no_worker');
    await cache.init(databasePath: path, databaseFactory: factory);

    var remoteCalls = 0;
    Future<Map<String, dynamic>> fetch() => cache.call<Map<String, dynamic>>(
      'profile',
      remote: () async {
        remoteCalls++;
        return {'name': 'Grace', 'age': 85};
      },
      fromJson: (json) => Map<String, dynamic>.from(json! as Map),
    );

    expect(await fetch(), {'name': 'Grace', 'age': 85});
    expect(await fetch(), {'name': 'Grace', 'age': 85});
    expect(remoteCalls, 1);

    await cache.call<String>(
      'user_1',
      remote: () async => 'a',
      fromJson: (json) => json! as String,
    );
    await cache.call<String>(
      'user_2',
      remote: () async => 'b',
      fromJson: (json) => json! as String,
    );
    expect((await cache.getCacheStats()).totalEntries, 3);
    expect(await cache.clearCacheByPrefix('user_'), 2);
    await cache.clearCacheForKey('profile');
    expect((await cache.getCacheStats()).totalEntries, 0);
  });

  test('data persists in IndexedDB with the custom factory', () async {
    final path = uniqueDatabasePath('no_worker_persist');
    await cache.init(databasePath: path, databaseFactory: factory);
    await cache.call<String>(
      'persisted',
      remote: () async => 'yes',
      fromJson: (json) => json! as String,
    );
    await cache.dispose();

    await cache.init(databasePath: path, databaseFactory: factory);
    expect(
      await cache.call<String>(
        'persisted',
        remote: () async => 'no',
        fromJson: (json) => json! as String,
      ),
      'yes',
    );
    expect(await factory.databaseExists('$path/remote_caching.db'), isTrue);
  });

  test('networkFirst falls back to the cache when the remote fails', () async {
    await cache.init(
      databasePath: uniqueDatabasePath('no_worker_strategy'),
      databaseFactory: factory,
    );
    await cache.call<String>(
      'news',
      remote: () async => 'cached',
      fromJson: (json) => json! as String,
    );
    final result = await cache.call<String>(
      'news',
      strategy: CacheStrategy.networkFirst,
      remote: () async => throw Exception('offline'),
      fromJson: (json) => json! as String,
    );
    expect(result, 'cached');
  });
}
