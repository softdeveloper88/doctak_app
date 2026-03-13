import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/data/models/chat_model/conversation_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// API service for the new conversation-based chat system.
/// Uses the /api/chat/* endpoints which sync with the web chat.
class ConversationApiService {
  static final ConversationApiService _instance = ConversationApiService._internal();
  factory ConversationApiService() => _instance;
  ConversationApiService._internal();

  String get _baseUrl => AppData.chatApiUrl;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppData.userToken}',
    'Accept': 'application/json',
  };

  // ======================== CONVERSATIONS ========================

  /// Get all conversations for the current user
  Future<ConversationListResponse> getConversations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/conversations'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return ConversationListResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load conversations: ${response.statusCode}');
  }

  /// Create or find a direct conversation with a user
  Future<CreateConversationResponse> createConversation({
    required String userId,
    String? initialMessage,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    if (initialMessage != null) body['initial_message'] = initialMessage;

    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/create'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateConversationResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create conversation: ${response.statusCode}');
  }

  /// Find an existing conversation with a user
  Future<FindConversationResponse> findConversation({required String userId}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/conversations/find'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode == 200) {
      return FindConversationResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to find conversation: ${response.statusCode}');
  }

  /// Mark a conversation as read
  Future<void> markConversationAsRead({required int conversationId}) async {
    await http.post(
      Uri.parse('$_baseUrl/conversations/$conversationId/read'),
      headers: _headers,
    );
  }

  // ======================== MESSAGES ========================

  /// Get messages for a conversation with pagination
  Future<ConversationMessagesResponse> getMessages({
    required int conversationId,
    int? beforeId,
    int? afterId,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (beforeId != null) params['before_id'] = '$beforeId';
    if (afterId != null) params['after_id'] = '$afterId';

    final uri = Uri.parse('$_baseUrl/messages/conversation/$conversationId')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return ConversationMessagesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  /// Send a text message
  Future<ConversationMessage> sendTextMessage({
    required int conversationId,
    required String message,
    int? parentId,
  }) async {
    final body = <String, dynamic>{'message': message, 'type': 'text'};
    if (parentId != null) body['parent_id'] = parentId;

    final response = await http.post(
      Uri.parse('$_baseUrl/messages/conversation/$conversationId'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return ConversationMessage.fromJson(json['message']);
    }
    throw Exception('Failed to send message: ${response.statusCode}');
  }

  /// Send a message with file attachment using Dio (multipart)
  Future<ConversationMessage> sendFileMessage({
    required int conversationId,
    required String filePath,
    String? message,
    String? type,
  }) async {
    final dio = Dio();
    dio.options.headers = {
      'Authorization': 'Bearer ${AppData.userToken}',
      'Accept': 'application/json',
    };

    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final mimeType = _getMimeType(fileName);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ),
      'message': message ?? '',
      'type': type ?? _inferType(fileName),
    });

    final response = await dio.post(
      '$_baseUrl/messages/conversation/$conversationId',
      data: formData,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ConversationMessage.fromJson(response.data['message']);
    }
    throw Exception(
        'Failed to send file message: ${response.statusCode} - ${response.data}');
  }

  /// Send a voice message using Dio (multipart)
  Future<ConversationMessage> sendVoiceMessage({
    required int conversationId,
    required String audioPath,
    double? duration,
  }) async {
    final dio = Dio();
    dio.options.headers = {
      'Authorization': 'Bearer ${AppData.userToken}',
      'Accept': 'application/json',
    };

    final fileName = audioPath.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    // Detect correct MIME type based on extension
    final MediaType contentType;
    switch (ext) {
      case 'wav':
        contentType = MediaType('audio', 'wav');
        break;
      case 'webm':
        contentType = MediaType('audio', 'webm');
        break;
      case 'ogg':
        contentType = MediaType('audio', 'ogg');
        break;
      case 'm4a':
      case 'aac':
        contentType = MediaType('audio', 'mp4');
        break;
      case 'amr':
        contentType = MediaType('audio', 'amr');
        break;
      default:
        contentType = MediaType('audio', 'mpeg');
    }

    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioPath,
        filename: fileName,
        contentType: contentType,
      ),
      if (duration != null) 'duration': duration,
    });

    final response = await dio.post(
      '$_baseUrl/messages/conversation/$conversationId/voice',
      data: formData,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ConversationMessage.fromJson(response.data['message']);
    }
    throw Exception(
        'Failed to send voice message: ${response.statusCode} - ${response.data}');
  }

  /// Delete a message
  Future<void> deleteMessage({required int messageId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/messages/$messageId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.statusCode}');
    }
  }

  /// Mark a specific message as read
  Future<void> markMessageAsRead({required int messageId}) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/$messageId/read'),
      headers: _headers,
    );
  }

  // ======================== TYPING ========================

  /// Send typing indicator
  Future<void> sendTypingIndicator({required int conversationId}) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/conversation/$conversationId/typing'),
      headers: _headers,
    );
  }

  /// Send stop typing indicator
  Future<void> sendStopTyping({required int conversationId}) async {
    await http.post(
      Uri.parse('$_baseUrl/messages/conversation/$conversationId/stop-typing'),
      headers: _headers,
    );
  }

  // ======================== USER STATUS ========================

  /// Get online users
  Future<Map<String, dynamic>> getOnlineUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/online'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get online users: ${response.statusCode}');
  }

  /// Get a specific user's status
  Future<Map<String, dynamic>> getUserStatus({required String userId}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId/status'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get user status: ${response.statusCode}');
  }

  /// Search users
  Future<Map<String, dynamic>> searchUsers({required String query}) async {
    final uri = Uri.parse('$_baseUrl/users/search')
        .replace(queryParameters: {'q': query});
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to search users: ${response.statusCode}');
  }

  // ======================== ENHANCED FEATURES ========================

  /// Get conversation media (images, videos, etc.)
  Future<Map<String, dynamic>> getConversationMedia({
    required int conversationId,
    String type = 'all',
  }) async {
    final uri = Uri.parse('$_baseUrl/enhanced/conversations/$conversationId/media')
        .replace(queryParameters: {'type': type});
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get conversation media: ${response.statusCode}');
  }

  /// Search within a conversation
  Future<Map<String, dynamic>> searchInConversation({
    required int conversationId,
    required String query,
  }) async {
    final uri = Uri.parse('$_baseUrl/enhanced/conversations/$conversationId/search')
        .replace(queryParameters: {'q': query});
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to search conversation: ${response.statusCode}');
  }

  // ======================== HELPERS ========================

  String? _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  String _inferType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'ogg', 'aac', 'm4a'].contains(ext)) return 'audio';
    return 'file';
  }
}
