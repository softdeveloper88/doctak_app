import 'package:doctak_app/core/utils/app/AppData.dart';

class ConversationMessagesResponse {
  bool? success;
  List<ConversationMessage>? messages;
  bool? hasMore;
  int? nextCursor;

  ConversationMessagesResponse({this.success, this.messages, this.hasMore, this.nextCursor});

  ConversationMessagesResponse.fromJson(dynamic json) {
    success = json['success'];
    hasMore = json['hasMore'] ?? json['has_more'] ?? false;
    nextCursor = _toInt(json['nextCursor']);
    // Backend returns 'items' (new API) or 'messages' (legacy)
    final raw = json['items'] ?? json['messages'];
    if (raw != null) {
      messages = [];
      raw.forEach((v) {
        messages?.add(ConversationMessage.fromJson(v));
      });
    }
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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
  final String? editedAt;
  final bool isPinned;
  final bool isStarred;
  // receiptState: "sent" | "delivered" | "seen" | null
  final String? receiptState;
  final MessageSender? sender;
  final List<MessageFileData>? files;
  // Backend's new 'attachments' array (from /upload route)
  final List<MessageAttachment>? attachments;
  // Backend's 'reactions' array
  final List<MessageReaction>? reactions;
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
    this.editedAt,
    this.isPinned = false,
    this.isStarred = false,
    this.receiptState,
    this.sender,
    this.files,
    this.attachments,
    this.reactions,
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

    List<MessageAttachment>? attachments;
    if (json['attachments'] != null) {
      attachments = [];
      json['attachments'].forEach((v) {
        attachments!.add(MessageAttachment.fromJson(v));
      });
    }

    List<MessageReaction>? reactions;
    if (json['reactions'] != null) {
      reactions = [];
      json['reactions'].forEach((v) {
        reactions!.add(MessageReaction.fromJson(v));
      });
    }

    ConversationMessage? parentMsg;
    if (json['parent'] != null) {
      parentMsg = ConversationMessage.fromJson(json['parent']);
    }

    // Get message body - API returns in multiple fields
    final String? messageBody = json['body'] ?? json['content'] ?? json['message'];

    // First attachment for convenience fields
    final firstAttachment = attachments?.isNotEmpty == true ? attachments!.first : null;

    return ConversationMessage(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversationId'] ?? json['conversation_id']),
      senderId: json['senderId'] ?? json['sender_id'] ?? json['from_id'],
      type: json['type'] ?? 'text',
      body: messageBody,
      content: messageBody,
      status: json['status'] ?? 'sent',
      isDeleted: json['isDeleted'] == true || json['isDeleted'] == 1 ||
                 json['is_deleted'] == true || json['is_deleted'] == 1,
      parentId: _toInt(json['parentId'] ?? json['parent_id']),
      isForwarded: json['is_forwarded'] == true || json['is_forwarded'] == 1,
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      editedAt: json['editedAt'],
      isPinned: json['isPinned'] == true || json['isPinned'] == 1,
      isStarred: json['isStarred'] == true || json['isStarred'] == 1,
      receiptState: json['receiptState'],
      // New backend: sender has {name, avatarUrl} — legacy has {first_name, last_name, profile_pic}
      sender: json['sender'] != null ? MessageSender.fromJson(json['sender']) : null,
      files: files,
      attachments: attachments,
      reactions: reactions,
      parent: parentMsg,
      fileUrl: firstAttachment?.fileUrl ??
          (json['file_url'] != null ? AppData.resolveChatMediaUrl(json['file_url'].toString()) : null),
      fileType: firstAttachment?.fileType ?? json['file_type'],
      fileName: firstAttachment?.fileName ?? json['file_name'],
      fileSize: firstAttachment?.fileSize ?? _toInt(json['file_size']),
      thumbnailUrl: firstAttachment?.thumbnailUrl ?? json['thumbnail_url'],
    );
  }

