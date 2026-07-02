import 'dart:async';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/services/notifications_websocket_service.dart';

/// Singleton service that maintains the unread notification count
/// using real-time WebSocket events (doctak-node UserChannel) and
/// FCM push notifications, instead of periodic HTTP polling.
class NotificationCounterService {
  static final NotificationCounterService _instance =
      NotificationCounterService._internal();

  factory NotificationCounterService() => _instance;

  NotificationCounterService._internal();

  final _countController = StreamController<int>.broadcast();
  final NotificationsWebSocketService _ws = NotificationsWebSocketService();

  int _unreadCount = 0;
  bool _initialized = false;
  StreamSubscription<NotificationWsEvent>? _wsSub;

  Stream<int> get countStream => _countController.stream;

  int get unreadCount => _unreadCount;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await refreshFromServer();

    await _ws.connect();
    _wsSub = _ws.events.listen(_onWsEvent);
  }

  /// Fetch the latest unread count from the Node notifications API.
  Future<void> refreshFromServer() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/notifications/unread-count',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final counts = response['counts'];
      if (counts is Map) {
        final map = Map<String, dynamic>.from(counts);
        final bellCount = map['notifications'];
        _setCount(bellCount is num ? bellCount.toInt() : int.tryParse('$bellCount') ?? 0);
        return;
      }
      final count = response['unread_count'] ?? response['unreadCount'];
      _setCount(count is num ? count.toInt() : int.tryParse('$count') ?? 0);
    } catch (e) {
      // Fallback for older backends that only expose the paginated list endpoint.
      try {
        final dio = Dio();
        final response = await dio.get(
          '${AppData.nodeApiUrl}/api/v1/notifications/unread/count',
          options: Options(
            headers: {'Authorization': 'Bearer ${AppData.userToken}'},
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );
        final count = response.data['unread_count'] ?? response.data['unreadCount'];
        _setCount(count is num ? count.toInt() : int.tryParse('$count') ?? 0);
      } catch (_) {
        try {
          final dio = Dio();
          final response = await dio.get(
            '${AppData.nodeApiUrl}/api/v1/notifications?filter=unread&page=1',
            options: Options(
              headers: {'Authorization': 'Bearer ${AppData.userToken}'},
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
            ),
          );
          final notifications = response.data['notifications'];
          final count = notifications is Map ? notifications['total'] : null;
          _setCount(count is num ? count.toInt() : 0);
        } catch (_) {}
      }
    }
  }

  void increment() {
    _setCount(_unreadCount + 1);
  }

  void setCount(int count) {
    _setCount(count);
  }

  void reset() {
    _setCount(0);
  }

  void onFCMForegroundPush() {
    increment();
    // Reconcile with server so the list screen and badge stay in sync.
    unawaited(refreshFromServer());
  }

  void _onWsEvent(NotificationWsEvent event) {
    if (event is NotificationCountsUpdated) {
      _setCount(event.notifications);
      return;
    }

    if (event is NotificationNew) {
      final myId = AppData.logInUserId.toString();
      final payload = event.data;
      final notification = payload['notification'];
      if (notification is Map) {
        final map = Map<String, dynamic>.from(notification);
        final actor = map['actor'];
        final actorId = (map['actorId'] ??
                map['actor_id'] ??
                (actor is Map ? actor['id'] : null))
            ?.toString();
        if (myId.isNotEmpty && actorId != null && actorId == myId) {
          return;
        }
      }

      final unreadCount = payload['unreadCount'] ?? payload['unread_count'];
      if (unreadCount is num) {
        _setCount(unreadCount.toInt());
        return;
      }
      increment();
    }
  }

  void _setCount(int count) {
    if (count < 0) count = 0;
    _unreadCount = count;
    if (!_countController.isClosed) {
      _countController.add(count);
    }
  }

  void dispose() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws.disconnect();
    _initialized = false;
    _unreadCount = 0;
  }
}
