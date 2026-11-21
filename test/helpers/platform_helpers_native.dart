import 'dart:io';

/// Whether the tests run in a browser.
const bool isWebTest = false;

/// Returns a fresh, unique database location for a test.
///
/// On native platforms this is an empty temporary directory.
String uniqueDatabasePath(String name) =>
    Directory.systemTemp.createTempSync('remote_caching_$name').path;
