import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/notification_model/notification_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Notification API Service
/// Handles all notification related API calls
class NotificationApiService {
  static final NotificationApiService _instance = NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  /// Get all notifications
  Future<ApiResponse<NotificationModel>> getNotifications({required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications?page=$page', method: networkUtils.HttpMethod.GET));
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
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications/$readStatus?page=$page', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(NotificationModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get filtered notifications: $e');
    }
  }

  /// Mark all notifications as read
  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsAsRead() async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications/mark-read', method: networkUtils.HttpMethod.POST));
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
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications/$notificationId/mark-read', method: networkUtils.HttpMethod.POST));
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
      final response = await getFilteredNotifications(page: '1', readStatus: 'unread');
      if (response.success && response.data != null) {
        final unreadCount = response.data!.notifications?.data?.length ?? 0;
        return ApiResponse.success({
          'unreadCount': unreadCount,
          'totalPages': 1, // NotificationModel doesn't have totalPages property
        });
      } else {
        return ApiResponse.error('Failed to get unread count');
      }
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
      // Note: This endpoint might not exist in the original API
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications/$notificationId/delete', method: networkUtils.HttpMethod.DELETE));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete notification: $e');
    }
  }

  /// Clear all notifications (if supported)
  Future<ApiResponse<Map<String, dynamic>>> clearAllNotifications() async {
    try {
      // Note: This endpoint might not exist in the original API
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications/clear-all', method: networkUtils.HttpMethod.POST));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to clear all notifications: $e');
    }
  }

  /// Get notification settings (if supported)
  Future<ApiResponse<Map<String, dynamic>>> getNotificationSettings() async {
    try {
      // Note: This endpoint might not exist in the original API
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/notifications/settings', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get notification settings: $e');
    }
  }

  /// Update notification settings (if supported)
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationSettings({required Map<String, bool> settings}) async {
    try {
      // Note: This endpoint might not exist in the original API
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse('/notifications/settings/update', method: networkUtils.HttpMethod.POST, request: settings.map((key, value) => MapEntry(key, value.toString()))),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update notification settings: $e');
    }
  }

  // ================================== BACKWARD COMPATIBILITY ==================================

  /// Get my notifications (backward compatibility)
  Future<ApiResponse<NotificationModel>> getMyNotifications({required String page}) async {
    return getNotifications(page: page);
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
