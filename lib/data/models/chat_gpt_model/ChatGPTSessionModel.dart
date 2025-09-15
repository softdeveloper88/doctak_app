class Session {
  final dynamic id;
  final String? userId;
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  Session({
    required this.id,
    this.userId,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
