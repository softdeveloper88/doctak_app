/// Offline-First Data Cache System
///
/// This module provides LinkedIn-style offline-first architecture for the DocTak app.
///
/// Features:
/// - Instant loading from local cache
/// - Background sync with API
/// - Seamless UI updates when fresh data arrives
/// - Offline support with automatic retry
/// - Optimized image caching with compression
///
/// Usage:
/// ```dart
/// // In your BLoC
/// import 'package:doctak_app/data/cache/cache_exports.dart';
///
/// // Get cached posts
/// final cacheService = PostCacheService();
/// final posts = await cacheService.getCachedPosts();
///
/// // Use repository for full cache-first loading
/// final repository = PostRepository();
/// final result = await repository.getPosts(page: 1);
/// ```
library;

export 'post_cache_service.dart';
export '../repository/post_repository.dart';
