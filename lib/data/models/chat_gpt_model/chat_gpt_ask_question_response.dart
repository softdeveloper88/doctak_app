import 'dart:convert';
ChatGptAskQuestionResponse chatGptAskQuestionResponseFromJson(String str) => ChatGptAskQuestionResponse.fromJson(json.decode(str));
String chatGptAskQuestionResponseToJson(ChatGptAskQuestionResponse data) => json.encode(data.toJson());
class ChatGptAskQuestionResponse {
  ChatGptAskQuestionResponse({
      this.content, 
      this.responseMessageId,});

  ChatGptAskQuestionResponse.fromJson(dynamic json) {
    content = json['content'];
    responseMessageId = json['responseMessageId'];
  }
  String? content;
  int? responseMessageId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['content'] = content;
    map['responseMessageId'] = responseMessageId;
    return map;
  }

}