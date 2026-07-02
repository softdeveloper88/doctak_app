import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/data/models/chat_model/conversation_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// API service for the conversation-based chat system.
/// Maps to doctak-node /api/chat/* routes.
class ConversationApiService {
  static final ConversationApiService _instance = ConversationApiService._internal();
  factory ConversationApiService() => _instance;
  ConversationApiService._internal();

  String get _base => AppData.chatApiUrl;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppData.userToken}',
    'Accept': 'application/json',
  };

  Map<String, String> get _jsonHeaders => {
    ..._headers,
    'Content-Type': 'application/json',
  };

  // ─── Conversations ─────────────────────────────────────────────

  /// List all conversations for the current user.
  Future<ConversationListResponse> getConversations() async {
    final res = await http.get(Uri.parse('$_base/conversations'), headers: _headers);
    _assertOk(res, 'getConversations');
    return ConversationListResponse.fromJson(jsonDecode(res.body));
  }

  /// Create or open a direct conversation.
  /// Backend: POST /api/chat/conversations  body: {peerUserId}
  Future<CreateConversationResponse> createConversation({required String peerUserId}) async {
    final res = await http.post(
      Uri.parse('$_base/conversations'),
      headers: _jsonHeaders,
      body: jsonEncode({'peerUserId': peerUserId}),
    );
    _assertOk(res, 'createConversation', extra: {201});
    return CreateConversationResponse.fromJson(jsonDecode(res.body));
  }

  /// Mark all messages read up to [messageId].
  /// Backend: POST /api/chat/conversations/:id/read  body: {messageId}
  Future<void> markConversationAsRead({
    required int conversationId,
    required int messageId,
  }) async {
    await http.post(
      Uri.parse('$_base/conversations/$conversationId/read'),
      headers: _jsonHeaders,
      body: jsonEncode({'messageId': messageId}),
    );
  }

  // ─── Messages ─────────────────────────────────────────────────

  /// Paginated message history.
  /// Backend: GET /api/chat/conversations/:id/messages?cursor=&limit=
  Future<ConversationMessagesResponse> getMessages({
    required int conversationId,
    int? cursor,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = '$cursor';
    final uri = Uri.parse('$_base/conversations/$conversationId/messages')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    _assertOk(res, 'getMessages');
    return ConversationMessagesResponse.fromJson(jsonDecode(res.body));
  }

  /// Incremental sync — fetch only messages newer than [afterId] / [updatedAfter].
  /// Backend: GET /api/chat/conversations/:id/messages/since?after=&updatedAfter=
  Future<ConversationMessagesResponse> getMessagesSince({
    required int conversationId,
    int? afterId,
    String? updatedAfter,
  }) async {
    final params = <String, String>{};
    if (afterId != null) params['after'] = '$afterId';
    if (updatedAfter != null) params['updatedAfter'] = updatedAfter;
    final uri = Uri.parse('$_base/conversations/$conversationId/messages/since')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    _assertOk(res, 'getMessagesSince');
    return ConversationMessagesResponse.fromJson(jsonDecode(res.body));
  }

  /// Send a text message.
  /// Backend: POST /api/chat/conversations/:id/messages  body: {body, parentId?}
  Future<ConversationMessage> sendTextMessage({
    required int conversationId,
    required String body,
    int? parentId,
  }) async {
    final payload = <String, dynamic>{'body': body};
    if (parentId != null) payload['parentId'] = parentId;
    final res = await http.post(
      Uri.parse('$_base/conversations/$conversationId/messages'),
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    _assertOk(res, 'sendTextMessage', extra: {201});
    final json = jsonDecode(res.body);
    return ConversationMessage.fromJson(json['message'] ?? json['data'] ?? json);
  }

  /// Edit an existing message body.
  /// Backend: PATCH /api/chat/messages/:id  body: {body}
  Future<ConversationMessage> editMessage({
    required int messageId,
    required String body,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/messages/$messageId'),
      headers: _jsonHeaders,
      body: jsonEncode({'body': body}),
    );
    _assertOk(res, 'editMessage');
    final json = jsonDecode(res.body);
    return ConversationMessage.fromJson(json['message'] ?? json['data'] ?? json);
  }

  /// Delete a message.
  /// Backend: DELETE /api/chat/messages/:id
  Future<void> deleteMessage({required int messageId}) async {
    final res = await http.delete(Uri.parse('$_base/messages/$messageId'), headers: _headers);
    _assertOk(res, 'deleteMessage');
  }

  /// Mark a message as delivered.
  /// Backend: POST /api/chat/messages/:id/delivered
  Future<void> markMessageDelivered({required int messageId}) async {
    await http.post(Uri.parse('$_base/messages/$messageId/delivered'), headers: _headers);
  }

  // ─── Reactions ────────────────────────────────────────────────

  /// Toggle an emoji reaction. Returns updated reactions list.
  /// Backend: POST /api/chat/messages/:id/reactions  body: {emoji}
  Future<List<MessageReaction>> toggleReaction({
    required int messageId,
    required String emoji,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/messages/$messageId/reactions'),
      headers: _jsonHeaders,
      body: jsonEncode({'emoji': emoji}),
    );
    _assertOk(res, 'toggleReaction');
    final json = jsonDecode(res.body);
    final raw = json['reactions'] ?? [];
    return (raw as List).map((r) => MessageReaction.fromJson(r)).toList();
  }

  // ─── File / Voice upload ──────────────────────────────────────

  /// Upload a file attachment and post it to a conversation.
  /// Backend: POST /api/chat/upload  multipart: {file, conversationId, caption?}
  Future<ConversationMessage> sendFileMessage({
    required int conversationId,
    required String filePath,
    String? caption,
  }) async {
    final dio = _buildDio();
    final fileName = filePath.split('/').last;
    final mimeType = _getMimeType(fileName);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ),
      'conversationId': conversationId.toString(),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
    final res = await dio.post('$_base/upload', data: formData);
    _assertDioOk(res, 'sendFileMessage');
    return ConversationMessage.fromJson(res.data['message'] ?? res.data['data'] ?? res.data);
  }

  /// Upload a voice recording and post it to a conversation.
  /// Backend: POST /api/chat/upload  multipart: {file, conversationId, duration?}
  Future<ConversationMessage> sendVoiceMessage({
    required int conversationId,
    required String audioPath,
    double? duration,
  }) async {
    final dio = _buildDio();
    final fileName = audioPath.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    final MediaType contentType;
    switch (ext) {
      case 'wav':  contentType = MediaType('audio', 'wav'); break;
      case 'webm': contentType = MediaType('audio', 'webm'); break;
      case 'ogg':  contentType = MediaType('audio', 'ogg'); break;
      case 'm4a':
      case 'aac':  contentType = MediaType('audio', 'mp4'); break;
      case 'amr':  contentType = MediaType('audio', 'amr'); break;
      default:     contentType = MediaType('audio', 'mpeg');
    }
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioPath, filename: fileName, contentType: contentType),
      'conversationId': conversationId.toString(),
      if (duration != null) 'duration': duration.toStringAsFixed(2),
    });
    final res = await dio.post('$_base/upload', data: formData);
    _assertDioOk(res, 'sendVoiceMessage');
    return ConversationMessage.fromJson(res.data['message'] ?? res.data['data'] ?? res.data);
  }

  // ─── WebSocket ticket ─────────────────────────────────────────

  /// Get a WebSocket connection URL for [conversationId].
  /// Returns null wsUrl when WS is not configured — fall back to polling.
  /// Backend: GET /api/chat/ws-ticket?conversationId=
  Future<WsTicketResponse> getWsTicket({required int conversationId}) async {
    final uri = Uri.parse('$_base/ws-ticket')
        .replace(queryParameters: {'conversationId': '$conversationId'});
    final res = await http.get(uri, headers: _headers);
    _assertOk(res, 'getWsTicket');
    return WsTicketResponse.fromJson(jsonDecode(res.body));
  }

  // ─── Presence / Heartbeat / Connections ───────────────────────

  /// Keep-alive presence heartbeat (server: POST /api/chat/presence).
  Future<void> touchPresence() async {
    await http.post(Uri.parse('$_base/presence'), headers: _headers);
  }

  /// Broadcast typing to conversation participants (chat list + open room).
  Future<void> postTyping({
    required int conversationId,
    required bool isTyping,
  }) async {
    await http.post(
      Uri.parse('$_base/typing'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'conversationId': conversationId,
        'isTyping': isTyping,
      }),
    );
  }

  /// Online status for participants in a conversation.
  Future<Map<String, dynamic>> getConversationPresence({required int conversationId}) async {
    final uri = Uri.parse('$_base/presence')
        .replace(queryParameters: {'conversationId': '$conversationId'});
    final res = await http.get(uri, headers: _headers);
    _assertOk(res, 'getConversationPresence');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Get all active WS connections for the current user.
  Future<Map<String, dynamic>> getConnections() async {
    final res = await http.get(Uri.parse('$_base/connections'), headers: _headers);
    _assertOk(res, 'getConnections');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Search ───────────────────────────────────────────────────

  Future<ConversationMessagesResponse> searchMessages({
    required int conversationId,
    required String query,
  }) async {
    final uri = Uri.parse('$_base/conversations/$conversationId/messages/search')
        .replace(queryParameters: {'q': query});
    final res = await http.get(uri, headers: _headers);
    _assertOk(res, 'searchMessages');
    return ConversationMessagesResponse.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> searchUsers({required String query}) async {
    final uri = Uri.parse('$_base/users/search').replace(queryParameters: {'q': query});
    final res = await http.get(uri, headers: _headers);
    _assertOk(res, 'searchUsers');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── AI ──────────────────────────────────────────────────────

  /// Server-sent events stream for AI reply.
  Future<http.StreamedResponse> streamAiReply({required int conversationId}) async {
    final req = http.Request(
        'POST', Uri.parse('$_base/conversations/$conversationId/ai-reply'));
    req.headers.addAll(_jsonHeaders);
    return req.send();
  }

  // ─── Helpers ─────────────────────────────────────────────────

  Dio _buildDio() {
    final dio = Dio();
    dio.options.headers = {
      'Authorization': 'Bearer ${AppData.userToken}',
      'Accept': 'application/json',
    };
    dio.options.validateStatus = (s) => s != null && s < 500;
    return dio;
  }

  void _assertOk(http.Response res, String method, {Set<int> extra = const {}}) {
    if (res.statusCode != 200 && !extra.contains(res.statusCode)) {
      throw Exception('$method failed: ${res.statusCode} ${res.body}');
    }
  }

  void _assertDioOk(Response res, String method) {
    if (res.statusCode == null ||
        (res.statusCode! >= 400 && res.statusCode! < 500)) {
      throw Exception('$method failed: ${res.statusCode} ${res.data}');
    }
  }

  String? _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':  return 'image/jpeg';
      case 'png':   return 'image/png';
      case 'gif':   return 'image/gif';
      case 'webp':  return 'image/webp';
      case 'mp4':   return 'video/mp4';
      case 'mov':   return 'video/quicktime';
      case 'mp3':   return 'audio/mpeg';
      case 'wav':   return 'audio/wav';
      case 'webm':  return 'audio/webm';
      case 'ogg':   return 'audio/ogg';
      case 'm4a':
      case 'aac':   return 'audio/mp4';
      case 'pdf':   return 'application/pdf';
      case 'doc':
      case 'docx':  return 'application/msword';
      default:      return 'application/octet-stream';
    }
  }
}

