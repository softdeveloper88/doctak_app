import 'dart:convert';
ChatGptSession chatGptSessionFromJson(String str) => ChatGptSession.fromJson(json.decode(str));
String chatGptSessionToJson(ChatGptSession data) => json.encode(data.toJson());
class ChatGptSession {
  ChatGptSession({
      this.success, 
      this.newSessionId, 
      this.sessions,});

  ChatGptSession.fromJson(dynamic json) {
    success = json['success'];
    newSessionId = json['newSessionId'];
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
  Sessions({
      this.id, 
      this.userId, 
      this.name, 
      this.createdAt, 
      this.updatedAt,});

  Sessions.fromJson(dynamic json) {
    id = json['id'];
    userId = json['userId'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
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