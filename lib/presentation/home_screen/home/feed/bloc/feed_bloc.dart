import 'dart:async';

import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/cache/feed_cache_service.dart';
import 'package:doctak_app/data/cache/post_cache_service.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/adapters/post_feed_adapter.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_module_enricher.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/reaction_picker.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ──────────────────────────────────────────────────────────

abstract class FeedEvent {
  const FeedEvent();
}

/// Initial load or pull-to-refresh (resets cursor).
class FeedLoadRequested extends FeedEvent {
  final bool refresh;
  const FeedLoadRequested({this.refresh = false});
}

/// Load the next page using the stored cursor.
class FeedLoadMoreRequested extends FeedEvent {
  const FeedLoadMoreRequested();
}

/// Background first-page enrich (case/survey modules) — separate handler so emit stays valid after await.
class FeedEnrichFirstPageRequested extends FeedEvent {
  final int generation;
  const FeedEnrichFirstPageRequested(this.generation);
}

// ─── States ──────────────────────────────────────────────────────────

abstract class FeedState {
  const FeedState();
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedEmpty extends FeedState {
  const FeedEmpty();
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
}

class FeedLoaded extends FeedState {
  final List<FeedEntry> entries;
  final bool hasMore;
  final bool isPaginating;

  const FeedLoaded({
    required this.entries,
    required this.hasMore,
    this.isPaginating = false,
  });

  FeedLoaded copyWith({
    List<FeedEntry>? entries,
    bool? hasMore,
    bool? isPaginating,
  }) {
    return FeedLoaded(
      entries: entries ?? this.entries,
      hasMore: hasMore ?? this.hasMore,
      isPaginating: isPaginating ?? this.isPaginating,
    );
  }
}

// ─── Bloc ────────────────────────────────────────────────────────────

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final SharedApiService _api = SharedApiService();
  final FeedCacheService _feedCache = FeedCacheService();
  final PostCacheService _postCache = PostCacheService();

  final List<FeedEntry> _entries = [];
  final Set<String> _seenKeys = {};
  String? _cursor;
  bool _hasMore = true;
  bool _isFetching = false;
  int _firstPageSnapshotSize = 0;
  int _enrichGeneration = 0;
  bool _showOfflineBanner = false;

  static const int _pageLimit = 20;
  static const int _maxApiAttempts = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// True while the first page is still loading (no cached rows yet).
  bool get showInitialShimmer =>
      state is FeedInitial ||
      (state is FeedLoading && _entries.isEmpty);

  /// Shown when feed rows come from cache after API failures.
  bool get showOfflineBanner => _showOfflineBanner;

  FeedBloc() : super(const FeedInitial()) {
    on<FeedLoadRequested>(_onLoad);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<FeedEnrichFirstPageRequested>(_onEnrichFirstPage);
  }

  bool get canLoadMore => _hasMore && !_isFetching;

  bool _resolveHasMore(FeedResponse data) {
    return data.hasMore ||
        (data.nextCursor != null && data.nextCursor!.isNotEmpty);
  }

  Future<bool> _restoreFromFeedCache() async {
    final snapshot = await _feedCache.getCachedFeed();
    if (snapshot == null || snapshot.entries.isEmpty) return false;

    _entries.clear();
    _seenKeys.clear();
    _appendUnique(snapshot.entries);
    _cursor = snapshot.nextCursor;
    _hasMore = snapshot.hasMore;
    return true;
  }

  Future<bool> _restoreFromPostCache() async {
    final posts = await _postCache.getCachedPosts();
    if (posts.isEmpty) return false;

    _entries.clear();
    _seenKeys.clear();
    for (final post in posts) {
      _appendUnique([FeedEntry.itemEntry(PostFeedAdapter.fromPost(post))]);
    }
    _cursor = null;
    _hasMore = false;
    return true;
  }

  Future<bool> _restoreFromAnyCache() async {
    if (await _restoreFromFeedCache()) return true;
    return _restoreFromPostCache();
  }

