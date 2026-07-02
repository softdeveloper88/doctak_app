import 'dart:io';
import 'package:doctak_app/core/utils/app/AppData.dart';
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
    return '.m4a';
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

      // Check disk cache (may be stored with content-type extension, e.g. .m4a for .webm URL)
      for (final ext in ['.m4a', '.webm', '.ogg', '.wav', '.mp3', _getFileExtension(url)]) {
        final cachePath = '${_cacheDirectory!.path}/${_generateCacheKey(url)}$ext';
        final cacheFile = File(cachePath);
        if (await cacheFile.exists()) {
          final fileSize = await cacheFile.length();
          if (fileSize > 0) {
            _memoryCache[url] = cachePath;
            debugPrint('Audio found in cache: $cachePath');
            return cachePath;
          }
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

  Map<String, String> _downloadHeaders() {
    final headers = <String, String>{
      'User-Agent': 'DocTak/1.0',
      'Accept': 'audio/*,*/*',
    };
    final token = AppData.userToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _extensionFromContentType(String? contentType, String url) {
    final mime = (contentType ?? '').toLowerCase();
    if (mime.contains('wav')) return '.wav';
    if (mime.contains('mpeg') || mime.contains('mp3')) return '.mp3';
    if (mime.contains('ogg')) return '.ogg';
    if (mime.contains('webm')) return '.webm';
    if (mime.contains('mp4') || mime.contains('m4a') || mime.contains('aac')) return '.m4a';
    return _getFileExtension(url);
  }

  Future<String?> _downloadAndCacheAudio(String url) async {
    try {
      await _initializeCacheDirectory();

      final response = await http
          .get(Uri.parse(url), headers: _downloadHeaders())
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw Exception('Download timeout');
            },
          );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        final extension = _extensionFromContentType(contentType, url);
        final finalCachePath = '${_cacheDirectory!.path}/${_generateCacheKey(url)}$extension';
        final tempPath = '$finalCachePath.tmp';
        final tempFile = File(tempPath);

        await tempFile.writeAsBytes(response.bodyBytes);

        // Verify the downloaded file
        final fileSize = await tempFile.length();
        if (fileSize > 0) {
          await tempFile.rename(finalCachePath);
          _memoryCache[url] = finalCachePath;
          debugPrint('Audio cached successfully: $finalCachePath');
          return finalCachePath;
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
