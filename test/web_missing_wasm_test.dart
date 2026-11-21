// Web-only: behavior when the SQLite WebAssembly binary cannot be loaded.
// Kept in its own file because a page must use a single sqflite web factory
// configuration.
@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'helpers/platform_helpers.dart';

void main() {
  final cache = RemoteCaching.instance;

  tearDown(() async {
    await cache.dispose();
  });

  test('init fails with a clear error when sqlite3.wasm is missing', () async {
    final brokenFactory = createDatabaseFactoryFfiWeb(
      options: SqfliteFfiWebOptions(
        sqlite3WasmUri: Uri.parse('/does_not_exist/sqlite3.wasm'),
      ),
      noWebWorker: true,
    );
    await expectLater(
      cache.init(
        databasePath: uniqueDatabasePath('broken'),
        databaseFactory: brokenFactory,
      ),
      throwsA(anything),
    );
    // A failed init leaves the cache uninitialized and usable later.
    expect(await cache.isCached('anything'), isFalse);
  });
}
