import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/notification_model/notification_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Notification API Service
/// Handles all notification related API calls via the Node `/api/v1/notifications` routes.
class NotificationApiService {
  static final NotificationApiService _instance = NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  /// Get all notifications
  Future<ApiResponse<NotificationModel>> getNotifications({required String page, String? filter}) async {
    try {
      final filterQuery = filter != null && filter.isNotEmpty ? '&filter=$filter' : '';
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications?page=$page$filterQuery',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(NotificationModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get notifications: $e');
    }
  }

  /// Get filtered notifications by read status
  Future<ApiResponse<NotificationModel>> getFilteredNotifications({
    required String page,
    required String readStatus, // "read", "unread", "all"
  }) async {
    final filter = readStatus == 'all' ? null : readStatus;
    return getNotifications(page: page, filter: filter);
  }

  /// Mark all notifications as read
  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsAsRead() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications/mark-read',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to mark all notifications as read: $e');
    }
  }

  /// Mark specific notification as read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationAsRead({required String notificationId}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications/$notificationId/mark-read',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to mark notification as read: $e');
    }
  }

  /// Get unread notifications count
  Future<ApiResponse<Map<String, dynamic>>> getUnreadNotificationCount() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications/unread/count',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final unreadCount = response['unread_count'] ?? response['unreadCount'] ?? 0;
      return ApiResponse.success({'unreadCount': unreadCount});
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get unread notification count: $e');
    }
  }

  /// Get read notifications
  Future<ApiResponse<NotificationModel>> getReadNotifications({required String page}) async {
    return getFilteredNotifications(page: page, readStatus: 'read');
  }

  /// Get unread notifications
  Future<ApiResponse<NotificationModel>> getUnreadNotifications({required String page}) async {
    return getFilteredNotifications(page: page, readStatus: 'unread');
  }

  /// Delete notification (if supported)
  Future<ApiResponse<Map<String, dynamic>>> deleteNotification({required String notificationId}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications/$notificationId/delete',
          method: networkUtils.HttpMethod.DELETE,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete notification: $e');
    }
  }

  /// Get my notifications (backward compatibility)
  Future<ApiResponse<NotificationModel>> getMyNotifications({required String page, String? filter}) async {
    return getNotifications(page: page, filter: filter);
  }

  /// Read all selected notifications (backward compatibility)
  Future<ApiResponse<Map<String, dynamic>>> readAllSelectedNotifications() async {
    return markAllNotificationsAsRead();
  }

  /// Read notification (backward compatibility)
  Future<ApiResponse<Map<String, dynamic>>> readNotification({required String notificationId}) async {
    return markNotificationAsRead(notificationId: notificationId);
  }
}
