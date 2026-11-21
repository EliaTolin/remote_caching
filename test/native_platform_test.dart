// Native-only tests (Dart VM): run with `flutter test`.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final cache = RemoteCaching.instance;

  tearDown(() async {
    await cache.dispose();
  });

  test('creates the database file inside databasePath, creating missing '
      'directories', () async {
    final root = Directory.systemTemp.createTempSync('remote_caching_native');
    final dir = p.join(root.path, 'nested', 'cache');
    expect(Directory(dir).existsSync(), isFalse);

    await cache.init(databasePath: dir);
    await cache.call<String>(
      'k',
      remote: () async => 'v',
      fromJson: (json) => json! as String,
    );
    await cache.dispose();

    final file = File(p.join(dir, 'remote_caching.db'));
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));

    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(file.path);
    try {
      final rows = await db.query('cache');
      expect(rows.single['key'], 'k');
      expect(rows.single['data'], '"v"');
    } finally {
      await db.close();
    }
    root.deleteSync(recursive: true);
  });

  test('accepts a custom databaseFactory', () async {
    sqfliteFfiInit();
    final root = Directory.systemTemp.createTempSync('remote_caching_factory');
    await cache.init(
      databasePath: root.path,
      databaseFactory: databaseFactoryFfi,
    );
    await cache.call<String>(
      'k',
      remote: () async => 'v',
      fromJson: (json) => json! as String,
    );
    expect(await cache.isCached('k'), isTrue);
    await cache.dispose();
    root.deleteSync(recursive: true);
  });

  test('in-memory database does not create files', () async {
    final before = Directory.current.listSync().map((e) => e.path).toSet();
    await cache.init(databasePath: getInMemoryDatabasePath());
    await cache.call<String>(
      'k',
      remote: () async => 'v',
      fromJson: (json) => json! as String,
    );
    await cache.dispose();
    final after = Directory.current.listSync().map((e) => e.path).toSet();
    expect(after.difference(before), isEmpty);
  });
}
