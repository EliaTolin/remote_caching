// Selects the SQLite backend for the current platform at compile time.
//
// - Native (Android, iOS, macOS, Linux, Windows, Dart VM): SQLite through
//   `dart:ffi` (`sqflite_common_ffi`), stored in a file.
// - Web: SQLite compiled to WebAssembly (`sqflite_common_ffi_web`), stored in
//   IndexedDB.
export 'database_platform_stub.dart'
    if (dart.library.js_interop) 'database_platform_web.dart'
    if (dart.library.ffi) 'database_platform_native.dart';
