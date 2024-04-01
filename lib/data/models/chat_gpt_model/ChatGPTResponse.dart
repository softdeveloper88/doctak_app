class ChatGPTResponse {
  final int id;
  final String gptSessionId;
  final String question;
  final String response;
  final String createdAt;
  final String updatedAt;

  ChatGPTResponse({
    required this.id,
    required this.gptSessionId,
    required this.question,
    required this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatGPTResponse.fromJson(Map<String, dynamic> json) {
    return ChatGPTResponse(
      id: json['id'],
      gptSessionId: json['gptSessionId'],
      question: json['question'],
      response: json['response'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
