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
