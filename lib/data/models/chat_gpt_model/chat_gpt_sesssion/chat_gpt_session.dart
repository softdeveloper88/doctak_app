import 'dart:convert';

ChatGptSession chatGptSessionFromJson(String str) => ChatGptSession.fromJson(json.decode(str));
String chatGptSessionToJson(ChatGptSession data) => json.encode(data.toJson());

class ChatGptSession {
  ChatGptSession({this.success, this.newSessionId, this.sessions, this.usage});

  /// Accepts either 'newSessionId' or legacy 'session_id'. Kept as the raw
  /// value (not coerced to int) — the v6 backend's session ids are not
  /// necessarily numeric (e.g. UUIDs), and coercing a non-numeric id to int
  /// silently produced null here, which then made "continue chat" calls
  /// send an empty/invalid session_id even though the initial
  /// image-analysis call (which tolerates a missing session id by creating
  /// one server-side) appeared to work fine.
  ChatGptSession.fromJson(dynamic json) {
    success = json['success'];
    newSessionId = json['newSessionId'] ?? json['session_id'];
    if (json['sessions'] != null) {
      sessions = [];
      json['sessions'].forEach((v) {
        sessions?.add(Sessions.fromJson(v));
      });
    }
    if (json['usage'] != null && json['usage'] is Map) {
      usage = AiUsageInfo.fromJson(Map<String, dynamic>.from(json['usage']));
    }
  }
  bool? success;
  dynamic newSessionId;
  List<Sessions>? sessions;
  AiUsageInfo? usage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['newSessionId'] = newSessionId;
    if (sessions != null) {
      map['sessions'] = sessions?.map((v) => v.toJson()).toList();
    }
    if (usage != null) {
      map['usage'] = usage!.toJson();
    }
    return map;
  }
}

/// Subscription & usage information returned by v6 sessions endpoint (Apple Guideline 1.4.1)
class AiUsageInfo {
  final String planSlug;
  final String planName;
  final int dailyLimit;
  final int dailyUsed;
  final int dailyRemaining;
  final bool canUse;

  const AiUsageInfo({
    this.planSlug = 'free',
    this.planName = 'Free Plan',
    this.dailyLimit = 5,
    this.dailyUsed = 0,
    this.dailyRemaining = 5,
    this.canUse = true,
  });

  factory AiUsageInfo.fromJson(Map<String, dynamic> json) => AiUsageInfo(
    planSlug: json['plan_slug']?.toString() ?? 'free',
    planName: json['plan_name']?.toString() ?? 'Free Plan',
    dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 5,
    dailyUsed: (json['daily_used'] as num?)?.toInt() ?? 0,
    dailyRemaining: (json['daily_remaining'] as num?)?.toInt() ?? 5,
    canUse: json['can_use'] == true,
  );

  Map<String, dynamic> toJson() => {
    'plan_slug': planSlug,
    'plan_name': planName,
    'daily_limit': dailyLimit,
    'daily_used': dailyUsed,
    'daily_remaining': dailyRemaining,
    'can_use': canUse,
  };

  bool get isPaid => planSlug != 'free';
}

Sessions sessionsFromJson(String str) => Sessions.fromJson(json.decode(str));
String sessionsToJson(Sessions data) => json.encode(data.toJson());

class Sessions {
  Sessions({this.id, this.userId, this.name, this.createdAt, this.updatedAt});

  Sessions.fromJson(dynamic json) {
    // Kept as the raw value — see the note on ChatGptSession.newSessionId
    // above for why coercing this to int was corrupting non-numeric ids.
    id = json['id'];
    userId = json['userId']?.toString();
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  dynamic id;
  String? userId;
  String? name;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['userId'] = userId;
    map['name'] = name;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
