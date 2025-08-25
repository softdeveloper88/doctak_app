import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/chat_model/contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/message_model.dart';
import 'package:doctak_app/data/models/chat_model/search_contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/send_message_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Chat API Service
/// Handles all chat and messaging related API calls
class ChatApiService {
  static final ChatApiService _instance = ChatApiService._internal();
  factory ChatApiService() => _instance;
  ChatApiService._internal();

  /// Get contacts list for chat
  Future<ApiResponse<ContactsModel>> getContacts({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-contacts?page=$page',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(ContactsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get contacts: $e');
    }
  }

  /// Search contacts
  Future<ApiResponse<SearchContactsModel>> searchContacts({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search-contacts?page=$page&keyword=$keyword',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(SearchContactsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search contacts: $e');
    }
  }

  /// Get chat messages for a room
  Future<ApiResponse<MessageModel>> getChatMessages({
    required String page,
    required String userId,
    required String roomId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/messenger?page=$page&user_id=$userId&room_id=$roomId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(MessageModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get messages: $e');
    }
  }

  /// Send text message
  Future<ApiResponse<SendMessageModel>> sendTextMessage({
    required String userId,
    required String roomId,
    required String receiverId,
    required String message,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/send-message',
          method: networkUtils.HttpMethod.POST,
          request: {
            'user_id': userId,
            'room_id': roomId,
            'receiver_id': receiverId,
            'attachment_type': 'text',
            'message': message,
          },
        ),
      );
      return ApiResponse.success(SendMessageModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to send text message: $e');
    }
  }

  /// Send message with file attachment
  Future<ApiResponse<SendMessageModel>> sendMessageWithFile({
    required String userId,
    required String roomId,
    required String receiverId,
    required String message,
    required String attachmentType,
    required String filePath,
  }) async {
    try {
      // Note: This needs special handling for file uploads
      // For now, using basic request structure
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/send-message',
          method: networkUtils.HttpMethod.POST,
          request: {
            'user_id': userId,
            'room_id': roomId,
            'receiver_id': receiverId,
            'attachment_type': attachmentType,
            'message': message,
            'file': filePath, // This would need proper file upload handling
          },
        ),
      );
      return ApiResponse.success(SendMessageModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to send message with file: $e');
    }
  }

  /// Delete a message
  Future<ApiResponse<Map<String, dynamic>>> deleteMessage({
    required String messageId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/delete-message',
          method: networkUtils.HttpMethod.POST,
          request: {'ic': messageId},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete message: $e');
    }
  }

  /// Update message read status
  Future<ApiResponse<Map<String, dynamic>>> updateReadStatus({
    required String userId,
    required String roomId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/update-seen-status?user_id=$userId&room_id=$roomId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update read status: $e');
    }
  }

  /// Send image message
  Future<ApiResponse<SendMessageModel>> sendImageMessage({
    required String userId,
    required String roomId,
    required String receiverId,
    required String imagePath,
    String? caption,
  }) async {
    return sendMessageWithFile(
      userId: userId,
      roomId: roomId,
      receiverId: receiverId,
      message: caption ?? '',
      attachmentType: 'image',
      filePath: imagePath,
    );
  }

  /// Send video message
  Future<ApiResponse<SendMessageModel>> sendVideoMessage({
    required String userId,
    required String roomId,
    required String receiverId,
    required String videoPath,
    String? caption,
  }) async {
    return sendMessageWithFile(
      userId: userId,
      roomId: roomId,
      receiverId: receiverId,
      message: caption ?? '',
      attachmentType: 'video',
      filePath: videoPath,
    );
  }

  /// Send document message
  Future<ApiResponse<SendMessageModel>> sendDocumentMessage({
    required String userId,
    required String roomId,
    required String receiverId,
    required String documentPath,
    String? caption,
  }) async {
    return sendMessageWithFile(
      userId: userId,
      roomId: roomId,
      receiverId: receiverId,
      message: caption ?? '',
      attachmentType: 'document',
      filePath: documentPath,
    );
  }

  /// Send audio message
  Future<ApiResponse<SendMessageModel>> sendAudioMessage({
    required String userId,
    required String roomId,
    required String receiverId,
    required String audioPath,
    String? caption,
  }) async {
    return sendMessageWithFile(
      userId: userId,
      roomId: roomId,
      receiverId: receiverId,
      message: caption ?? '',
      attachmentType: 'audio',
      filePath: audioPath,
    );
  }

  /// Get chat room info
  Future<ApiResponse<Map<String, dynamic>>> getRoomInfo({
    required String roomId,
  }) async {
    try {
      // This endpoint might not exist in the original API
      // Adding it as a placeholder for room information
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/room-info?room_id=$roomId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get room info: $e');
    }
  }

  /// Mark all messages in room as read
  Future<ApiResponse<Map<String, dynamic>>> markRoomAsRead({
    required String userId,
    required String roomId,
  }) async {
    return updateReadStatus(userId: userId, roomId: roomId);
  }

  /// Get unread message count
  Future<ApiResponse<Map<String, dynamic>>> getUnreadCount({
    required String userId,
  }) async {
    try {
      // This might need to be calculated from contacts or messages
      final contactsResponse = await getContacts(page: '1');
      if (contactsResponse.success && contactsResponse.data != null) {
        // Calculate unread count from contacts
        final contacts = contactsResponse.data!.contacts ?? [];
        int totalUnread = 0;
        for (var contact in contacts) {
          totalUnread += contact.unreadCount ?? 0;
        }
        return ApiResponse.success({
          'totalUnreadCount': totalUnread,
          'unreadRooms': contacts.where((c) => (c.unreadCount ?? 0) > 0).length,
        });
      } else {
        return ApiResponse.error('Failed to get unread count');
      }
    } catch (e) {
      return ApiResponse.error('Failed to get unread count: $e');
    }
  }

  // ================================== BACKWARD COMPATIBILITY METHODS ==================================

  /// Backward compatibility method for getRoomMessenger
  Future<ApiResponse<MessageModel>> getRoomMessenger({
    required String page,
    required String userId,
    required String roomId,
  }) async {
    return getChatMessages(page: page, userId: userId, roomId: roomId);
  }

  /// Backward compatibility method for sendMessageWithoutFile
  Future<ApiResponse<SendMessageModel>> sendMessageWithoutFile({
    required String userId,
    required String roomId,
    required String receiverId,
    required String attachmentType,
    required String message,
  }) async {
    return sendTextMessage(
      userId: userId,
      roomId: roomId,
      receiverId: receiverId,
      message: message,
    );
  }
}