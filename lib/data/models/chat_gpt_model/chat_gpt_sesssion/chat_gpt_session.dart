import 'dart:convert';

ChatGptSession chatGptSessionFromJson(String str) => ChatGptSession.fromJson(json.decode(str));
String chatGptSessionToJson(ChatGptSession data) => json.encode(data.toJson());

class ChatGptSession {
  ChatGptSession({this.success, this.newSessionId, this.sessions, this.usage});

  /// Accepts either 'newSessionId' or legacy 'session_id' and supports int or String values.
  ChatGptSession.fromJson(dynamic json) {
    success = json['success'];
    final dynamic rawId = json['newSessionId'] ?? json['session_id'];
    newSessionId = _asInt(rawId);
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
  int? newSessionId;
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
    id = _asInt(json['id']);
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

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value);
  }
  // Attempt toString parse for other numeric types
  return int.tryParse(value.toString());
}
