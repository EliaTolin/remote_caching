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

## 📋 Table of Contents

- [✨ Features](#-features)
- [🎯 Why RemoteCaching?](#-why-remotecaching)
- [🚀 Quick Start](#-quick-start)
- [🛠️ Usage Guide](#️-usage-guide)
- [📚 API Reference](#-api-reference)
- [💡 Advanced Usage](#-advanced-usage)
- [📦 Complete Example](#-complete-example)
- [❓ FAQ](#-faq)
- [🤝 Contributing](#-contributing)

---

## ✨ Features

- ✅ **Automatic caching** of remote data with intelligent expiration
- ⏳ **Flexible expiration** - use duration or exact datetime
- 🔄 **Manual cache invalidation** (by key or clear all)
- 💾 **SQLite-powered** persistent cache with automatic cleanup
- 🧩 **Generic support** for any data type (`Map`, `List`, custom models...)
- 🧰 **Custom deserialization** with `fromJson` functions
- 📊 **Cache statistics** and monitoring
- 🧪 **Test-friendly** with verbose logging and in-memory database support
- 🛡️ **Error handling** - graceful fallback to remote calls
- 🔧 **Cross-platform** support (iOS, Android, Web, Desktop)

## 🎯 Why RemoteCaching?

- 🔍 You need **structured, persistent caching** for remote API calls
- 💡 You want **fine-grained control** over serialization and expiration
- 🧼 You don't want to reinvent the wheel each time you need cache logic
- ⚡ You want to **reduce API calls** and improve app performance
- 🛡️ You need **reliable error handling** that won't break your app

---

## 🚀 Quick Start

### 1. Add the dependency

```bash
flutter pub add remote_caching
```

### 2. Initialize the cache

```dart
import 'package:remote_caching/remote_caching.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await RemoteCaching.instance.init(
    defaultCacheDuration: Duration(hours: 1),
    verboseMode: true, // See logs in debug mode
  );
  
  runApp(MyApp());
}
```

### 3. Cache your first API call

```dart
class UserService {
  Future<User> getUserProfile(String userId) async {
    return await RemoteCaching.instance.call<User>(
      'user_$userId',
      cacheDuration: Duration(minutes: 30),
      remote: () async => await fetchUserFromAPI(userId),
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }
}
```

---

## 🛠️ Usage Guide

### 📋 Initialization

Initialize the cache system with your preferred settings:

```dart
await RemoteCaching.instance.init(
  defaultCacheDuration: Duration(hours: 1), // Default cache duration
  verboseMode: true, // Enable detailed logging (default: kDebugMode)
  databasePath: '/custom/path/cache.db', // Custom database path (optional)
);
```

**Parameters:**
- `defaultCacheDuration`: Default expiration time for cached items
- `verboseMode`: Enable detailed logging for debugging
- `databasePath`: Custom database path (uses default if not specified)

### 🔄 Basic Caching

Cache a simple API call with automatic expiration:

```dart
final user = await RemoteCaching.instance.call<User>(
  'user_profile_123',
  cacheDuration: Duration(minutes: 30),
  remote: () async => await apiService.getUser(123),
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

### ⏰ Exact Expiration Time

Use a specific expiration datetime instead of duration:

```dart
final user = await RemoteCaching.instance.call<User>(
  'user_profile_123',
  cacheExpiring: DateTime.now().add(Duration(hours: 2)),
  remote: () async => await apiService.getUser(123),
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

### 📝 Caching Lists and Complex Data

Cache lists, maps, or any serializable data:

```dart
// Cache a list of users
final users = await RemoteCaching.instance.call<List<User>>(
  'all_users',
  remote: () async => await apiService.getAllUsers(),
  fromJson: (json) => (json as List)
      .map((item) => User.fromJson(item as Map<String, dynamic>))
      .toList(),
);

// Cache a map of settings
final settings = await RemoteCaching.instance.call<Map<String, dynamic>>(
  'app_settings',
  remote: () async => await apiService.getSettings(),
  fromJson: (json) => Map<String, dynamic>.from(json as Map),
);
```

### 🔄 Force Refresh

Bypass cache and fetch fresh data:

```dart
final user = await RemoteCaching.instance.call<User>(
  'user_profile_123',
  forceRefresh: true, // Ignore cache, fetch from remote
  remote: () async => await apiService.getUser(123),
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);
```

### 🧹 Cache Management

Clear cache entries as needed:

```dart
// Clear specific cache entry
await RemoteCaching.instance.clearCacheForKey('user_profile_123');

// Clear all cache
await RemoteCaching.instance.clearCache();
```

### 📊 Cache Statistics

Monitor your cache usage:

```dart
final stats = await RemoteCaching.instance.getCacheStats();
print('Total entries: ${stats.totalEntries}');
print('Total size: ${stats.totalSizeBytes} bytes');
print('Expired entries: ${stats.expiredEntries}');
```

---

## 💡 Advanced Usage

### 🧠 In-Memory Database

Use in-memory database for testing or temporary caching:

```dart
import 'package:remote_caching/src/common/get_in_memory_database.dart';

await RemoteCaching.instance.init(
  databasePath: getInMemoryDatabasePath(),
  verboseMode: true,
);
```

⚠️ **Warning**: In-memory cache is lost on app restart. Avoid storing large datasets.

### 🔑 Dynamic Cache Keys

Generate cache keys dynamically based on parameters:

```dart
class ProductService {
  Future<Product> getProduct(String category, String id) async {
    final cacheKey = 'product_${category}_$id';
    
    return await RemoteCaching.instance.call<Product>(
      cacheKey,
      remote: () async => await apiService.getProduct(category, id),
      fromJson: (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }
}
```

### 🛡️ Error Handling

The package handles serialization errors gracefully:

```dart
// If serialization fails, the remote call is used instead
// No app crashes, just logged errors
final data = await RemoteCaching.instance.call<ComplexModel>(
  'complex_data',
  remote: () async => await fetchComplexData(),
  fromJson: (json) => ComplexModel.fromJson(json as Map<String, dynamic>),
);
```

### 🔄 Cache Invalidation Strategies

Implement different cache invalidation patterns:

```dart
class CacheManager {
  // Invalidate related cache entries
  Future<void> invalidateUserCache(String userId) async {
    await RemoteCaching.instance.clearCacheForKey('user_$userId');
    await RemoteCaching.instance.clearCacheForKey('user_profile_$userId');
    await RemoteCaching.instance.clearCacheForKey('user_settings_$userId');
  }
  
  // Invalidate all cache when user logs out
  Future<void> onUserLogout() async {
    await RemoteCaching.instance.clearCache();
  }
}
```

---

## 📦 Complete Example

Here's a complete example showing how to cache API responses in a Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? _user;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await RemoteCaching.instance.call<User>(
        'user_profile_123',
        cacheDuration: Duration(minutes: 30),
        remote: () async {
          final response = await http.get(
            Uri.parse('https://api.example.com/users/123'),
          );
          
          if (response.statusCode == 200) {
            return jsonDecode(response.body);
          } else {
            throw Exception('Failed to load user profile');
          }
        },
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    // Force refresh from remote
    final user = await RemoteCaching.instance.call<User>(
      'user_profile_123',
      forceRefresh: true,
      remote: () async {
        final response = await http.get(
          Uri.parse('https://api.example.com/users/123'),
        );
        return jsonDecode(response.body);
      },
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );

    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    
    if (_user == null) {
      return Center(child: Text('No user data'));
    }
    
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: ${_user!.name}', style: Theme.of(context).textTheme.headline6),
          Text('Email: ${_user!.email}'),
          Text('Age: ${_user!.age}'),
        ],
      ),
    );
  }
}

class User {
  final String name;
  final String email;
  final int age;

  User({required this.name, required this.email, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
    );
  }
}
```

A full working example is available in the [`example/`](example/) directory.

---

## 📚 API Reference

### RemoteCaching Class

The main class for managing remote caching operations.

#### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `init()` | Initialize the cache system | `defaultCacheDuration`, `verboseMode`, `databasePath` |
| `call<T>()` | Cache a remote call | `key`, `remote`, `fromJson`, `cacheDuration`, `cacheExpiring`, `forceRefresh` |
| `clearCache()` | Clear all cache entries | None |
| `clearCacheForKey()` | Clear specific cache entry | `key` |
| `getCacheStats()` | Get cache statistics | None |
| `dispose()` | Clean up resources | None |

#### Parameters Details

**`init()` parameters:**
- `defaultCacheDuration` (Duration?): Default expiration time for cached items
- `verboseMode` (bool): Enable detailed logging (default: `kDebugMode`)
- `databasePath` (String?): Custom database path

**`call<T>()` parameters:**
- `key` (String): Unique identifier for the cache entry
- `remote` (Future<T> Function()): Function that fetches data from remote source
- `fromJson` (T Function(Object? json)): Function to deserialize JSON data
- `cacheDuration` (Duration?): How long to cache the data
- `cacheExpiring` (DateTime?): Exact expiration datetime
- `forceRefresh` (bool): Bypass cache and fetch fresh data

### CachingStats Class

Statistics about the current cache state.

```dart
class CachingStats {
  final int totalEntries;      // Total number of cached entries
  final int totalSizeBytes;    // Total size of cached data in bytes
  final int expiredEntries;    // Number of expired entries
}
```

---

## ❓ FAQ

**Q: What happens if serialization or deserialization fails?**  
A: The error is logged, the cache is ignored, and the remote call is used. Your app will never crash due to cache errors.

**Q: Can I use my own model classes?**  
A: Yes! Just provide a `fromJson` function and ensure your model supports `toJson` when caching. The package relies on `jsonEncode` / `jsonDecode` under the hood.

**Q: Does it work offline?**  
A: Cached data is available offline until it expires or is cleared.

**Q: Does it work on all platforms?**  
A: We use [sqlite3](https://pub.dev/packages/sqflite) with [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) to support all platforms. Refer to the packages docs for more information.

**Q: Can I use a custom database path?**  
A: Yes! You can specify a custom database path using the `databasePath` parameter in the `init()` method.

**Q: How do I handle cache invalidation?**  
A: Use `clearCacheForKey()` for specific entries or `clearCache()` for all entries. You can also use `forceRefresh: true` to bypass cache for a single call.

**Q: What's the difference between `cacheDuration` and `cacheExpiring`?**  
A: `cacheDuration` sets expiration relative to now (e.g., 30 minutes from now), while `cacheExpiring` sets an absolute expiration datetime.

**Q: Can I cache different types of data?**  
A: Yes! You can cache any serializable data: primitives, maps, lists, custom objects, etc. Just provide the appropriate `fromJson` function.

**Q: Is the cache persistent?**  
A: Yes, by default the cache is stored in SQLite and persists between app launches. Use `getInMemoryDatabasePath()` for temporary in-memory caching.

**Q: How do I monitor cache performance?**  
A: Use `getCacheStats()` to get statistics about cache usage, or enable `verboseMode` to see detailed logs.

---

## 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to check [issues page](https://github.com/eliatolin/remote_caching/issues) or submit a pull request.

### Code Style

This project follows the [very_good_analysis](https://pub.dev/packages/very_good_analysis) linting rules.

---

_Made with ❤️ by [Eliatolin](https://github.com/eliatolin)_
