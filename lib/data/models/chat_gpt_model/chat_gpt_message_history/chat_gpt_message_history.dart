import 'dart:convert';

ChatGptMessageHistory chatGptMessageHistoryFromJson(String str) =>
    ChatGptMessageHistory.fromJson(json.decode(str));
String chatGptMessageHistoryToJson(ChatGptMessageHistory data) =>
    json.encode(data.toJson());

class ChatGptMessageHistory {
  ChatGptMessageHistory({
    this.success,
    this.messages,
  });

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
  });

  Messages.fromJson(dynamic json) {
    id = json['id'];
    gptSessionId = json['gptSessionId'];
    question = json['question'];
    response = json['response'];
    createdAt = json['created_at'];
    imageUrl1 = json['image_url'];
    imageUrl2 = json['image_url2'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? gptSessionId;
  String? question;
  String? response;
  String? createdAt;
  String? imageUrl1;
  String? imageUrl2;
  String? updatedAt;

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
    return map;
  }
}
