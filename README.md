<p align="center">
  <img src="https://raw.githubusercontent.com/eliatolin/remote_caching/main/assets/logo.png" width="220px" alt="Remote Caching logo" />
</p>

<h1 align="center">🔁 Remote Caching 📦</h1>

<p align="center">
  <strong>A lightweight, flexible, and persistent cache layer for remote API calls in Flutter.</strong><br />
  Avoid redundant network calls. Boost performance. Cache smartly.
</p>

<p align="center">
  <a href="https://pub.dev/packages/remote_caching">
    <img src="https://img.shields.io/pub/points/remote_caching" alt="Pub Points" />
  </a>
  <a href="https://pub.dev/packages/remote_caching">
    <img src="https://img.shields.io/pub/v/remote_caching.svg" alt="Pub Version" />
  </a>
  <a href="https://github.com/eliatolin/remote_caching">
    <img src="https://img.shields.io/github/stars/eliatolin/remote_caching?style=social" alt="GitHub Stars" />
  </a>
  <a href="https://pub.dev/packages/very_good_analysis">
    <img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="Very Good Analysis" />
  </a>
  <a href="https://github.com/eliatolin/remote_caching/actions"><img src="https://github.com/eliatolin/remote_caching/actions/workflows/test.yml/badge.svg"></a>
  <a href="https://codecov.io/github/EliaTolin/remote_caching" >
    <img src="https://codecov.io/github/EliaTolin/remote_caching/graph/badge.svg?token=P09UXF2DER"/>
  </a>
</p>

---

A lightweight yet powerful Flutter package for caching asynchronous remote calls locally using SQLite — with full support for expiration, serialization, and custom deserializers.

> 🧠 Save your API responses. 🔁 Avoid unnecessary calls. ⚡ Go fast. 💡 Stay clean.

---

## ✨ Features

- ✅ **Automatic caching** of remote data  
- ⏳ **Configurable expiration** duration per call  
- 🔄 **Manual cache invalidation** (by key or all)  
- 💾 **SQLite-powered** persistent cache  
- 🧩 **Generic support** for any type (`Map`, `List`, custom models...)  
- 🧰 **Custom `fromJson()`** support for deserializing complex types  
- 📊 **Cache statistics API**  
- 🧪 **Test-friendly** and easy to debug (`verboseMode`)  

## ❗ Why RemoteCaching?

- 🔍 You need **structured, persistent caching** for remote API calls
- 💡 You want **control** over serialization and expiration
- 🧼 You don't want to reinvent the wheel each time you need simple cache logic

## 🚀 Getting Started

Add to your `pubspec.yaml`:

```sh
flutter pub add remote_caching
```

Then run:

```sh
flutter pub get
```

---

## 🛠️ Usage

### 1. Initialize the cache system

```dart
await RemoteCaching.instance.init(
  defaultCacheDuration: Duration(hours: 1), // Optional
  verboseMode: true, // Optional: see RemoteCaching logs in your console, default is enabled only in debug mode
  databasePath: '/path/to/your/database.db', // Optional: specify a custom database path.
);
```

### 2. Cache a remote API call

```dart
final user = await RemoteCaching.instance.call<UserProfile>(
  'user_profile',
  cacheDuration: Duration(minutes: 30), // Optional
  remote: () async => await fetchUserProfile(),
  fromJson: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
);
```

Or use cacheExpiring for an exact expiration date/time:

```dart
final user = await RemoteCaching.instance.call<UserProfile>(
  'user_profile',
  cacheExpiring: DateTime.now().add(Duration(hours: 2)), // Optional
  remote: () async => await fetchUserProfile(),
  fromJson: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
);
```

Or if you want to cache a remote call with a dynamic key:

```dart
final pizza = await RemoteCaching.instance.call<Pizza>(
  'pizza_${pizzaName}',
  cacheDuration: Duration(minutes: 30), // Optional
  remote: () async => await fetchPizza(pizzaName),
  fromJson: (json) => Pizza.fromJson(json as Map<String, dynamic>),
);
```

If you want to cache a list of objects, you need to provide a `fromJson` function.

```dart
final pizzas = await RemoteCaching.instance.call<List<Pizza>>(
  'pizzas',
  remote: () async => await fetchPizzas(),
  fromJson: (json) => (json as List)
      .map((item) => Pizza.fromJson(item as Map<String, dynamic>))
      .toList(),
);
```

- The first call fetches from remote and caches the result.
- Subsequent calls within 30 minutes return the cached value.
- After expiration, the remote is called again and cache is updated.

### 3. Force refresh

```dart
await RemoteCaching.instance.call(
  'user_profile',
  forceRefresh: true,
  remote: () async => await fetchUserProfile(),
  fromJson: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
);
```

### 4. Clear cache

```dart
await RemoteCaching.instance.clearCache(); // All
await RemoteCaching.instance.clearCacheForKey('user_profile'); // By key
```

### 5. Get cache statistics

```dart
final stats = await RemoteCaching.instance.getCacheStats();
print(stats); // CachingStats(totalEntries: 3, totalSizeBytes: 1234, expiredEntries: 1)
```
---

### 💡 Use in-memory database (optional)

If you want to initialize Remote Caching in memory, you can pass getInMemoryDatabasePath() to the init() method:

```dart
await RemoteCaching.instance.init(
  databasePath: getInMemoryDatabasePath(),
);
```

This will create a non-persistent in-memory cache, meaning all cached data will be lost on app restart.
⚠️ Avoid storing large datasets in memory, especially on mobile devices, as available RAM can be limited.

---

## 📦 Example

A full example is available in the [`example/`](example/) directory. It demonstrates how to cache results from the [Agify.io](https://agify.io) API and display them in a Flutter app.

---

## 📚 API Reference

### RemoteCaching

| Method | Description |
|--------|-------------|
| `init({Duration? defaultCacheDuration, bool verboseMode = false, String? databasePath})` | Initialize the cache system |
| `call<T>(String key, {required Future<T> Function() remote, Duration? cacheDuration, DateTime? cacheExpiring, bool forceRefresh = false, T Function(Object? json)? fromJson})` | Cache a remote call |
| `clearCache()` | Clear all cache |
| `clearCacheForKey(String key)` | Clear cache for a specific key |
| `getCacheStats()` | Get cache statistics |
| `dispose()` | Dispose the cache system |

---

## ❓ FAQ

**Q: What happens if serialization or deserialization fails?**  
A: The error is logged, the cache is ignored, and the remote call is used. Your app will never crash due to cache errors.

**Q: Can I use my own model classes?**  
A: Yes! Just provide a fromJson function and ensure your model supports toJson when caching. The package relies on jsonEncode / jsonDecode under the hood.

**Q: Does it work offline?**  
A: Cached data is available offline until it expires or is cleared.

**Q: Does it work on all platforms?**  
A: We use [sqlite3](https://pub.dev/packages/sqflite) with [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) to support all platforms. Refer to the packages docs for more information.

**Q: Can I use a custom database path?**  
A: Yes! You can specify a custom database path using the `databasePath` parameter.

**Q: Why use concurrency=1 in the test?**  
A: We use concurrency=1 in the test to avoid race conditions when reading and writing to the database at the same time.
Flutter runs tests in parallel when there are multiple test files.

---

## 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to check [issues page](https://github.com/eliatolin/remote_caching/issues) or submit a pull request.

---

_Made with ❤️ by [Eliatolin](https://github.com/eliatolin)_
