import 'package:flutter_test/flutter_test.dart';
import 'package:remote_caching/remote_caching.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Error Handler Tests', () {
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      await RemoteCaching.instance.init(
        databasePath: getInMemoryDatabasePath(),
      );
    });

    tearDown(() async {
      await RemoteCaching.instance.clearCache();
      await RemoteCaching.instance.dispose();
    });

    group('onError callback', () {
      test('should be called on deserialization error (fromJson)', () async {
        CacheError? capturedError;
        final testData = {'name': 'John', 'age': 30};

        // First call - cache the data
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'error_test_key',
          remote: () async => testData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // Second call - fromJson throws an error
        final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'error_test_key',
          remote: () async => {'fallback': 'data'},
          fromJson: (json) {
            throw const FormatException('Intentional error');
          },
          onError: (error) {
            capturedError = error;
          },
        );

        // Should have captured the error
        expect(capturedError, isNotNull);
        expect(capturedError!.key, equals('error_test_key'));
        expect(capturedError!.type, equals(CacheErrorType.deserializationFromJson));
        expect(capturedError!.error, isA<FormatException>());
        expect(capturedError!.rawData, isNotNull);

        // Should have fallen back to remote
        expect(result, equals({'fallback': 'data'}));
      });

      test('should not be called when no errors occur', () async {
        CacheError? capturedError;
        final testData = {'name': 'Test'};

        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'no_error_key',
          remote: () async => testData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
          onError: (error) {
            capturedError = error;
          },
        );

        expect(capturedError, isNull);
      });

      test('should work without onError callback (backward compatibility)',
          () async {
        final testData = {'name': 'John'};

        // First call - cache the data
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'backward_compat_key',
          remote: () async => testData,
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // Second call - fromJson throws but no onError provided
        // Should not throw, just fall back to remote
        final result = await RemoteCaching.instance.call<Map<String, dynamic>>(
          'backward_compat_key',
          remote: () async => {'fallback': 'data'},
          fromJson: (json) {
            throw const FormatException('Intentional error');
          },
          // No onError callback - should still work
        );

        expect(result, equals({'fallback': 'data'}));
      });

      test('CacheError should have correct message for deserialization errors',
          () async {
        CacheError? capturedError;

        // First call - cache the data
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'message_test_key',
          remote: () async => {'data': 'test'},
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // Second call - trigger error
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'message_test_key',
          remote: () async => {'fallback': 'data'},
          fromJson: (json) {
            throw const FormatException('Bad format');
          },
          onError: (error) {
            capturedError = error;
          },
        );

        expect(capturedError, isNotNull);
        expect(
          capturedError!.message,
          contains('message_test_key'),
        );
        expect(
          capturedError!.message,
          contains('Bad format'),
        );
      });

      test('CacheError toString should return readable message', () async {
        final error = CacheError(
          key: 'test_key',
          type: CacheErrorType.serialization,
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
        );

        expect(error.toString(), contains('CacheError'));
        expect(error.toString(), contains('test_key'));
      });
    });

    group('CacheErrorType', () {
      test('serialization type should have correct message', () {
        final error = CacheError(
          key: 'key',
          type: CacheErrorType.serialization,
          error: Exception('error'),
          stackTrace: StackTrace.current,
        );
        expect(error.message, contains('serialize'));
      });

      test('deserializationJson type should have correct message', () {
        final error = CacheError(
          key: 'key',
          type: CacheErrorType.deserializationJson,
          error: Exception('error'),
          stackTrace: StackTrace.current,
        );
        expect(error.message, contains('decode JSON'));
      });

      test('deserializationFromJson type should have correct message', () {
        final error = CacheError(
          key: 'key',
          type: CacheErrorType.deserializationFromJson,
          error: Exception('error'),
          stackTrace: StackTrace.current,
        );
        expect(error.message, contains('convert JSON'));
      });
    });

    group('Error scenarios', () {
      test('should handle multiple errors in sequence', () async {
        final errors = <CacheError>[];

        // Cache some data first
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'multi_error_key',
          remote: () async => {'data': 'test'},
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
        );

        // First error
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'multi_error_key',
          remote: () async => {'fallback': '1'},
          fromJson: (json) => throw Exception('Error 1'),
          onError: errors.add,
        );

        // Cache new data
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'multi_error_key',
          remote: () async => {'new': 'data'},
          fromJson: (json) => Map<String, dynamic>.from(json! as Map),
          forceRefresh: true,
        );

        // Second error
        await RemoteCaching.instance.call<Map<String, dynamic>>(
          'multi_error_key',
          remote: () async => {'fallback': '2'},
          fromJson: (json) => throw Exception('Error 2'),
          onError: errors.add,
        );

        expect(errors.length, equals(2));
        expect(errors[0].error.toString(), contains('Error 1'));
        expect(errors[1].error.toString(), contains('Error 2'));
      });
    });
  });
}
