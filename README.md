<div align="center">
  <img src="assets/logo.png" alt="Remote Caching Logo" width="240" />
</div>

# Remote Caching 🔁

[![pub package](https://img.shields.io/pub/v/remote_caching.svg)](https://pub.dev/packages/remote_caching)
[![GitHub stars](https://img.shields.io/github/stars/eliatoli/remote_caching?style=social)](https://github.com/eliatoli/remote_caching)

A lightweight yet powerful Flutter package for caching asynchronous remote calls locally using SQLite — with full support for expiration, serialization, and custom deserializers.

> Save your API responses. Avoid unnecessary network calls. Go fast. Stay clean.

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


## 🚀 Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  remote_caching: ^0.0.1
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
  verboseMode: true, // Optional: see logs in your console
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
print(stats); // { total_entries: 3, total_size_bytes: 1234, expired_entries: 1 }
```

---

## 📦 Example

A full example is available in the [`example/`](example/) directory. It demonstrates how to cache results from the [Agify.io](https://agify.io) API and display them in a Flutter app.

---

## 📚 API Reference

### RemoteCaching

| Method | Description |
|--------|-------------|
| `init({Duration? defaultCacheDuration, bool verboseMode = false})` | Initialize the cache system |
| `call<T>(String key, {required Future<T> Function() remote, Duration? cacheDuration, bool forceRefresh = false, T Function(Object? json)? fromJson})` | Cache a remote call |
| `clearCache()` | Clear all cache |
| `clearCacheForKey(String key)` | Clear cache for a specific key |
| `getCacheStats()` | Get cache statistics |
| `dispose()` | Dispose the cache system |

---

## ❓ FAQ

**Q: What happens if serialization or deserialization fails?**  
A: The error is logged, the cache is ignored, and the remote call is used. Your app will never crash due to cache errors.

**Q: Can I use my own model classes?**  
A: Yes! Just provide a `fromJson` function and ensure your model supports `toJson`.

**Q: Does it work offline?**  
A: Cached data is available offline until it expires or is cleared.

---

## 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to check [issues page](https://github.com/eliatolin/remote_caching/issues) or submit a pull request.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a new Pull Request

---

_Made with ❤️ by [Eliatolin](https://github.com/eliatolin)_
