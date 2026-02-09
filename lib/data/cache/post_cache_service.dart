import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:crypto/crypto.dart';

/// Parse posts from JSON in isolate
List<Post> _parsePostsFromJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((e) => Post.fromJson(e)).toList();
}

/// Encode posts to JSON in isolate
String _encodePostsToJson(List<Map<String, dynamic>> posts) {
  return json.encode(posts);
}

/// A high-performance local cache service for posts
/// Implements LinkedIn-style offline-first architecture
class PostCacheService {
  static PostCacheService? _instance;
  static const String _cacheFileName = 'doctak_posts_cache.json';
  static const String _metadataFileName = 'doctak_posts_metadata.json';
  static const int _maxCachedPosts = 100; // Keep last 100 posts
  static const Duration _cacheValidityDuration = Duration(hours: 24);
  
  // In-memory cache for fastest access
  List<Post>? _memoryCache;
  Map<String, dynamic>? _metadata;
  bool _isInitialized = false;
  
  factory PostCacheService() {
    _instance ??= PostCacheService._();
    return _instance!;
  }
  
  PostCacheService._();
  
  /// Initialize the cache service
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      await _loadMetadata();
      _isInitialized = true;
      debugPrint('📦 PostCacheService initialized');
    } catch (e) {
      debugPrint('❌ PostCacheService init error: $e');
    }
  }
  
  /// Get cache directory
  Future<Directory> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/post_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
  
  /// Get cache file
  Future<File> get _cacheFile async {
    final dir = await _cacheDir;
    return File('${dir.path}/$_cacheFileName');
  }
  
  /// Get metadata file
  Future<File> get _metadataFile async {
    final dir = await _cacheDir;
    return File('${dir.path}/$_metadataFileName');
  }
  
  /// Load metadata from disk
  Future<void> _loadMetadata() async {
    try {
      final file = await _metadataFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        _metadata = json.decode(content);
      } else {
        _metadata = {
          'lastSync': 0,
          'totalPosts': 0,
          'lastPage': 1,
          'numberOfPages': 1,
          'postHashes': <String, String>{},
        };
      }
    } catch (e) {
      debugPrint('❌ Error loading metadata: $e');
      _metadata = {
        'lastSync': 0,
        'totalPosts': 0,
        'lastPage': 1,
        'numberOfPages': 1,
        'postHashes': <String, String>{},
      };
    }
  }
  
  /// Save metadata to disk
  Future<void> _saveMetadata() async {
    try {
      final file = await _metadataFile;
      await file.writeAsString(json.encode(_metadata));
    } catch (e) {
      debugPrint('❌ Error saving metadata: $e');
    }
  }
  
  /// Check if cache is valid
  bool get isCacheValid {
    if (_metadata == null) return false;
    final lastSync = _metadata!['lastSync'] as int? ?? 0;
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    return DateTime.now().difference(lastSyncTime) < _cacheValidityDuration;
  }
  
  /// Check if we have any cached data (even if expired)
  bool get hasCachedData {
    return _memoryCache != null && _memoryCache!.isNotEmpty;
  }
  
  /// Get last sync time
  DateTime? get lastSyncTime {
    if (_metadata == null) return null;
    final lastSync = _metadata!['lastSync'] as int? ?? 0;
    if (lastSync == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(lastSync);
  }
  
  /// Get cached posts (memory-first, then disk)
  Future<List<Post>> getCachedPosts() async {
    await init();
    
    // Return from memory if available
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      debugPrint('📦 Returning ${_memoryCache!.length} posts from memory cache');
      return List.from(_memoryCache!);
    }
    
    // Load from disk using isolate for JSON parsing
    try {
      final file = await _cacheFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        // Parse JSON in isolate to prevent UI jank
        _memoryCache = await compute(_parsePostsFromJson, content);
        debugPrint('📦 Loaded ${_memoryCache!.length} posts from disk cache (isolate)');
        return List.from(_memoryCache!);
      }
    } catch (e) {
      debugPrint('❌ Error reading cache: $e');
    }
    
    return [];
  }
  
  /// Generate hash for a post to detect changes
  String _generatePostHash(Post post) {
    final content = '${post.id}_${post.title}_${post.likes?.length}_${post.comments?.length}_${post.updatedAt}';
    return md5.convert(utf8.encode(content)).toString();
  }
  
  /// Save posts to cache (both memory and disk)
  Future<void> savePosts(List<Post> posts, {bool isRefresh = false, int? lastPage, int? numberOfPages}) async {
    await init();
    
    if (posts.isEmpty) return;
    
    try {
      List<Post> postsToSave;
      
      if (isRefresh) {
        // On refresh, replace all posts
        postsToSave = posts.take(_maxCachedPosts).toList();
      } else {
        // On pagination, merge with existing
        final existing = await getCachedPosts();
        final existingIds = existing.map((p) => p.id).toSet();
        
        // Add new posts that don't exist
        final newPosts = posts.where((p) => !existingIds.contains(p.id)).toList();
        postsToSave = [...existing, ...newPosts].take(_maxCachedPosts).toList();
      }
      
      // Update memory cache
      _memoryCache = postsToSave;
      
      // Update metadata
      _metadata!['lastSync'] = DateTime.now().millisecondsSinceEpoch;
      _metadata!['totalPosts'] = postsToSave.length;
      if (lastPage != null) _metadata!['lastPage'] = lastPage;
      if (numberOfPages != null) _metadata!['numberOfPages'] = numberOfPages;
      
      // Generate hashes for change detection
      final hashes = <String, String>{};
      for (final post in postsToSave) {
        hashes[post.id.toString()] = _generatePostHash(post);
      }
      _metadata!['postHashes'] = hashes;
      
      // Save to disk asynchronously (don't block UI)
      _saveToDisk(postsToSave);
      
      debugPrint('📦 Cached ${postsToSave.length} posts');
    } catch (e) {
      debugPrint('❌ Error saving cache: $e');
    }
  }
  
  /// Save to disk in background using isolate
  Future<void> _saveToDisk(List<Post> posts) async {
    try {
      final file = await _cacheFile;
      final jsonList = posts.map((p) => p.toJson()).toList();
      // Encode JSON in isolate to prevent UI jank
      final jsonString = await compute(_encodePostsToJson, jsonList);
      await file.writeAsString(jsonString);
      await _saveMetadata();
      debugPrint('💾 Saved ${posts.length} posts to disk (isolate)');
    } catch (e) {
      debugPrint('❌ Error writing to disk: $e');
    }
  }
  
  /// Update a single post in cache (for likes, comments, etc.)
  Future<void> updatePost(Post updatedPost) async {
    await init();
    
    if (_memoryCache == null) {
      await getCachedPosts();
    }
    
    if (_memoryCache != null) {
      final index = _memoryCache!.indexWhere((p) => p.id == updatedPost.id);
      if (index >= 0) {
        _memoryCache![index] = updatedPost;
        
        // Update hash
        final hashes = Map<String, String>.from(_metadata!['postHashes'] ?? {});
        hashes[updatedPost.id.toString()] = _generatePostHash(updatedPost);
        _metadata!['postHashes'] = hashes;
        
        // Save to disk asynchronously
        _saveToDisk(_memoryCache!);
      }
    }
  }
  
  /// Remove a post from cache
  Future<void> removePost(int postId) async {
    await init();
    
    if (_memoryCache == null) {
      await getCachedPosts();
    }
    
    if (_memoryCache != null) {
      _memoryCache!.removeWhere((p) => p.id == postId);
      
      // Remove hash
      final hashes = Map<String, String>.from(_metadata!['postHashes'] ?? {});
      hashes.remove(postId.toString());
      _metadata!['postHashes'] = hashes;
      
      // Save to disk asynchronously
      _saveToDisk(_memoryCache!);
    }
  }
  
  /// Add a new post to the beginning of cache
  Future<void> addPost(Post newPost) async {
    await init();
    
    if (_memoryCache == null) {
      await getCachedPosts();
    }
    
    _memoryCache ??= [];
    
    // Add to beginning
    _memoryCache!.insert(0, newPost);
    
    // Trim if over limit
    if (_memoryCache!.length > _maxCachedPosts) {
      _memoryCache = _memoryCache!.take(_maxCachedPosts).toList();
    }
    
    // Update hash
    final hashes = Map<String, String>.from(_metadata!['postHashes'] ?? {});
    hashes[newPost.id.toString()] = _generatePostHash(newPost);
    _metadata!['postHashes'] = hashes;
    
    // Save to disk asynchronously
    _saveToDisk(_memoryCache!);
  }
  
  /// Check if a post has changed (using hash comparison)
  bool hasPostChanged(Post post) {
    if (_metadata == null) return true;
    
    final hashes = Map<String, String>.from(_metadata!['postHashes'] ?? {});
    final storedHash = hashes[post.id.toString()];
    
    if (storedHash == null) return true;
    
    return storedHash != _generatePostHash(post);
  }
  
  /// Get posts that have changed between cached and new data
  List<Post> getChangedPosts(List<Post> newPosts) {
    if (_metadata == null || _memoryCache == null) return newPosts;
    
    final hashes = Map<String, String>.from(_metadata!['postHashes'] ?? {});
    
    return newPosts.where((post) {
      final storedHash = hashes[post.id.toString()];
      if (storedHash == null) return true; // New post
      return storedHash != _generatePostHash(post); // Changed post
    }).toList();
  }
  
  /// Clear all cache
  Future<void> clearCache() async {
    _memoryCache = null;
    _metadata = {
      'lastSync': 0,
      'totalPosts': 0,
      'lastPage': 1,
      'numberOfPages': 1,
      'postHashes': <String, String>{},
    };
    
    try {
      final file = await _cacheFile;
      if (await file.exists()) {
        await file.delete();
      }
      await _saveMetadata();
      debugPrint('🗑️ Cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedPosts': _memoryCache?.length ?? 0,
      'lastSync': lastSyncTime?.toIso8601String(),
      'isValid': isCacheValid,
      'maxPosts': _maxCachedPosts,
    };
  }
}
