import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:equatable/equatable.dart';

int? _safeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class ConversationListResponse {
  bool? success;
  List<Conversation>? conversations;

  ConversationListResponse({this.success, this.conversations});

  ConversationListResponse.fromJson(dynamic json) {
    success = json['success'];
    if (json['conversations'] != null) {
      conversations = [];
      json['conversations'].forEach((v) {
        conversations?.add(Conversation.fromJson(v));
      });
    }
  }
}

class Conversation extends Equatable {
  final int? id;
  final String? name;
  final String? avatar;
  final String? type;
  final int? unreadCount;
  final String? createdAt;
  final String? updatedAt;
  final ConversationLastMessage? lastMessage;
  final List<ConversationParticipant>? participants;

  const Conversation({
    this.id,
    this.name,
    this.avatar,
    this.type,
    this.unreadCount,
    this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.participants,
  });

  factory Conversation.fromJson(dynamic json) {
    List<ConversationParticipant>? participants;
    if (json['conversation_participants'] != null) {
      participants = [];
      json['conversation_participants'].forEach((v) {
        participants!.add(ConversationParticipant.fromJson(v));
      });
    }

    ConversationLastMessage? lastMsg;
    if (json['last_message'] != null) {
      lastMsg = ConversationLastMessage.fromJson(json['last_message']);
    }

    return Conversation(
      id: _safeInt(json['id']),
      name: json['name'],
      avatar: json['avatar'] != null ? AppData.fullImageUrl(json['avatar'].toString()) : null,
      type: json['type'],
      unreadCount: _safeInt(json['unread_count']) ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      lastMessage: lastMsg,
      participants: participants,
    );
  }

  /// Get the other participant in a direct conversation
  ConversationParticipant? getOtherParticipant(String currentUserId) {
    return participants?.firstWhere(
      (p) => p.userId.toString() != currentUserId,
      orElse: () => participants!.first,
    );
  }

  Conversation copyWith({
    int? id,
    String? name,
    String? avatar,
    String? type,
    int? unreadCount,
    String? createdAt,
    String? updatedAt,
    ConversationLastMessage? lastMessage,
    List<ConversationParticipant>? participants,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      participants: participants ?? this.participants,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, type, unreadCount, createdAt];
}

class ConversationLastMessage {
  final int? id;
  final int? conversationId;
  final dynamic senderId;
  final String? type;
  final String? body;
  final String? content;
  final String? status;
  final String? createdAt;

  ConversationLastMessage({
    this.id,
    this.conversationId,
    this.senderId,
    this.type,
    this.body,
    this.content,
    this.status,
    this.createdAt,
  });

  factory ConversationLastMessage.fromJson(dynamic json) {
    return ConversationLastMessage(
      id: _safeInt(json['id']),
      conversationId: _safeInt(json['conversation_id']),
      senderId: json['sender_id'] ?? json['from_id'],
      type: json['type'],
      body: json['body'] ?? json['content'] ?? json['message'],
      content: json['content'] ?? json['body'] ?? json['message'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}

class ConversationParticipant {
  final int? id;
  final int? conversationId;
  final dynamic userId;
  final String? role;
  final int? unreadCount;
  final bool? isBlocked;
  final bool? isMuted;
  final ParticipantUser? user;

  ConversationParticipant({
    this.id,
    this.conversationId,
    this.userId,
    this.role,
    this.unreadCount,
    this.isBlocked,
    this.isMuted,
    this.user,
  });

  factory ConversationParticipant.fromJson(dynamic json) {
    return ConversationParticipant(
      id: _safeInt(json['id']),
      conversationId: _safeInt(json['conversation_id']),
      userId: json['user_id'],
      role: json['role'],
      unreadCount: _safeInt(json['unread_count']) ?? 0,
      isBlocked: json['is_blocked'] == true || json['is_blocked'] == 1,
      isMuted: json['is_muted'] == true || json['is_muted'] == 1,
      user: json['user'] != null ? ParticipantUser.fromJson(json['user']) : null,
    );
  }
}

class ParticipantUser {
  final dynamic id;
  final String? firstName;
  final String? lastName;
  final String? profilePic;

  ParticipantUser({this.id, this.firstName, this.lastName, this.profilePic});

  factory ParticipantUser.fromJson(dynamic json) {
    return ParticipantUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePic: json['profile_pic'],
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

class CreateConversationResponse {
  final bool? success;
  final int? conversationId;
  final bool? isNew;

  CreateConversationResponse({this.success, this.conversationId, this.isNew});

  factory CreateConversationResponse.fromJson(dynamic json) {
    return CreateConversationResponse(
      success: json['success'],
      conversationId: _safeInt(json['conversation_id']),
      isNew: json['is_new'],
    );
  }
}

class FindConversationResponse {
  final bool? success;
  final bool? exists;
  final int? conversationId;

  FindConversationResponse({this.success, this.exists, this.conversationId});

  factory FindConversationResponse.fromJson(dynamic json) {
    return FindConversationResponse(
      success: json['success'],
      exists: json['exists'],
      conversationId: _safeInt(json['conversation_id']),
    );
  }
}
