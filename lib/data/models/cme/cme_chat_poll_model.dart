class CmeChatMessage {
  final String? id;
  final String? eventId;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String? message;
  final String? createdAt;
  final bool? isOwn;
  final String? role; // attendee, speaker, organizer, moderator

  CmeChatMessage({
    this.id,
    this.eventId,
    this.userId,
    this.userName,
    this.userAvatar,
    this.message,
    this.createdAt,
    this.isOwn,
    this.role,
  });

  factory CmeChatMessage.fromJson(Map<String, dynamic> json) {
    return CmeChatMessage(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? json['user']?['name'],
      userAvatar: json['user_avatar'] ?? json['user']?['profile_pic'],
      message: json['message'],
      createdAt: json['created_at'],
      isOwn: json['is_own'],
      role: json['role'],
    );
  }

  bool get isModerator => role == 'moderator' || role == 'organizer';
  bool get isSpeaker => role == 'speaker';
}

class CmePollData {
  final String? id;
  final String? eventId;
  final String? question;
  final List<CmePollOption>? options;
  final String? status; // active, closed, draft
  final int? totalVotes;
  final bool? hasVoted;
  final String? votedOptionId;
  final String? createdAt;
  final String? closedAt;

  CmePollData({
    this.id,
    this.eventId,
    this.question,
    this.options,
    this.status,
    this.totalVotes,
    this.hasVoted,
    this.votedOptionId,
    this.createdAt,
    this.closedAt,
  });

  factory CmePollData.fromJson(Map<String, dynamic> json) {
    return CmePollData(
      id: json['id']?.toString(),
      eventId: json['event_id']?.toString(),
      question: json['question']?.toString(),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => CmePollOption.fromJson(o))
              .toList()
          : null,
      status: json['status']?.toString(),
      totalVotes: json['total_votes'] is int ? json['total_votes'] : int.tryParse(json['total_votes']?.toString() ?? ''),
      hasVoted: json['has_voted'] == true || json['has_voted'] == 1,
      votedOptionId: json['voted_option_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
    );
  }

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
}

class CmePollOption {
  final String? id;
  final String? text;
  final int? votes;
  final double? percentage;

  CmePollOption({this.id, this.text, this.votes, this.percentage});

  factory CmePollOption.fromJson(Map<String, dynamic> json) {
    return CmePollOption(
      id: json['id']?.toString(),
      text: (json['text'] ?? json['option_text'])?.toString(),
      votes: json['votes'] is int ? json['votes'] : int.tryParse(json['votes']?.toString() ?? ''),
      percentage: (json['percentage'] is num)
          ? (json['percentage'] as num).toDouble()
          : double.tryParse(json['percentage']?.toString() ?? ''),
    );
  }
}
