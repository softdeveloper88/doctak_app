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
  // New backend: peer is the other user in a direct conversation
  final ConversationPeer? peer;

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
    this.peer,
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
    // Backend returns 'lastMessage' (camelCase) or 'last_message' (snake_case)
    final rawLastMsg = json['lastMessage'] ?? json['last_message'];
    if (rawLastMsg != null) {
      lastMsg = ConversationLastMessage.fromJson(rawLastMsg);
    }

    ConversationPeer? peer;
    if (json['peer'] != null) {
      peer = ConversationPeer.fromJson(json['peer']);
    }

    // Resolve display name: backend may return name or derive from peer
    String? displayName = json['name'];
    if ((displayName == null || displayName.isEmpty) && peer != null) {
      displayName = peer.name;
    }

    // Resolve avatar: from peer.avatarUrl or legacy avatar field
    String? displayAvatar = peer?.avatarUrl ?? json['avatarUrl'];
    if (displayAvatar == null && json['avatar'] != null) {
      displayAvatar = AppData.fullImageUrl(json['avatar'].toString());
    }

    return Conversation(
      id: _safeInt(json['id']),
      name: displayName,
      avatar: displayAvatar,
      type: json['type'],
      unreadCount: _safeInt(json['unreadCount'] ?? json['unread_count']) ?? 0,
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      lastMessage: lastMsg,
      participants: participants,
      peer: peer,
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
    ConversationPeer? peer,
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
      peer: peer ?? this.peer,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, type, unreadCount, createdAt];
}

/// The other participant in a direct conversation (new backend format).
class ConversationPeer {
  final String id;
  final String? name;
  final String? specialty;
  final String? avatarUrl;
  final bool isAi;

  ConversationPeer({
    required this.id,
    this.name,
    this.specialty,
    this.avatarUrl,
    this.isAi = false,
  });

  factory ConversationPeer.fromJson(dynamic json) {
    return ConversationPeer(
      id: (json['id'] ?? '').toString(),
      name: json['name'],
      specialty: json['specialty'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      isAi: json['isAi'] == true || json['is_ai'] == true,
    );
  }
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
      conversationId: _safeInt(json['conversationId'] ?? json['conversation_id']),
      senderId: json['senderId'] ?? json['sender_id'] ?? json['from_id'],
      type: json['type'],
      body: json['body'] ?? json['content'] ?? json['message'],
      content: json['content'] ?? json['body'] ?? json['message'],
      status: json['status'],
      createdAt: json['createdAt'] ?? json['created_at'],
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
  final bool isVerified;

  ParticipantUser({this.id, this.firstName, this.lastName, this.profilePic, this.isVerified = false});

  factory ParticipantUser.fromJson(dynamic json) {
    return ParticipantUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePic: json['profile_pic'],
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

class CreateConversationResponse {
  final bool? success;
  final int? conversationId;
  final bool? isNew;
  final Conversation? conversation;

  CreateConversationResponse({this.success, this.conversationId, this.isNew, this.conversation});

  factory CreateConversationResponse.fromJson(dynamic json) {
    Conversation? conv;
    final rawConv = json['conversation'] ?? json['data'];
    if (rawConv != null) conv = Conversation.fromJson(rawConv);
    return CreateConversationResponse(
      success: json['success'],
      conversationId: _safeInt(json['conversationId'] ?? json['conversation_id']),
      isNew: json['isNew'] ?? json['is_new'],
      conversation: conv,
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
      conversationId: _safeInt(json['conversationId'] ?? json['conversation_id']),
    );
  }
}

/// Response from GET /api/chat/ws-ticket
class WsTicketResponse {
  /// Null when WebSocket is not configured; client should fall back to polling.
  final String? wsUrl;
  final int conversationId;

  WsTicketResponse({this.wsUrl, required this.conversationId});

  factory WsTicketResponse.fromJson(dynamic json) {
    return WsTicketResponse(
      wsUrl: json['wsUrl'],
      conversationId: _safeInt(json['conversationId']) ?? 0,
    );
  }
}
