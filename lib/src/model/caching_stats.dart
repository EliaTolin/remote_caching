class CachingStats {
  final int totalEntries;
  final int totalSizeBytes;
  final int expiredEntries;

  CachingStats({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.expiredEntries,
  });
}