import 'dart:convert';

SendMessageModel messagesFromJson(String str) => SendMessageModel.fromJson(json.decode(str));
String messagesToJson(SendMessageModel data) => json.encode(data.toJson());
class SendMessageModel {
  SendMessageModel({
    this.userId,
    this.profile,
    this.body,
    this.attachment,
    this.attachmentType,
    this.createdAt,});

  SendMessageModel.fromJson(dynamic json) {
    userId = json['user_id'];
    profile = json['profile'];
    body = json['body'];
    attachment = json['attachment'];
    attachmentType = json['attachment_type'];
    createdAt = json['created_at'];
  }
  String? userId;
  String? profile;
  String? body;
  dynamic attachment;
  dynamic attachmentType;
  String? createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['profile'] = profile;
    map['body'] = body;
    map['attachment'] = attachment;
    map['attachment_type'] = attachmentType;
    map['created_at'] = createdAt;
    return map;
  }

}