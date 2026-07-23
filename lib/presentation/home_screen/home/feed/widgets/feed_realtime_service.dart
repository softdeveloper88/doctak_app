import 'dart:async';
import 'dart:developer';

import 'package:doctak_app/core/network/network_utils.dart' as network_utils;
import 'package:doctak_app/data/services/notifications_websocket_service.dart';
import 'package:flutter/foundation.dart';

/// Tracks new home-feed posts via UserChannel WebSocket + `/api/feed/new-since`
/// polling (same dual path as the website).
class FeedRealtimeService {
  FeedRealtimeService._();
  static final FeedRealtimeService instance = FeedRealtimeService._();

  static const Duration _pollInterval = Duration(seconds: 20);
  static const Duration _initialPollDelay = Duration(seconds: 5);

  final ValueNotifier<int> pendingCount = ValueNotifier(0);
  final Set<String> _pendingPostIds = {};
  final Set<String> _seenPostIds = {};
  static const int _maxSeen = 200;

  StreamSubscription<NotificationWsEvent>? _wsSub;
  Timer? _pollTimer;
  Timer? _initialPollTimer;
  bool _active = false;
  bool _polling = false;
  DateTime _sinceUtc = DateTime.now().toUtc();

  bool get hasPending => _pendingPostIds.isNotEmpty;

  void start() {
    if (_active) return;
    _active = true;
    _sinceUtc = DateTime.now().toUtc();

    unawaited(NotificationsWebSocketService().connect());
    _wsSub?.cancel();
    _wsSub = NotificationsWebSocketService().events.listen(_onWsEvent);

    _initialPollTimer?.cancel();
    _initialPollTimer = Timer(_initialPollDelay, () {
      if (!_active) return;
      unawaited(_pollNewSince());
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(_pollInterval, (_) {
        if (!_active) return;
        unawaited(_pollNewSince());
      });
    });
  }

  void stop() {
    _active = false;
    onPostUpdated = null;
    onPostDeleted = null;
    _wsSub?.cancel();
    _wsSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _initialPollTimer?.cancel();
    _initialPollTimer = null;
  }

  void clearPending() {
    if (_pendingPostIds.isEmpty) return;
    _pendingPostIds.clear();
    _syncPendingCount();
  }

  void markFeedRefreshed() {
    _sinceUtc = DateTime.now().toUtc();
    clearPending();
  }

  void _onWsEvent(NotificationWsEvent event) {
    if (event is FeedPostArrived) {
      _registerPost(event.postId);
    } else if (event is FeedPostUpdated) {
      onPostUpdated?.call(event);
    } else if (event is FeedPostDeleted) {
      onPostDeleted?.call(event);
    }
  }

  /// Wired by [SVHomeFragment] to patch the visible home feed.
  void Function(FeedPostUpdated event)? onPostUpdated;

  /// Wired by [SVHomeFragment] to remove a post from the visible home feed.
  void Function(FeedPostDeleted event)? onPostDeleted;

  void _registerPost(String postId) {
    final id = postId.trim();
    if (id.isEmpty) return;
    if (_seenPostIds.contains(id)) return;
    _rememberSeen(id);

    if (_pendingPostIds.add(id)) {
      _syncPendingCount();
      log('FeedRealtimeService: new post pending ($id)');
    }
  }

  void _rememberSeen(String id) {
    _seenPostIds.add(id);
    if (_seenPostIds.length <= _maxSeen) return;
    final drop = _maxSeen ~/ 2;
    final toRemove = _seenPostIds.take(drop).toList();
    for (final removed in toRemove) {
      _seenPostIds.remove(removed);
    }
  }

  void _syncPendingCount() {
    pendingCount.value = _pendingPostIds.length;
  }

  Future<void> _pollNewSince() async {
    if (_polling || !_active) return;
    _polling = true;
    try {
      final since = _sinceUtc.toIso8601String();
      final response = await network_utils.handleResponse(
        await network_utils.buildHttpResponseNode(
          '/api/feed/new-since?since=${Uri.encodeQueryComponent(since)}&limit=10',
          method: network_utils.HttpMethod.GET,
        ),
      );

      if (response['success'] != true) return;

      final posts = response['posts'];
      if (posts is! List || posts.isEmpty) return;

      var latest = _sinceUtc;
      for (final raw in posts) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final id = (map['id'] ?? '').toString();
        if (id.isNotEmpty) _registerPost(id);

        final createdAt = map['createdAt']?.toString();
        if (createdAt != null && createdAt.isNotEmpty) {
          final parsed = DateTime.tryParse(createdAt);
          if (parsed != null && parsed.isAfter(latest)) {
            latest = parsed.toUtc();
          }
        }
      }
      _sinceUtc = latest;
    } catch (e) {
      log('FeedRealtimeService._pollNewSince: $e');
    } finally {
      _polling = false;
    }
  }

  void pollNow() {
    if (!_active) return;
    unawaited(_pollNewSince());
  }
}
