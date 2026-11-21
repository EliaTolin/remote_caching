## 1.1.0

* **Web support**: the cache now works on Flutter web (dart2js and `--wasm`), backed by SQLite WebAssembly persisted in IndexedDB via `sqflite_common_ffi_web`. Run `dart run sqflite_common_ffi_web:setup` in your app (see README)
* New optional `databaseFactory` parameter in `init()` to provide a custom sqflite `DatabaseFactory`
* `init()` no longer overrides the global sqflite `databaseFactory` of the host app
* Upgraded to `sqflite_common_ffi` 2.4 / `sqlite3` 3.x: SQLite is bundled through build hooks, `sqlite3_flutter_libs` and `sqflite` are no longer dependencies
* Requires Dart 3.10 / Flutter 3.38 or later

## 1.0.19

* Added `isCached()` method to check if a valid (non-expired) cache entry exists for a given key

## 1.0.17

* Added `onError` callback to `call()` method for custom error handling
* New `CacheError` class with detailed error information (key, type, error, stackTrace, rawData)
* New `CacheErrorType` enum for distinguishing serialization vs deserialization errors
* Backward compatible: errors still fallback gracefully without callback

## 1.0.16

* Added `CacheStrategy` enum with `cacheFirst` and `networkFirst` strategies
* New `strategy` parameter in `call()` method for fine-grained cache control
* `networkFirst` strategy fetches fresh data and falls back to cache (even expired) on failure
* Backward compatible: default strategy remains `cacheFirst`

## 1.0.15

* Added `clearCacheByPrefix()` method to clear all cache entries matching a prefix

## 1.0.14

* Fix problem about sqflite on Android

## 1.0.13

* Fix problem about sqflite on Android

## 1.0.12

* Added new docs

## 1.0.11

* Added new docs

## 1.0.10

* Remove support for web

## 1.0.9

* Added getInMemoryDatabasePath function
* Added databasePath parameter to the init method

## 1.0.8

* Added databasePath parameter to the call method

## 1.0.7

* Update docs

## 1.0.6

* Added cacheExpiring parameter to the call method

## 1.0.5


## 1.0.4

* Added verbose mode
* Added exception if fromJson is not provided for List

## 1.0.3

* First stable release

## 0.0.1

* Initial release
