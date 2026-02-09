import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/cache/post_cache_service.dart';
import 'package:doctak_app/data/repository/post_repository.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

part 'home_event.dart';
part 'home_state.dart';

/// HomeBloc with LinkedIn-style offline-first architecture
/// Features:
/// - Instant loading from cache
/// - Background sync with API
/// - Optimistic updates for likes
/// - Automatic retry on network restoration
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  final PostRepository _postRepository = PostRepository();
  final PostCacheService _cacheService = PostCacheService();

  int pageNumber = 1;
  int numberOfPage = 1;
  List<Post> postList = [];
  final int nextPageTrigger = 1;
  var postData;

  // Connectivity monitoring for auto-retry
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<List<Post>>? _postsStreamSubscription;

  // Rate limiting variables to prevent rapid API calls
  DateTime? _lastApiCallTime;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _minTimeBetweenRetries = Duration(seconds: 5);
  static const Duration _cooldownAfterFailures = Duration(seconds: 30);
  bool _isInCooldown = false;
  Timer? _cooldownTimer;

  // Track offline state
  bool _isOfflineMode = false;
  String? _lastErrorMessage;

  // Track if pagination is currently loading to prevent duplicate requests
  bool _isLoadingPage = false;

  HomeBloc() : super(DataInitial()) {
    on<PostLoadPageEvent>(_onGetPosts);
    on<LoadSearchPageEvent>(_onGetSearchPosts);
    on<AdsSettingEvent>(_adsSettingApi);
    on<PostLikeEvent>(_onPostLike);
    on<DeletePostEvent>(_onDeletePost);
    on<DetailsPostEvent>(_onGetDetailsPosts);
    on<RefreshPostsEvent>(_onRefreshPosts);
    on<UpdatePostsFromCacheEvent>(_onUpdatePostsFromCache);
    on<ManualRetryEvent>(_onManualRetry);
    on<PostCheckIfNeedMoreDataEvent>((event, emit) async {
      // Don't trigger pagination when:
      // 1. Already loading a page (prevents duplicate requests)
      // 2. In cooldown mode (offline/error state)
      // 3. Already loaded all pages
      if (_isLoadingPage) return;
      if (_isInCooldown) return;
      if (pageNumber > numberOfPage) return;

      if (event.index == postList.length - nextPageTrigger) {
        add(PostLoadPageEvent(page: pageNumber));
      }
    });

    // Start listening for connectivity changes to auto-retry pending likes
    _startConnectivityMonitoring();

    // Listen for cache updates from repository
    _listenForCacheUpdates();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Don't process if bloc is closed
      if (isClosed) return;

      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasConnection) {
        if (_pendingLikeRequests.isNotEmpty) {
          // Silently retry pending likes
          retryPendingLikeRequests();
        }
      }
    });
  }

  void _listenForCacheUpdates() {
    _postsStreamSubscription = _postRepository.postsStream.listen((posts) {
      // Only update if we have posts and the state is appropriate
      if (posts.isNotEmpty && !isClosed) {
        // Use Future.microtask to ensure we're not in a closed state
        Future.microtask(() {
          if (!isClosed) {
            add(UpdatePostsFromCacheEvent(posts: posts));
          }
        });
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _postsStreamSubscription?.cancel();
    _cooldownTimer?.cancel();
    return super.close();
  }

  /// Check if we should allow an API call (rate limiting only during failures)
  bool _shouldAllowApiCall() {
    // If in cooldown, don't allow
    if (_isInCooldown) {
      debugPrint('🚫 API call blocked: In cooldown mode');
      return false;
    }

    // Only apply time check if there have been recent failures
    if (_consecutiveFailures > 0 && _lastApiCallTime != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCallTime!);
      if (timeSinceLastCall < _minTimeBetweenRetries) {
        debugPrint(
          '🚫 API call blocked: Too soon after failure (${timeSinceLastCall.inSeconds}s < ${_minTimeBetweenRetries.inSeconds}s)',
        );
        return false;
      }
    }

    return true;
  }

  /// Record a successful API call
  void _recordApiSuccess() {
    _lastApiCallTime = DateTime.now();
    _consecutiveFailures = 0;
    _isOfflineMode = false;
    _lastErrorMessage = null;
    _isInCooldown = false;
    _cooldownTimer?.cancel();
  }

  /// Record a failed API call and start cooldown if needed
  void _recordApiFailure(String errorMessage) {
    _lastApiCallTime = DateTime.now();
    _consecutiveFailures++;
    _lastErrorMessage = errorMessage;

    debugPrint('❌ API failure #$_consecutiveFailures: $errorMessage');

    // Start cooldown after max consecutive failures
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _startCooldown();
    }
  }

  /// Start cooldown period to prevent hammering the server
  void _startCooldown() {
    if (_isInCooldown) return;

    _isInCooldown = true;
    _isOfflineMode = true;
    debugPrint(
      '⏳ Starting ${_cooldownAfterFailures.inSeconds}s cooldown after $_consecutiveFailures failures',
    );

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_cooldownAfterFailures, () {
      if (!isClosed) {
        _isInCooldown = false;
        // Don't auto-retry, let user manually retry
        debugPrint('✅ Cooldown ended. User can retry manually.');
      }
    });
  }

  /// Reset rate limiting state (called on manual retry)
  void _resetRateLimiting() {
    _consecutiveFailures = 0;
    _isInCooldown = false;
    _cooldownTimer?.cancel();
    _lastApiCallTime = null;
  }

  /// Handle manual retry from user
  Future<void> _onManualRetry(
    ManualRetryEvent event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('🔄 Manual retry triggered by user');
    _resetRateLimiting();
    _isOfflineMode = false;
    pageNumber = 1;
    add(PostLoadPageEvent(page: 1));
  }

  Future<void> _onUpdatePostsFromCache(
    UpdatePostsFromCacheEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Simply emit the loaded state - postList is already updated
    emit(PostPaginationLoadedState());
  }

  /// Check if posts have actually changed
  bool _hasPostsChanged(List<Post> newPosts) {
    if (postList.isEmpty) return true;
    if (newPosts.length != postList.length) return true;

    // Check first 5 posts for changes
    for (int i = 0; i < newPosts.length.clamp(0, 5); i++) {
      final newPost = newPosts[i];
      final existingIndex = postList.indexWhere((p) => p.id == newPost.id);

      if (existingIndex < 0) return true;

      final existing = postList[existingIndex];
      if (existing.likes?.length != newPost.likes?.length ||
          existing.comments?.length != newPost.comments?.length) {
        return true;
      }
    }

    return false;
  }

  /// Main posts loading with cache-first strategy and rate limiting
  Future<void> _onGetPosts(
    PostLoadPageEvent event,
    Emitter<HomeState> emit,
  ) async {
    final isFirstPage = event.page == 1;

    // Prevent duplicate pagination requests
    if (!isFirstPage && _isLoadingPage) {
      debugPrint('🚫 Pagination blocked: Already loading page');
      return;
    }

    // Set loading flag for pagination
    if (!isFirstPage) {
      _isLoadingPage = true;
    }

    if (isFirstPage) {
      pageNumber = 1;
      _isLoadingPage = false; // Reset for first page

      // Show loading state first (don't clear postList yet to avoid flicker)
      emit(PostPaginationLoadingState());

      // Try loading from cache first for instant display
      final cachedPosts = await _cacheService.getCachedPosts();

      if (cachedPosts.isNotEmpty) {
        postList = cachedPosts;

        // If in offline mode, show cached data with retry banner
        if (_isOfflineMode) {
          emit(
            PostOfflineWithCacheState(
              errorMessage: _lastErrorMessage ?? 'Unable to connect to server',
            ),
          );
          return;
        }

        emit(PostPaginationLoadedState());

        // Fetch fresh data in background (don't await) - only if not in cooldown
        if (!_isInCooldown) {
          _fetchPostsInBackground();
        }
        return;
      }

      // No cache available - clear and continue to API fetch
      postList.clear();
    } else {
      // For pagination, only check rate limiting if there have been failures
      if (_consecutiveFailures > 0 && !_shouldAllowApiCall()) {
        _isLoadingPage = false;
        // Don't emit error for pagination, just silently ignore
        return;
      }

      // Emit pagination loading state (shows loading indicator at bottom, doesn't block UI)
      if (postList.isNotEmpty) {
        emit(PostPaginationLoadedState(isPaginationLoading: true));
      }
    }

    // Fetch from API
    try {
      var response1 = await apiManager.getPosts(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
      );
      final response = PostDataModel.fromJson(response1.response.data!);

      if (response1.response.statusCode == 302) {
        _isLoadingPage = false;
        _recordApiFailure('Session error');
        if (postList.isNotEmpty) {
          emit(
            PostOfflineWithCacheState(
              errorMessage: 'Session expired. Please try again.',
            ),
          );
        } else {
          emit(PostDataError('An error occurred'));
        }
        return;
      }

      // API call succeeded - reset failure counter
      _recordApiSuccess();

      numberOfPage = response.posts?.lastPage ?? 0;
      final newPosts = response.posts?.data ?? [];

      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;

        if (isFirstPage) {
          postList = newPosts;
        } else {
          postList.addAll(newPosts);
        }
      }

      // Save to cache (only first page for now)
      if (isFirstPage && newPosts.isNotEmpty) {
        await _cacheService.savePosts(
          newPosts,
          isRefresh: true,
          lastPage: pageNumber,
          numberOfPages: numberOfPage,
        );
      }

      // Emit appropriate state based on posts
      if (postList.isEmpty && isFirstPage) {
        emit(PostsEmptyState());
      } else {
        emit(PostPaginationLoadedState());
      }

      // Clear loading flag after successful load
      _isLoadingPage = false;
    } catch (e) {
      // Clear loading flag on error
      _isLoadingPage = false;

      final errorMessage = _parseErrorMessage(e);
      _recordApiFailure(errorMessage);

      // If we have cached data, show it with offline banner (LinkedIn-style)
      if (postList.isNotEmpty) {
        emit(PostOfflineWithCacheState(errorMessage: errorMessage));
      } else {
        // No cached data - show full error with retry
        emit(PostDataError(errorMessage));
      }
    }
  }

  /// Parse error message to user-friendly format
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network is unreachable')) {
      return 'No internet connection';
    } else if (errorStr.contains('timeout')) {
      return 'Connection timed out';
    } else if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504')) {
      return 'Server is temporarily unavailable';
    } else if (errorStr.contains('429') ||
        errorStr.contains('too many requests')) {
      return 'Too many requests. Please wait a moment.';
    } else {
      return 'Unable to load posts. Please try again.';
    }
  }

  Future<void> _fetchPostsInBackground() async {
    try {
      // Check if bloc is closed before starting
      if (isClosed) return;

      var response1 = await apiManager.getPosts(
        'Bearer ${AppData.userToken}',
        '1',
      );

      // Check again after async operation
      if (isClosed) return;

      final response = PostDataModel.fromJson(response1.response.data!);

      if (response1.response.statusCode == 302) {
        return;
      }

      final newPosts = response.posts?.data ?? [];
      numberOfPage = response.posts?.lastPage ?? 0;
      pageNumber = 2; // Reset to page 2 for next load

      // Check if data actually changed
      if (_hasPostsChanged(newPosts)) {
        postList = newPosts;

        // Save to cache
        await _cacheService.savePosts(
          newPosts,
          isRefresh: true,
          lastPage: pageNumber,
          numberOfPages: numberOfPage,
        );

        // Use add() to trigger event instead of emit() directly
        // This is the proper way to update state from outside event handlers
        if (!isClosed) {
          add(UpdatePostsFromCacheEvent(posts: newPosts));
        }
      } else {
        // Fresh data is same as cached, no UI update needed
      }
    } catch (e) {
      // Don't show error - we already have cached data displayed
    }
  }

  Future<void> _onRefreshPosts(
    RefreshPostsEvent event,
    Emitter<HomeState> emit,
  ) async {
    pageNumber = 1;
    add(PostLoadPageEvent(page: 1));
  }

  Future<void> _onGetDetailsPosts(
    DetailsPostEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(PostPaginationLoadingState());

    try {
      if (event.commentId != 0) {
        print(event.commentId);
        postData = await apiManager.getDetailsPosts(
          'Bearer ${AppData.userToken}',
          event.commentId.toString(),
        );
      } else {
        postData = await apiManager.getDetailsLikesPosts(
          'Bearer ${AppData.userToken}',
          event.postId.toString(),
        );
      }
      print('post $postData');
      emit(PostPaginationLoadedState());
    } catch (e) {
      print(e);

      // emit(PostPaginationLoadedState());
      emit(PostDataError('An error occurred $e'));
    }
  }

  Future<void> _onGetSearchPosts(
    LoadSearchPageEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PostPaginationLoadingState());
    }
    try {
      PostDataModel response = await apiManager.getSearchPostList(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
        event.search ?? '',
      );
      print(response.toJson());
      numberOfPage = response.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(response.posts?.data ?? []);
      }
      emit(PostPaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);
      // emit(PostPaginationLoadedState());

      emit(PostDataError('An error occurred $e'));
    }
  }

  Future<void> _onPostLike(PostLikeEvent event, Emitter<HomeState> emit) async {
    // Find the post in the list
    int index = postList.indexWhere(
      (element) => element.id.toString() == event.postId.toString(),
    );

    if (index < 0) {
      print('⚠️ Post not found in list: ${event.postId}');
      return;
    }

    // Determine current like state
    bool wasLiked = postList[index].likes!
        .where(
          (element) =>
              element.userId.toString() == AppData.logInUserId.toString(),
        )
        .isNotEmpty;

    print(
      '👍 Optimistic like/unlike for post ${event.postId}, wasLiked: $wasLiked',
    );

    // OPTIMISTIC UPDATE: Update UI immediately
    if (wasLiked) {
      // Remove like optimistically
      postList[index].likes!.removeWhere(
        (element) =>
            element.userId.toString() == AppData.logInUserId.toString(),
      );
    } else {
      // Add like optimistically
      postList[index].likes!.add(
        Likes(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          userId: AppData.logInUserId,
          postId: event.postId.toString(),
        ),
      );
    }

    // Emit state immediately for instant UI feedback
    emit(PostPaginationLoadedState());

    // Now make the API call in the background
    try {
      var response = await apiManager.like(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
      );
      print('✅ Like API success: ${response.data}');

      // API succeeded - UI already reflects correct state
      // Optionally emit again to ensure consistency
      emit(PostPaginationLoadedState());
    } catch (e) {
      print('❌ Like API failed: $e');

      // ROLLBACK: Revert the optimistic update on failure
      int currentIndex = postList.indexWhere(
        (element) => element.id.toString() == event.postId.toString(),
      );

      if (currentIndex >= 0) {
        if (wasLiked) {
          // Restore the like
          postList[currentIndex].likes!.add(
            Likes(
              id: 1,
              userId: AppData.logInUserId,
              postId: event.postId.toString(),
            ),
          );
        } else {
          // Remove the optimistic like
          postList[currentIndex].likes!.removeWhere(
            (element) =>
                element.userId.toString() == AppData.logInUserId.toString(),
          );
        }

        // Emit state with rolled-back data
        emit(PostPaginationLoadedState());

        // Queue for retry if it's a network error
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('Network') ||
            e.toString().contains('Connection')) {
          print('📝 Queuing like request for retry when network returns');
          _queueFailedLikeRequest(event.postId.toString(), !wasLiked);
        }
      }
    }
  }

  // Queue for failed like requests (simple in-memory queue)
  final Map<String, bool> _pendingLikeRequests = {};

  void _queueFailedLikeRequest(String postId, bool shouldLike) {
    _pendingLikeRequests[postId] = shouldLike;
    print('📋 Pending like requests: ${_pendingLikeRequests.length}');
  }

  // Method to retry pending like requests (can be called when network returns)
  Future<void> retryPendingLikeRequests() async {
    if (_pendingLikeRequests.isEmpty || isClosed) return;

    print('🔄 Retrying ${_pendingLikeRequests.length} pending like requests');
    final requestsCopy = Map<String, bool>.from(_pendingLikeRequests);

    for (var entry in requestsCopy.entries) {
      // Check if bloc is closed before each retry
      if (isClosed) return;

      try {
        await apiManager.like('Bearer ${AppData.userToken}', entry.key);
        print('✅ Retry successful for post ${entry.key}');
        _pendingLikeRequests.remove(entry.key);
      } catch (e) {
        print('❌ Retry failed for post ${entry.key}: $e');
        // Keep in queue for next retry
      }
    }
  }

  Future<void> _onDeletePost(
    DeletePostEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Find the post index
    final postIndex = postList.indexWhere(
      (element) => element.id == event.postId,
    );

    if (postIndex < 0) {
      debugPrint('⚠️ Post not found for deletion: ${event.postId}');
      return;
    }

    // Store the post for potential rollback
    final deletedPost = postList[postIndex];

    // OPTIMISTIC UPDATE: Remove from UI immediately
    postList.removeAt(postIndex);
    emit(PostPaginationLoadedState());
    debugPrint('🗑️ Post ${event.postId} removed from UI optimistically');

    // Remove from local cache immediately
    await _cacheService.removePost(event.postId ?? 0);
    debugPrint('🗑️ Post ${event.postId} removed from local cache');

    // Now make the API call in background
    try {
      var response = await apiManager.deletePost(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
      );
      debugPrint('✅ Delete API success: ${response.data}');
    } catch (e) {
      debugPrint('❌ Delete API failed: $e');

      // ROLLBACK: Restore the post on failure
      if (!isClosed) {
        // Insert back at original position or at start if position is invalid
        final insertIndex = postIndex.clamp(0, postList.length);
        postList.insert(insertIndex, deletedPost);

        // Restore to cache
        await _cacheService.updatePost(deletedPost);

        emit(PostPaginationLoadedState());
        debugPrint(
          '🔄 Rollback: Post ${event.postId} restored after API failure',
        );
      }
    }
  }

  Future<void> _adsSettingApi(
    AdsSettingEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      AppData.adsSettingModel = await apiManager.advertisementSetting(
        'Bearer ${AppData.userToken}',
      );
      AppData.listAdsType = await apiManager.advertisementTypes(
        'Bearer ${AppData.userToken}',
      );

      // banner ads
      AppData.isShowGoogleBannerAds =
          (AppData.listAdsType
              .where(
                (element) =>
                    element.type == 'banner' && element.provider == 'Google',
              )
              .isNotEmpty) &&
          ((AppData.adsSettingModel.data
                  ?.where(
                    (element) =>
                        element.advertisementType == 'banner' &&
                        element.provider == 'Google' &&
                        element.isAdvertisementOn == 1,
                  )
                  .isNotEmpty ??
              false));
      AppData.androidBannerAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'banner' && element.provider == 'Google',
          )
          .firstOrNull
          ?.androidId;
      AppData.iosBannerAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'banner' && element.provider == 'Google',
          )
          .firstOrNull
          ?.iosId;
      // native ads
      AppData.isShowGoogleNativeAds =
          (AppData.listAdsType
              .where(
                (element) =>
                    element.type == 'native' && element.provider == 'Google',
              )
              .isNotEmpty) &&
          ((AppData.adsSettingModel.data
                  ?.where(
                    (element) =>
                        element.advertisementType == 'native' &&
                        element.provider == 'Google' &&
                        element.isAdvertisementOn == 1,
                  )
                  .isNotEmpty ??
              false));
      AppData.androidNativeAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'native' && element.provider == 'Google',
          )
          .firstOrNull
          ?.androidId;
      AppData.iosNativeAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'native' && element.provider == 'Google',
          )
          .firstOrNull
          ?.iosId;
    } catch (e) {
      // Silently handle ads loading errors
    }
  }

  //  _onGetPosts1(GetPost event, Emitter<HomeState> emit) async {
  //   emit(DataInitial());
  //   // ProgressDialogUtils.showProgressDialog();
  //   try {
  //     final response = await postService.getPosts(
  //         'Bearer ${AppData.userToken}',
  //         '1');
  //     // if (response.==true) {
  //     //   ProgressDialogUtils.hideProgressDialog();
  //       emit(DataLoaded(response));
  //     // } else {
  //     //   ProgressDialogUtils.hideProgressDialog();
  //     //   emit(LoginFailure(error: 'Invalid credentials'));
  //     // }
  //   } catch (e) {
  //     print(e);
  //     emit(DataError('An error occurred'));
  //   }
  // }
}
