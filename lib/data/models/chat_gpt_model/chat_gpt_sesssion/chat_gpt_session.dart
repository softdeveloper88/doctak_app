import 'dart:convert';

ChatGptSession chatGptSessionFromJson(String str) =>
    ChatGptSession.fromJson(json.decode(str));
String chatGptSessionToJson(ChatGptSession data) => json.encode(data.toJson());

class ChatGptSession {
  ChatGptSession({this.success, this.newSessionId, this.sessions});

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
  }
  bool? success;
  int? newSessionId;
  List<Sessions>? sessions;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['newSessionId'] = newSessionId;
    if (sessions != null) {
      map['sessions'] = sessions?.map((v) => v.toJson()).toList();
    }
    return map;
  }
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
