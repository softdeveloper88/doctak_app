import 'package:doctak_app/core/utils/app/AppData.dart';

class ConversationMessagesResponse {
  bool? success;
  List<ConversationMessage>? messages;
  bool? hasMore;

  ConversationMessagesResponse({this.success, this.messages, this.hasMore});

  ConversationMessagesResponse.fromJson(dynamic json) {
    success = json['success'];
    hasMore = json['has_more'] ?? false;
    if (json['messages'] != null) {
      messages = [];
      json['messages'].forEach((v) {
        messages?.add(ConversationMessage.fromJson(v));
      });
    }
  }
}

class ConversationMessage {
  final int? id;
  final int? conversationId;
  final dynamic senderId;
  final String? type;
  final String? body;
  final String? content;
  final String? status;
  final bool? isDeleted;
  final int? parentId;
  final bool? isForwarded;
  final String? createdAt;
  final String? updatedAt;
  final MessageSender? sender;
  final List<MessageFileData>? files;
  final ConversationMessage? parent;
  // Convenience fields from API for first file
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;

  ConversationMessage({
    this.id,
    this.conversationId,
    this.senderId,
    this.type,
    this.body,
    this.content,
    this.status,
    this.isDeleted,
    this.parentId,
    this.isForwarded,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.files,
    this.parent,
    this.fileUrl,
    this.fileType,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
  });

  factory ConversationMessage.fromJson(dynamic json) {
    List<MessageFileData>? files;
    if (json['files'] != null) {
      files = [];
      json['files'].forEach((v) {
        files!.add(MessageFileData.fromJson(v));
      });
    }

    ConversationMessage? parentMsg;
    if (json['parent'] != null) {
      parentMsg = ConversationMessage.fromJson(json['parent']);
    }

    // Get message body - API returns in multiple fields
    final String? messageBody = json['body'] ?? json['content'] ?? json['message'];

    return ConversationMessage(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversation_id']),
      senderId: json['sender_id'] ?? json['from_id'],
      type: json['type'] ?? 'text',
      body: messageBody,
      content: messageBody,
      status: json['status'] ?? 'sent',
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      parentId: _toInt(json['parent_id']),
      isForwarded: json['is_forwarded'] == true || json['is_forwarded'] == 1,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      sender: json['sender'] != null ? MessageSender.fromJson(json['sender']) : null,
      files: files,
      parent: parentMsg,
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileName: json['file_name'],
      fileSize: _toInt(json['file_size']),
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Whether this message was sent by the current user
  bool get isMine => senderId.toString() == AppData.logInUserId;

  /// Get the display text for the message
  String get displayText {
    if (isDeleted == true) return 'This message was deleted';
    // Voice/audio messages show their own player widget — suppress body text label
    final t = type?.toLowerCase() ?? '';
    if (t == 'voice' || t == 'audio') return '';
    return body ?? content ?? '';
  }

  /// Whether this message has a file attachment
  bool get hasAttachment => fileUrl != null || (files != null && files!.isNotEmpty);

  /// Get attachment type category
  String get attachmentCategory {
    if (type == 'image') return 'image';
    if (type == 'video') return 'video';
    if (type == 'audio') return 'audio';
    if (type == 'file') return 'file';
    if (fileType != null) {
      if (fileType!.startsWith('image/')) return 'image';
      if (fileType!.startsWith('video/')) return 'video';
      if (fileType!.startsWith('audio/')) return 'audio';
    }
    return 'file';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'type': type,
      'body': body,
      'content': content,
      'status': status,
      'is_deleted': isDeleted,
      'parent_id': parentId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class MessageSender {
  final dynamic id;
  final String? firstName;
  final String? lastName;
  final String? profilePic;

  MessageSender({this.id, this.firstName, this.lastName, this.profilePic});

  factory MessageSender.fromJson(dynamic json) {
    return MessageSender(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePic: json['profile_pic'],
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

class MessageFileData {
  final int? id;
  final int? messageId;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? fileUrl;
  final String? thumbnailUrl;

  MessageFileData({
    this.id,
    this.messageId,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.fileUrl,
    this.thumbnailUrl,
  });

  factory MessageFileData.fromJson(dynamic json) {
    return MessageFileData(
      id: _toIntFile(json['id']),
      messageId: _toIntFile(json['message_id']),
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: _toIntFile(json['file_size']),
      fileUrl: json['file_url'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }

  static int? _toIntFile(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
