import 'dart:convert';
MessageModel messageModelFromJson(String str) => MessageModel.fromJson(json.decode(str));
String messageModelToJson(MessageModel data) => json.encode(data.toJson());
class MessageModel {
  MessageModel({
      this.success, 
      this.roomId, 
      this.messages, 
      this.total, 
      this.lastPage,});

  MessageModel.fromJson(dynamic json) {
    success = json['success'];
    roomId = json['room_id'];
    if (json['messages'] != null) {
      messages = [];
      json['messages'].forEach((v) {
        messages?.add(Messages.fromJson(v));
      });
    }
    total = json['total'];
    lastPage = json['last_page'];
  }
  bool? success;
  dynamic roomId;
  List<Messages>? messages;
  int? total;
  int? lastPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['room_id'] = roomId;
    if (messages != null) {
      map['messages'] = messages?.map((v) => v.toJson()).toList();
    }
    map['total'] = total;
    map['last_page'] = lastPage;
    return map;
  }

}

Messages messagesFromJson(String str) => Messages.fromJson(json.decode(str));
String messagesToJson(Messages data) => json.encode(data.toJson());
class Messages {
  Messages({
      this.id,
      this.userId,
      this.profile,
      this.body, 
      this.attachment, 
      this.attachmentType, 
      this.createdAt,});

  Messages.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    profile = json['profile'];
    body = json['body'];
    attachment = json['attachment'];
    attachmentType = json['attachment_type'];
    createdAt = json['created_at'];
  }
  String? id;
  String? userId;
  String? profile;
  String? body;
  dynamic attachment;
  dynamic attachmentType;
  String? createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['profile'] = profile;
    map['body'] = body;
    map['attachment'] = attachment;
    map['attachment_type'] = attachmentType;
    map['created_at'] = createdAt;
    return map;
  }

}