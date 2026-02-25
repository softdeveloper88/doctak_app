import 'dart:convert';

import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';

ChatGptAskQuestionResponse chatGptAskQuestionResponseFromJson(String str) =>
    ChatGptAskQuestionResponse.fromJson(json.decode(str));
String chatGptAskQuestionResponseToJson(ChatGptAskQuestionResponse data) =>
    json.encode(data.toJson());

/// A single citation source returned with AI responses.
/// Required for Apple App Store Guideline 1.4.1 (Safety - Physical Harm) compliance.
class CitationSource {
  final String url;
  final String? title;

  CitationSource({required this.url, this.title});

  factory CitationSource.fromJson(Map<String, dynamic> json) {
    return CitationSource(
      url: json['url'] as String? ?? '',
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'title': title};
}

class ChatGptAskQuestionResponse {
  ChatGptAskQuestionResponse({
    this.content,
    this.responseMessageId,
    this.imageUrl,
    this.imageUrl2,
    this.sources,
    this.analysisType,
    this.usage,
  });

  ChatGptAskQuestionResponse.fromJson(dynamic json) {
    content = json['content'] ?? '';
    responseMessageId = json['responseMessageId'] ?? json['response_message_id'];
    imageUrl = json['image_url'] ?? json['file_url'];
    imageUrl2 = json['image_url2'];
    analysisType = json['analysis_type'];
    if (json['sources'] != null && json['sources'] is List) {
      sources = (json['sources'] as List)
          .map((s) => CitationSource.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    if (json['usage'] != null && json['usage'] is Map) {
      usage = AiUsageInfo.fromJson(Map<String, dynamic>.from(json['usage']));
    }
  }

  String? content;
  int? responseMessageId;
  String? imageUrl;
  String? imageUrl2;
  String? analysisType;
  List<CitationSource>? sources; // ← Citation links (Apple Guideline 1.4.1)
  AiUsageInfo? usage; // ← Real-time quota info from each response

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['content'] = content;
    map['responseMessageId'] = responseMessageId;
    map['image_url'] = imageUrl;
    map['image_url2'] = imageUrl2;
    map['analysis_type'] = analysisType;
    map['sources'] = sources?.map((s) => s.toJson()).toList();
    if (usage != null) map['usage'] = usage!.toJson();
    return map;
  }
}