  ConversationMessage copyWith({
    int? id,
    int? conversationId,
    dynamic senderId,
    String? type,
    String? body,
    String? content,
    String? status,
    bool? isDeleted,
    int? parentId,
    bool? isForwarded,
    String? createdAt,
    String? updatedAt,
    String? editedAt,
    bool? isPinned,
    bool? isStarred,
    String? receiptState,
    MessageSender? sender,
    List<MessageFileData>? files,
    List<MessageAttachment>? attachments,
    List<MessageReaction>? reactions,
    ConversationMessage? parent,
    String? fileUrl,
    String? fileType,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      body: body ?? this.body,
      content: content ?? this.content,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      parentId: parentId ?? this.parentId,
      isForwarded: isForwarded ?? this.isForwarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      isPinned: isPinned ?? this.isPinned,
      isStarred: isStarred ?? this.isStarred,
      receiptState: receiptState ?? this.receiptState,
      sender: sender ?? this.sender,
      files: files ?? this.files,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      parent: parent ?? this.parent,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
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

    final t = type?.toLowerCase() ?? '';
    if (t == 'voice' || t == 'audio') return '';

    if (attachmentCategory == 'audio') return '';

    final text = (body ?? content ?? '').trim();
    if (text.isEmpty) return '';

    if (looksLikeVoiceFileName(text)) return '';

    final name = fileName ??
        (files != null && files!.isNotEmpty ? files!.first.fileName : null);
    if (name != null && text == name.trim()) return '';

    return text;
  }

  static bool looksLikeVoiceFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final voicePattern = RegExp(r'^voice_\d+\.[a-z0-9]+$', caseSensitive: false);
    final audioPattern = RegExp(r'\.(m4a|mp3|wav|aac|ogg|amr|opus|webm)$', caseSensitive: false);
    return voicePattern.hasMatch(trimmed) || audioPattern.hasMatch(trimmed);
  }

  /// Resolved attachment URL from any supported field.
  String? get resolvedFileUrl {
    if (fileUrl != null && fileUrl!.trim().isNotEmpty) return fileUrl!.trim();
    if (attachments != null && attachments!.isNotEmpty) {
      final url = attachments!.first.fileUrl.trim();
      if (url.isNotEmpty) return url;
    }
    if (files != null && files!.isNotEmpty) {
      final url = files!.first.fileUrl?.trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  /// Whether this message has a file attachment
  bool get hasAttachment => resolvedFileUrl != null;

  /// Voice/audio message (may still lack URL if realtime payload was incomplete).
  bool get isVoiceOrAudioMessage {
    final t = type?.toLowerCase() ?? '';
    if (t == 'voice' || t == 'audio') return true;
    if (attachmentCategory == 'audio') return true;
    final text = (body ?? content ?? '').trim();
    if (text.isNotEmpty && looksLikeVoiceFileName(text)) return true;
    final name = fileName ??
        (files != null && files!.isNotEmpty ? files!.first.fileName : null) ??
        (attachments != null && attachments!.isNotEmpty
            ? attachments!.first.fileName
            : null);
    if (name != null && looksLikeVoiceFileName(name)) return true;
    return false;
  }

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
  // New backend fields (camelCase)
  final String? name;
  final String? avatarUrl;

  MessageSender({this.id, this.firstName, this.lastName, this.profilePic, this.name, this.avatarUrl});

  factory MessageSender.fromJson(dynamic json) {
    return MessageSender(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePic: json['profile_pic'],
      name: json['name'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }

  String get fullName {
    if (name != null && name!.isNotEmpty) return name!;
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  String? get displayAvatar => avatarUrl ?? profilePic;
}

// ─── New model classes ────────────────────────────────────────────────

/// A file attached to a message via the /api/chat/upload endpoint.
class MessageAttachment {
  final int? id;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String fileUrl;
  final String? thumbnailUrl;

  MessageAttachment({
    this.id,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.fileUrl,
    this.thumbnailUrl,
  });

  factory MessageAttachment.fromJson(dynamic json) {
    final rawUrl = (json['fileUrl'] ?? json['file_url'] ?? '').toString();
    return MessageAttachment(
      id: _toInt(json['id']),
      fileName: json['fileName'] ?? json['file_name'],
      fileType: json['fileType'] ?? json['file_type'],
      fileSize: _toInt(json['fileSize'] ?? json['file_size']),
      fileUrl: rawUrl.isNotEmpty ? AppData.resolveChatMediaUrl(rawUrl) : '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// An emoji reaction on a message.
class MessageReaction {
  final String emoji;
  final List<String> userIds;
  final int count;

  MessageReaction({required this.emoji, required this.userIds, required this.count});

  factory MessageReaction.fromJson(dynamic json) {
    final rawUserIds = json['userIds'] ?? json['user_ids'] ?? [];
    final ids = <String>[];
    if (rawUserIds is List) {
      for (final id in rawUserIds) ids.add(id.toString());
    }
    return MessageReaction(
      emoji: (json['emoji'] ?? '').toString(),
      userIds: ids,
      count: (json['count'] ?? ids.length) is int
          ? json['count'] ?? ids.length
          : int.tryParse(json['count'].toString()) ?? ids.length,
    );
  }
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
    final rawUrl = json['file_url']?.toString();
    return MessageFileData(
      id: _toIntFile(json['id']),
      messageId: _toIntFile(json['message_id']),
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: _toIntFile(json['file_size']),
      fileUrl: rawUrl != null && rawUrl.isNotEmpty ? AppData.resolveChatMediaUrl(rawUrl) : rawUrl,
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
