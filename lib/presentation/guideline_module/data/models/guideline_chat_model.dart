/// Represents a single message in a guideline chat conversation.
class GuidelineChatMessage {
  final int? id;
  final String role; // 'user' | 'assistant'
  final String content;
  final int? rating;
  final DateTime? createdAt;

  const GuidelineChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.rating,
    this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory GuidelineChatMessage.fromJson(Map<String, dynamic> json) {
    return GuidelineChatMessage(
      id: _parseInt(json['id']),
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      rating: _parseInt(json['rating']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'rating': rating,
        'created_at': createdAt?.toIso8601String(),
      };

  GuidelineChatMessage copyWith({
    int? id,
    String? role,
    String? content,
    int? rating,
    DateTime? createdAt,
  }) {
    return GuidelineChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents a guideline chat session/conversation.
class GuidelineChatSession {
  final String sessionId;
  final String title;
  final int messageCount;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;

  const GuidelineChatSession({
    required this.sessionId,
    required this.title,
    this.messageCount = 0,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  factory GuidelineChatSession.fromJson(Map<String, dynamic> json) {
    return GuidelineChatSession(
      sessionId: json['session_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Guideline Chat',
      messageCount: _parseInt(json['message_count']) ?? 0,
      firstMessageAt: json['first_message_at'] != null
          ? DateTime.tryParse(json['first_message_at'].toString())
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

/// Usage/quota info for the guideline AI feature.
class GuidelineUsageInfo {
  final bool isPaid;
  final bool canUse;
  final int dailyLimit;
  final int dailyUsed;
  final int dailyRemaining;

  const GuidelineUsageInfo({
    this.isPaid = false,
    this.canUse = true,
    this.dailyLimit = 5,
    this.dailyUsed = 0,
    this.dailyRemaining = 5,
  });

  factory GuidelineUsageInfo.fromJson(Map<String, dynamic> json) {
    return GuidelineUsageInfo(
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      canUse: json['can_use'] != false && json['can_use'] != 0,
      dailyLimit: _parseInt(json['daily_limit']) ?? 5,
      dailyUsed: _parseInt(json['daily_used']) ?? 0,
      dailyRemaining: _parseInt(json['daily_remaining']) ?? 5,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

/// Suggested topic for the welcome screen.
class GuidelineSuggestedTopic {
  final String icon;
  final String title;
  final String subtitle;
  final String query;

  const GuidelineSuggestedTopic({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.query,
  });

  factory GuidelineSuggestedTopic.fromJson(Map<String, dynamic> json) {
    return GuidelineSuggestedTopic(
      icon: json['icon'] ?? 'help',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      query: json['query'] ?? '',
    );
  }
}

/// AI Agent response wrapper.
class GuidelineAgentResponse {
  final String response;
  final List<Map<String, dynamic>> sources;
  final List<String> suggestions;
  final String sessionId;

  const GuidelineAgentResponse({
    required this.response,
    this.sources = const [],
    this.suggestions = const [],
    required this.sessionId,
  });

  factory GuidelineAgentResponse.fromJson(Map<String, dynamic> json) {
    return GuidelineAgentResponse(
      response: json['response'] ?? '',
      sources: (json['sources'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sessionId: json['session_id'] ?? '',
    );
  }
}
