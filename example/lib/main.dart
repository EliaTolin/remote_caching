import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:remote_caching/remote_caching.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Caching Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AgePredictionPage(),
    );
  }
}

class AgePredictionPage extends StatefulWidget {
  const AgePredictionPage({super.key});

  @override
  State<AgePredictionPage> createState() => _AgePredictionPageState();
}

class _AgePredictionPageState extends State<AgePredictionPage> {
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _ageData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCaching();
  }

  Future<void> _initializeCaching() async {
    try {
      await RemoteCaching.instance.init(
        defaultCacheDuration: const Duration(minutes: 30),
        verboseMode: true,
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize caching: $e';
      });
    }
  }

  Future<void> _predictAge() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = 'Please enter a name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _ageData = null;
    });

    try {
      final data = await RemoteCaching.instance.call(
        'age_prediction_$name',
        cacheExpiring: DateTime.now().add(const Duration(seconds: 10)),
        remote: () async {
          final response = await http.get(
            Uri.parse('https://api.agify.io?name=$name'),
          );

          if (response.statusCode == 200) {
            return jsonDecode(response.body) as Map<String, dynamic>;
          } else {
            throw Exception('Failed to load age prediction');
          }
        },
        fromJson: (json) => Map<String, dynamic>.from(json! as Map),
      );

      setState(() {
        _ageData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    try {
      await RemoteCaching.instance.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    }
  }

  Future<void> _showCacheStats() async {
    try {
      final stats = await RemoteCaching.instance.getCacheStats();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cache Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total entries: ${stats.totalEntries}'),
                Text('Total size: ${stats.totalSizeBytes} bytes'),
                Text('Expired entries: ${stats.expiredEntries}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get cache stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Age Prediction with Caching'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showCacheStats,
            tooltip: 'Cache Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearCache,
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter a name',
                hintText: 'e.g., meelad',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _predictAge(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _predictAge,
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Predicting...'),
                      ],
                    )
                  : const Text('Predict Age'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            if (_ageData != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Age Prediction for "${_ageData!['name']}"',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 32),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Predicted Age: ${_ageData!['age']}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              Text(
                                'Based on ${_ageData!['count']} occurrences',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '💾 This result is cached for 10 seconds!',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            const Text(
              'Powered by Agify.io API',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
