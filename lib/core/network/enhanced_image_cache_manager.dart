import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';

/// Creates an HttpClient optimized for image loading
HttpClient _createOptimizedHttpClient() {
  final httpClient = HttpClient();
  
  // Accept all certificates for compatibility
  httpClient.badCertificateCallback = (cert, host, port) => true;
  
  // Optimized timeouts for image loading
  httpClient.connectionTimeout = const Duration(seconds: 15);
  httpClient.idleTimeout = const Duration(seconds: 30);
  
  // Allow more concurrent connections for parallel image loading
  httpClient.maxConnectionsPerHost = 20;
  
  // Enable compression
  httpClient.autoUncompress = true;
  
  return httpClient;
}

/// Custom HTTP client for optimized image loading
class OptimizedHttpClient extends IOClient {
  OptimizedHttpClient() : super(_createOptimizedHttpClient());
}

/// Enhanced image cache manager with:
/// - Longer cache duration for offline access
/// - Optimized for large media libraries
/// - Better memory management
class EnhancedImageCacheManager extends CacheManager {
  static const String key = 'doctakEnhancedImageCache';
  
  static EnhancedImageCacheManager? _instance;
  
  factory EnhancedImageCacheManager() {
    _instance ??= EnhancedImageCacheManager._();
    return _instance!;
  }
  
  EnhancedImageCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30), // 30 days cache
          maxNrOfCacheObjects: 500, // Store up to 500 images
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(httpClient: OptimizedHttpClient()),
        ),
      );
  
  /// Clear the singleton instance
  static void reset() {
    _instance = null;
  }
  
  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/$key');
      
      if (!await cacheDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      return 0;
    }
  }
  
  /// Get human-readable cache size
  static Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Cache manager specifically for post images
/// Uses same base but with different key for organization
class PostImageCacheManager extends CacheManager {
  static const String key = 'doctakPostImageCache';
  
  static PostImageCacheManager? _instance;
  
  factory PostImageCacheManager() {
    _instance ??= PostImageCacheManager._();
    return _instance!;
  }
  
  PostImageCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 14), // 14 days for post images
          maxNrOfCacheObjects: 300, // Store up to 300 post images
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(httpClient: OptimizedHttpClient()),
        ),
      );
  
  static void reset() {
    _instance = null;
  }
}

/// Cache manager for profile images (longer cache, smaller count)
class ProfileImageCacheManager extends CacheManager {
  static const String key = 'doctakProfileImageCache';
  
  static ProfileImageCacheManager? _instance;
  
  factory ProfileImageCacheManager() {
    _instance ??= ProfileImageCacheManager._();
    return _instance!;
  }
  
  ProfileImageCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 60), // 60 days for profile pics
          maxNrOfCacheObjects: 200, // Store up to 200 profile pics
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(httpClient: OptimizedHttpClient()),
        ),
      );
  
  static void reset() {
    _instance = null;
  }
}

/// Cache manager for video thumbnails
class VideoThumbnailCacheManager extends CacheManager {
  static const String key = 'doctakVideoThumbnailCache';
  
  static VideoThumbnailCacheManager? _instance;
  
  factory VideoThumbnailCacheManager() {
    _instance ??= VideoThumbnailCacheManager._();
    return _instance!;
  }
  
  VideoThumbnailCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7), // 7 days for thumbnails
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(httpClient: OptimizedHttpClient()),
        ),
      );
  
  static void reset() {
    _instance = null;
  }
}

/// Utility class to manage all image caches
class ImageCacheUtils {
  /// Clear all image caches
  static Future<void> clearAllCaches() async {
    try {
      await EnhancedImageCacheManager().emptyCache();
      await PostImageCacheManager().emptyCache();
      await ProfileImageCacheManager().emptyCache();
      await VideoThumbnailCacheManager().emptyCache();
      debugPrint('🗑️ All image caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing caches: $e');
    }
  }
  
  /// Get total cache size
  static Future<int> getTotalCacheSize() async {
    int total = 0;
    
    try {
      final dir = await getTemporaryDirectory();
      
      final caches = [
        EnhancedImageCacheManager.key,
        PostImageCacheManager.key,
        ProfileImageCacheManager.key,
        VideoThumbnailCacheManager.key,
      ];
      
      for (final cacheKey in caches) {
        final cacheDir = Directory('${dir.path}/$cacheKey');
        if (await cacheDir.exists()) {
          await for (final entity in cacheDir.list(recursive: true)) {
            if (entity is File) {
              total += await entity.length();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error calculating cache size: $e');
    }
    
    return total;
  }
  
  /// Get formatted total cache size
  static Future<String> getTotalCacheSizeFormatted() async {
    final bytes = await getTotalCacheSize();
    
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Preload images for a list of URLs (useful for feed prefetching)
  static Future<void> preloadImages(List<String> urls) async {
    for (final url in urls) {
      if (url.isNotEmpty && url != 'null') {
        try {
          await PostImageCacheManager().getSingleFile(url);
        } catch (e) {
          // Ignore preload errors
        }
      }
    }
  }
}
