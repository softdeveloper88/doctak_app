import 'dart:convert';

enum MessageRole { user, assistant, system }

extension MessageRoleExtension on MessageRole {
  String get value {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }

  static MessageRole fromString(String value) {
    switch (value) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        throw ArgumentError('Invalid MessageRole value: $value');
    }
  }
}

class Source {
  final String url;
  final String? title;

  Source({required this.url, this.title});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(url: json['url'], title: json['title']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'title': title};
  }
}

class AiChatMessageModel {
  final int id;
  final int sessionId;
  final MessageRole role;
  final String content;
  final String? filePath;
  final String? mimeType;
  final String? feedback;
  final List<Source>? sources;
  final DateTime createdAt;
  final List<int>? fileBytes; // Store image bytes for reliable display

  AiChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.filePath,
    this.mimeType,
    this.feedback,
    this.sources,
    required this.createdAt,
    this.fileBytes,
  });

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) {
    List<Source>? sources;
    if (json['metadata'] != null) {
      final metadata = json['metadata'] is String ? jsonDecode(json['metadata']) : json['metadata'];

      if (metadata['sources'] != null) {
        sources = (metadata['sources'] as List).map((source) => Source.fromJson(source)).toList();
      }
    }

    return AiChatMessageModel(
      id: json['id'] ?? 0,
      sessionId: json['session_id'],
      role: MessageRoleExtension.fromString(json['role']),
      content: json['content'],
      filePath: json['file_path'],
      mimeType: json['mime_type'],
      feedback: json['feedback'],
      sources: sources,
      createdAt: DateTime.parse(json['created_at']),
      fileBytes: json['file_bytes'] != null ? List<int>.from(json['file_bytes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> metadata = {};
    if (sources != null && sources!.isNotEmpty) {
      metadata['sources'] = sources!.map((source) => source.toJson()).toList();
    }

    return {
      'id': id,
      'session_id': sessionId,
      'role': role.value,
      'content': content,
      'file_path': filePath,
      'mime_type': mimeType,
      'feedback': feedback,
      'metadata': metadata.isEmpty ? null : jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'file_bytes': fileBytes,
    };
  }

  // For local storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from local storage
  factory AiChatMessageModel.fromJsonString(String jsonString) {
    return AiChatMessageModel.fromJson(jsonDecode(jsonString));
  }
}
