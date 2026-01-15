import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();

  static const String _cacheDirectoryName = 'voice_messages_cache';
  Directory? _cacheDirectory;
  final Map<String, String> _memoryCache = {};

  Future<void> _initializeCacheDirectory() async {
    if (_cacheDirectory != null) return;

    try {
      Directory appDir;
      if (Platform.isAndroid) {
        // For Android, use external storage if available, otherwise use app documents
        final externalDir = await getExternalStorageDirectory();
        appDir = externalDir ?? await getApplicationDocumentsDirectory();
      } else {
        // For iOS, use documents directory
        appDir = await getApplicationDocumentsDirectory();
      }

      _cacheDirectory = Directory('${appDir.path}/$_cacheDirectoryName');

      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      debugPrint('Cache directory initialized: ${_cacheDirectory!.path}');
    } catch (e) {
      debugPrint('Error initializing cache directory: $e');
    }
  }

  String _generateCacheKey(String url) {
    // Generate a unique key based on the URL
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  String _getCacheFilePath(String url) {
    final key = _generateCacheKey(url);
    final extension = _getFileExtension(url);
    return '${_cacheDirectory!.path}/$key$extension';
  }

  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      return path.substring(lastDot);
    }
    // Default to .aac if no extension found
    return '.aac';
  }

  Future<String?> getCachedAudioPath(String url) async {
    try {
      await _initializeCacheDirectory();

      // Check memory cache first
      if (_memoryCache.containsKey(url)) {
        final cachedPath = _memoryCache[url]!;
        final file = File(cachedPath);
        if (await file.exists()) {
          return cachedPath;
        } else {
          // File was deleted, remove from memory cache
          _memoryCache.remove(url);
        }
      }

      // Check disk cache
      final cachePath = _getCacheFilePath(url);
      final cacheFile = File(cachePath);

      if (await cacheFile.exists()) {
        // Verify file is not corrupted
        final fileSize = await cacheFile.length();
        if (fileSize > 0) {
          _memoryCache[url] = cachePath;
          debugPrint('Audio found in cache: $cachePath');
          return cachePath;
        } else {
          // Corrupted file, delete it
          await cacheFile.delete();
        }
      }

      // Not in cache, download it
      debugPrint('Audio not in cache, downloading: $url');
      return await _downloadAndCacheAudio(url);
    } catch (e) {
      debugPrint('Error getting cached audio: $e');
      return null;
    }
  }

  Future<String?> _downloadAndCacheAudio(String url) async {
    try {
      final cachePath = _getCacheFilePath(url);

      // Create a temporary file for downloading
      final tempPath = '$cachePath.tmp';
      final tempFile = File(tempPath);

      // Download the file
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'DocTak/1.0', 'Accept': 'audio/*'})
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw Exception('Download timeout');
            },
          );

      if (response.statusCode == 200) {
        // Write to temporary file
        await tempFile.writeAsBytes(response.bodyBytes);

        // Verify the downloaded file
        final fileSize = await tempFile.length();
        if (fileSize > 0) {
          // Move temp file to cache file
          await tempFile.rename(cachePath);
          _memoryCache[url] = cachePath;
          debugPrint('Audio cached successfully: $cachePath');
          return cachePath;
        } else {
          // Empty file, delete it
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          throw Exception('Downloaded file is empty');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _initializeCacheDirectory();

      // Clear memory cache
      _memoryCache.clear();

      // Clear disk cache
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        final files = _cacheDirectory!.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }

      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      await _initializeCacheDirectory();

      int totalSize = 0;
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        final files = _cacheDirectory!.listSync();
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  Future<void> removeCachedAudio(String url) async {
    try {
      await _initializeCacheDirectory();

      // Remove from memory cache
      _memoryCache.remove(url);

      // Remove from disk cache
      final cachePath = _getCacheFilePath(url);
      final cacheFile = File(cachePath);

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        debugPrint('Cached audio removed: $cachePath');
      }
    } catch (e) {
      debugPrint('Error removing cached audio: $e');
    }
  }

  // Clean up old cache files (older than 30 days)
  Future<void> cleanOldCache() async {
    try {
      await _initializeCacheDirectory();

      final now = DateTime.now();
      final maxAge = const Duration(days: 30);

      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        final files = _cacheDirectory!.listSync();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = now.difference(stat.modified);
            if (age > maxAge) {
              await file.delete();
              debugPrint('Deleted old cache file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old cache: $e');
    }
  }
}
