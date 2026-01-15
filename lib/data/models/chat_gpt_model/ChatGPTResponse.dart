class ChatGPTResponse {
  final dynamic id;
  final String gptSessionId;
  final String question;
  final String response;
  final String createdAt;
  final String updatedAt;

  ChatGPTResponse({required this.id, required this.gptSessionId, required this.question, required this.response, required this.createdAt, required this.updatedAt});

  factory ChatGPTResponse.fromJson(Map<String, dynamic> json) {
    final rawSessionId = json['gptSessionId'] ?? json['session_id'];
    return ChatGPTResponse(
      id: json['id'],
      gptSessionId: rawSessionId?.toString() ?? '',
      question: json['question'] ?? '',
      response: json['response'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