  Future<ApiResponse<FeedResponse>> _fetchFirstPageWithRetries() async {
    ApiResponse<FeedResponse> lastRes =
        ApiResponse.error('Failed to load feed');
    for (var attempt = 0; attempt < _maxApiAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_retryDelay);
      }
      lastRes = await _api.getHomeFeed(limit: _pageLimit, initial: true);
      if (lastRes.success && lastRes.data != null) {
        return lastRes;
      }
    }
    return lastRes;
  }

  void _emitLoaded(Emitter<FeedState> emit, {bool paginating = false}) {
    if (_entries.isEmpty) {
      emit(const FeedEmpty());
      return;
    }
    emit(FeedLoaded(
      entries: List.unmodifiable(_entries),
      hasMore: _hasMore,
      isPaginating: paginating,
    ));
  }

  Future<void> _onLoad(FeedLoadRequested event, Emitter<FeedState> emit) async {
    if (_isFetching) return;

    final isRefresh = event.refresh;
    final hadEntries = _entries.isNotEmpty;

    if (isRefresh) {
      _cursor = null;
      _hasMore = true;
      _firstPageSnapshotSize = 0;
      _enrichGeneration++;
      resetFeedTopReactionsCache();
    } else if (_entries.isEmpty) {
      final showedCache = await _restoreFromAnyCache();
      if (showedCache) {
        _emitLoaded(emit);
      } else {
        emit(const FeedLoading());
      }
    }

    _isFetching = true;
    final res = await _fetchFirstPageWithRetries();
    _isFetching = false;

    if (!res.success || res.data == null) {
      if (isRefresh && hadEntries) {
        _showOfflineBanner = true;
        _emitLoaded(emit);
        return;
      }
      if (_entries.isEmpty) {
        if (await _restoreFromAnyCache()) {
          _showOfflineBanner = true;
          _emitLoaded(emit);
        } else {
          emit(const FeedError('No Internet connection. Please try again.'));
        }
      }
      return;
    }

    final data = res.data!;
    final incoming = data.entries;

    _showOfflineBanner = false;
    _entries.clear();
    _seenKeys.clear();
    _appendUnique(incoming);
    _cursor = data.nextCursor;
    _hasMore = _resolveHasMore(data);

    _emitLoaded(emit);

    unawaited(_feedCache.saveFeed(
      entries: _entries,
      nextCursor: _cursor,
      hasMore: _hasMore,
      replace: true,
    ));

    // Server `initial=1` + ensureModuleVisibility inject case/survey modules;
    // skip client enrich to avoid a second heavy feed build.
  }

  /// Injects case/survey modules into the first page only — never touches paginated tail rows.
  Future<void> _onEnrichFirstPage(
    FeedEnrichFirstPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    final generation = event.generation;
    if (generation != _enrichGeneration) return;

    final snapshotSize = _firstPageSnapshotSize;
    if (snapshotSize <= 0 || _entries.isEmpty) return;

    // User already loaded page 2+ — skip so we don't rewrite or truncate the list.
    if (_entries.length > snapshotSize) return;

    final pageCopy = List<FeedEntry>.from(_entries.take(snapshotSize));
    final enriched = await FeedModuleEnricher.enrich(pageCopy, _api);

    if (isClosed ||
        generation != _enrichGeneration ||
        _entries.length > snapshotSize) {
      return;
    }

    final pageKeys = pageCopy.map((e) => e.dedupeKey).toSet();
    final hasNew =
        enriched.any((entry) => !pageKeys.contains(entry.dedupeKey));
    final orderChanged = enriched.length != pageCopy.length ||
        enriched.asMap().entries.any(
              (e) =>
                  e.key >= pageCopy.length ||
                  pageCopy[e.key].dedupeKey != e.value.dedupeKey,
            );
    if (!hasNew && !orderChanged) return;

    final keysBefore = _entries.map((e) => e.dedupeKey).toList();

    for (final key in pageKeys) {
      _seenKeys.remove(key);
    }
    _entries.removeRange(0, snapshotSize);
    _entries.insertAll(0, enriched);
    for (final entry in enriched) {
      _seenKeys.add(entry.dedupeKey);
    }

    if (isClosed || _entries.isEmpty) return;

    final keysAfter = _entries.map((e) => e.dedupeKey).toList();
    if (keysBefore.length == keysAfter.length) {
      var unchanged = true;
      for (var i = 0; i < keysBefore.length; i++) {
        if (keysBefore[i] != keysAfter[i]) {
          unchanged = false;
          break;
        }
      }
      if (unchanged) return;
    }

    final paginating =
        state is FeedLoaded ? (state as FeedLoaded).isPaginating : false;
    emit(FeedLoaded(
      entries: List.unmodifiable(_entries),
      hasMore: _hasMore,
      isPaginating: paginating,
    ));

    unawaited(_feedCache.saveFeed(
      entries: _entries,
      nextCursor: _cursor,
      hasMore: _hasMore,
      replace: true,
    ));
  }

  Future<void> _onLoadMore(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (_isFetching || !_hasMore) return;
    if (_cursor == null || _cursor!.isEmpty) return;

    _isFetching = true;

    if (state is FeedLoaded) {
      emit((state as FeedLoaded).copyWith(isPaginating: true));
    }

    final ApiResponse<FeedResponse> res =
        await _api.getHomeFeed(cursor: _cursor, limit: _pageLimit);
    _isFetching = false;

    if (!res.success || res.data == null) {
      if (state is FeedLoaded) {
        emit((state as FeedLoaded).copyWith(isPaginating: false));
      }
      return;
    }

    final data = res.data!;
    final beforeCount = _entries.length;
    _appendUnique(data.entries);
    _cursor = data.nextCursor;
    _hasMore = _resolveHasMore(data);

    if (data.entries.isEmpty) {
      _hasMore = false;
    } else if (_entries.length == beforeCount) {
      _hasMore = false;
    }

    emit(FeedLoaded(
      entries: List.unmodifiable(_entries),
      hasMore: _hasMore,
      isPaginating: false,
    ));

    unawaited(_feedCache.saveFeed(
      entries: _entries,
      nextCursor: _cursor,
      hasMore: _hasMore,
    ));
  }

  void _appendUnique(List<FeedEntry> incoming) {
    for (final entry in incoming) {
      final key = entry.dedupeKey;
      if (_seenKeys.contains(key)) continue;
      _seenKeys.add(key);
      _entries.add(entry);
    }
  }
}
