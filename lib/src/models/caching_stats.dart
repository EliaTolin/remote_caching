class CachingStats {
  CachingStats({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.expiredEntries,
  });
  final int totalEntries;
  final int totalSizeBytes;
  final int expiredEntries;

  @override
  String toString() {
    return 'CachingStats(totalEntries: $totalEntries, totalSizeBytes: $totalSizeBytes, expiredEntries: $expiredEntries)';
  }
}
