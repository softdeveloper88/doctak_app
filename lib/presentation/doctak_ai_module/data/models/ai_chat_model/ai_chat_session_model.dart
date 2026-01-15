import 'dart:convert';

class AiChatSessionModel {
  final int id;
  final String userId;
  String name;
  final String? type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AiChatSessionModel({required this.id, required this.userId, required this.name, this.type, required this.createdAt, required this.updatedAt, this.deletedAt});

  factory AiChatSessionModel.fromJson(Map<String, dynamic> json) {
    return AiChatSessionModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'user_id': userId, 'name': name, 'type': type, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(), 'deleted_at': deletedAt?.toIso8601String()};
  }

  // For local storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from local storage
  factory AiChatSessionModel.fromJsonString(String jsonString) {
    return AiChatSessionModel.fromJson(jsonDecode(jsonString));
  }
}
