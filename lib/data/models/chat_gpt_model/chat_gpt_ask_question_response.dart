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
    this.imageUrl2,
  });

  ChatGptAskQuestionResponse.fromJson(dynamic json) {
    content = json['content'] ?? '';
    responseMessageId = json['responseMessageId'];
    imageUrl = json['image_url'];
    imageUrl2 = json['image_url2'];
  }
  String? content;
  int? responseMessageId;
  String? imageUrl;
  String? imageUrl2;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['content'] = content;
    map['responseMessageId'] = responseMessageId;
    map['image_url'] = imageUrl;
    map['image_url2'] = imageUrl2;
    return map;
  }
}
