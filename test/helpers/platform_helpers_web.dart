/// Whether the tests run in a browser.
const bool isWebTest = true;

int _counter = 0;

/// Returns a fresh, unique database location for a test.
///
/// On the web this is a unique virtual folder name inside IndexedDB.
String uniqueDatabasePath(String name) =>
    'remote_caching_${name}_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
