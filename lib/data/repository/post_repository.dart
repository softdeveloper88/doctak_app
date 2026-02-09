import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/cache/post_cache_service.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';

/// Result wrapper for repository operations
class PostResult {
  final List<Post> posts;
  final bool isFromCache;
  final bool hasMorePages;
  final int currentPage;
  final int totalPages;
  final String? error;

  PostResult({
    required this.posts,
    this.isFromCache = false,
    this.hasMorePages = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Repository that manages posts with offline-first architecture
/// Implements LinkedIn-style data loading:
/// 1. Show cached data immediately
/// 2. Fetch from API in background
/// 3. Update UI with fresh data seamlessly
class PostRepository {
  static PostRepository? _instance;

  final ApiServiceManager _apiManager = ApiServiceManager();
  final PostCacheService _cacheService = PostCacheService();

  // Stream controller for real-time updates
  final _postsStreamController = StreamController<List<Post>>.broadcast();
  Stream<List<Post>> get postsStream => _postsStreamController.stream;

  // Connectivity tracking
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;

  factory PostRepository() {
    _instance ??= PostRepository._();
    return _instance!;
  }

  PostRepository._() {
    _initConnectivityMonitoring();
    _cacheService.init();
  }

  void _initConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);

      // If we just came online, trigger a background sync
      // if (wasOffline && _isOnline) {
      //   debugPrint('📶 Network restored - triggering background sync');
      //   syncInBackground();
      // }
    });
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _postsStreamController.close();
  }

  /// Get posts with cache-first strategy
  /// Returns cached data immediately, then syncs from API
  Future<PostResult> getPosts({
    required int page,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      '📥 PostRepository.getPosts(page: $page, forceRefresh: $forceRefresh)',
    );

    // For page 1, try cache first for instant loading
    if (page == 1 && !forceRefresh) {
      final cachedPosts = await _cacheService.getCachedPosts();

      if (cachedPosts.isNotEmpty) {
        debugPrint(
          '✅ Returning ${cachedPosts.length} cached posts immediately',
        );

        // Start background sync
        _syncFromApiInBackground(page: 1, isRefresh: true);

        return PostResult(
          posts: cachedPosts,
          isFromCache: true,
          hasMorePages: true, // Assume more pages until API confirms
          currentPage: 1,
          totalPages: 1,
        );
      }
    }

    // No cache or force refresh - fetch from API
    return await _fetchFromApi(page: page, isRefresh: page == 1);
  }

  /// Fetch posts from API
  Future<PostResult> _fetchFromApi({
    required int page,
    bool isRefresh = false,
  }) async {
    if (!_isOnline) {
      // Offline - return cached data with error
      final cachedPosts = await _cacheService.getCachedPosts();
      return PostResult(
        posts: cachedPosts,
        isFromCache: true,
        error: 'No internet connection',
      );
    }

    try {
      debugPrint('🌐 Fetching posts from API (page: $page)');

      final response = await _apiManager.getPosts(
        'Bearer ${AppData.userToken}',
        '$page',
      );

      if (response.response.statusCode == 302) {
        throw Exception('Session expired');
      }

      final postData = PostDataModel.fromJson(response.response.data!);
      final posts = postData.posts?.data ?? [];
      final totalPages = postData.posts?.lastPage ?? 1;

      debugPrint(
        '✅ Fetched ${posts.length} posts from API (page $page of $totalPages)',
      );

      // Save to cache
      await _cacheService.savePosts(
        posts,
        isRefresh: isRefresh,
        lastPage: page,
        numberOfPages: totalPages,
      );

      // Notify stream listeners
      if (isRefresh) {
        _postsStreamController.add(posts);
      }

      return PostResult(
        posts: posts,
        isFromCache: false,
        hasMorePages: page < totalPages,
        currentPage: page,
        totalPages: totalPages,
      );
    } catch (e) {
      debugPrint('❌ API error: $e');

      // Return cached data on error
      final cachedPosts = await _cacheService.getCachedPosts();

      return PostResult(
        posts: cachedPosts,
        isFromCache: true,
        error: e.toString(),
      );
    }
  }

  /// Sync from API in background without blocking UI
  Future<void> _syncFromApiInBackground({
    required int page,
    bool isRefresh = false,
  }) async {
    // Prevent multiple simultaneous syncs
    if (_isSyncing) {
      debugPrint('⏳ Sync already in progress, skipping');
      return;
    }

    // Rate limit syncs (minimum 30 seconds between syncs)
    if (_lastSyncAttempt != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncAttempt!);
      if (timeSinceLastSync < const Duration(seconds: 30)) {
        debugPrint(
          '⏳ Rate limiting sync, last sync was ${timeSinceLastSync.inSeconds}s ago',
        );
        return;
      }
    }

    _isSyncing = true;
    _lastSyncAttempt = DateTime.now();

    try {
      debugPrint('🔄 Starting background sync...');

      final result = await _fetchFromApi(page: page, isRefresh: isRefresh);

      if (result.isSuccess && !result.isFromCache) {
        debugPrint(
          '✅ Background sync completed with ${result.posts.length} posts',
        );

        // Notify listeners of fresh data
        _postsStreamController.add(result.posts);
      }
    } catch (e) {
      debugPrint('❌ Background sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Public method to trigger background sync
  Future<void> syncInBackground() async {
    await _syncFromApiInBackground(page: 1, isRefresh: true);
  }

  /// Update a post (likes, comments, etc.)
  Future<void> updatePostInCache(Post post) async {
    await _cacheService.updatePost(post);

    // Notify stream listeners
    final posts = await _cacheService.getCachedPosts();
    _postsStreamController.add(posts);
  }

  /// Remove a post from cache
  Future<void> removePostFromCache(int postId) async {
    await _cacheService.removePost(postId);

    // Notify stream listeners
    final posts = await _cacheService.getCachedPosts();
    _postsStreamController.add(posts);
  }

  /// Add a new post to cache (after creation)
  Future<void> addPostToCache(Post post) async {
    await _cacheService.addPost(post);

    // Notify stream listeners
    final posts = await _cacheService.getCachedPosts();
    _postsStreamController.add(posts);
  }

  /// Clear all cached posts
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getCacheStats();
  }

  /// Check if we have cached data
  bool get hasCachedData => _cacheService.hasCachedData;

  /// Check if cache is still valid
  bool get isCacheValid => _cacheService.isCacheValid;

  /// Check network connectivity
  bool get isOnline => _isOnline;
}
