import 'dart:convert';

ChatGptAskQuestionResponse chatGptAskQuestionResponseFromJson(String str) =>
    ChatGptAskQuestionResponse.fromJson(json.decode(str));
String chatGptAskQuestionResponseToJson(ChatGptAskQuestionResponse data) =>
    json.encode(data.toJson());

class ChatGptAskQuestionResponse {
  ChatGptAskQuestionResponse({
    this.content,
    this.responseMessageId,
    this.imageUrl,
  });

  ChatGptAskQuestionResponse.fromJson(dynamic json) {
    content = json['content'] ?? '';
    responseMessageId = json['responseMessageId'];
    imageUrl = json['image_url'];
  }
  String? content;
  int? responseMessageId;
  String? imageUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['content'] = content;
    map['responseMessageId'] = responseMessageId;
    map['image_url'] = imageUrl;
    return map;
  }
}
