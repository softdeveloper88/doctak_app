import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Snapshot of the typed home feed persisted for offline use.
class FeedCacheSnapshot {
  final List<FeedEntry> entries;
  final String? nextCursor;
  final bool hasMore;

  const FeedCacheSnapshot({
    required this.entries,
    this.nextCursor,
    this.hasMore = false,
  });
}

/// Local cache for [FeedEntry] rows served by `GET /api/feed`.
class FeedCacheService {
  static FeedCacheService? _instance;
  static const String _cacheFileName = 'doctak_feed_cache.json';
  static const int _maxCachedEntries = 150;

  FeedCacheSnapshot? _memoryCache;
  bool _isInitialized = false;
  Timer? _persistDebounce;

  factory FeedCacheService() {
    _instance ??= FeedCacheService._();
    return _instance!;
  }

  FeedCacheService._();

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('📦 FeedCacheService initialized');
  }

  Future<Directory> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/feed_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<File> get _cacheFile async {
    final dir = await _cacheDir;
    return File('${dir.path}/$_cacheFileName');
  }

  Future<FeedCacheSnapshot?> getCachedFeed() async {
    await init();

    if (_memoryCache != null && _memoryCache!.entries.isNotEmpty) {
      return _memoryCache;
    }

    try {
      final file = await _cacheFile;
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content);
      if (json is! Map) return null;

      final rawEntries =
          json['entries'] is List ? json['entries'] as List : const [];
      final entries = rawEntries
          .whereType<Map>()
          .map((e) => FeedEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (entries.isEmpty) return null;

      _memoryCache = FeedCacheSnapshot(
        entries: entries,
        nextCursor: json['nextCursor']?.toString(),
        hasMore: json['hasMore'] == true,
      );
      return _memoryCache;
    } catch (e) {
      debugPrint('❌ FeedCacheService read error: $e');
      return null;
    }
  }

  Future<void> saveFeed({
    required List<FeedEntry> entries,
    String? nextCursor,
    required bool hasMore,
    bool replace = false,
  }) async {
    await init();
    if (entries.isEmpty) return;

    try {
      List<FeedEntry> toSave;
      if (replace) {
        toSave = entries.take(_maxCachedEntries).toList();
      } else {
        final existing = _memoryCache?.entries ?? const <FeedEntry>[];
        final seen = existing.map((e) => e.dedupeKey).toSet();
        final merged = [
          ...existing,
          ...entries.where((e) => !seen.contains(e.dedupeKey)),
        ];
        toSave = merged.take(_maxCachedEntries).toList();
      }

      _memoryCache = FeedCacheSnapshot(
        entries: toSave,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );

      _schedulePersist(toSave, nextCursor, hasMore);
    } catch (e) {
      debugPrint('❌ FeedCacheService save error: $e');
    }
  }

  /// Debounce disk writes so pagination does not block scroll frames.
  void _schedulePersist(
    List<FeedEntry> entries,
    String? nextCursor,
    bool hasMore,
  ) {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 800), () {
      unawaited(_persistToDisk(entries, nextCursor, hasMore));
    });
  }

  Future<void> _persistToDisk(
    List<FeedEntry> entries,
    String? nextCursor,
    bool hasMore,
  ) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(
        jsonEncode({
          'lastSync': DateTime.now().millisecondsSinceEpoch,
          'entries': entries.map((e) => e.toJson()).toList(),
          'nextCursor': nextCursor,
          'hasMore': hasMore,
        }),
      );
      debugPrint('📦 Cached ${entries.length} feed entries');
    } catch (e) {
      debugPrint('❌ FeedCacheService persist error: $e');
    }
  }
}
