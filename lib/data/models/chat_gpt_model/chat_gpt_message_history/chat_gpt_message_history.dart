import 'dart:convert';

ChatGptMessageHistory chatGptMessageHistoryFromJson(String str) => ChatGptMessageHistory.fromJson(json.decode(str));
String chatGptMessageHistoryToJson(ChatGptMessageHistory data) => json.encode(data.toJson());

class ChatGptMessageHistory {
  ChatGptMessageHistory({this.success, this.messages});

  ChatGptMessageHistory.fromJson(dynamic json) {
    success = json['success'];
    if (json['messages'] != null) {
      messages = [];
      json['messages'].forEach((v) {
        messages?.add(Messages.fromJson(v));
      });
    }
  }
  bool? success;
  List<Messages>? messages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (messages != null) {
      map['messages'] = messages?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Messages messagesFromJson(String str) => Messages.fromJson(json.decode(str));
String messagesToJson(Messages data) => json.encode(data.toJson());

class Messages {
  Messages({
    this.id,
    this.gptSessionId,
    this.question,
    this.response,
    this.createdAt,
    this.imageUrl1,
    this.imageUrl2,
    this.updatedAt,
    this.imageBytes1,
    this.imageBytes2,
    this.sources,
  });

  Messages.fromJson(dynamic json) {
    id = json['id'];
    final dynamic rawSessionId = json['gptSessionId'] ?? json['session_id'];
    gptSessionId = rawSessionId?.toString();
    question = json['question'];
    response = json['response'];
    createdAt = json['created_at'];
    imageUrl1 = json['image_url'] ?? json['file_url'];
    imageUrl2 = json['image_url2'];
    updatedAt = json['updated_at'];
    if (json['sources'] != null && json['sources'] is List) {
      sources = (json['sources'] as List)
          .map((s) {
            if (s is Map<String, dynamic>) return s;
            if (s is Map) return Map<String, dynamic>.from(s);
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }
  }

  int? id;
  String? gptSessionId;
  String? question;
  String? response;
  String? createdAt;
  String? imageUrl1;
  String? imageUrl2;
  String? updatedAt;
  List<int>? imageBytes1;
  List<int>? imageBytes2;

  /// Citation sources (Apple Guideline 1.4.1). Each map has 'url' and 'title'.
  List<Map<String, dynamic>>? sources;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['gptSessionId'] = gptSessionId;
    map['question'] = question;
    map['response'] = response;
    map['created_at'] = createdAt;
    map['image_url'] = imageUrl1;
    map['image_url2'] = imageUrl2;
    map['updated_at'] = updatedAt;
    if (sources != null) {
      map['sources'] = sources;
    }
    return map;
  }
}
