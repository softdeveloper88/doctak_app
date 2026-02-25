/// Model for Awards & Recognitions (maps to awards_and_recognitions table)
class AwardModel {
  int? id;
  String? userId;
  String? awardName;
  String? awardingBody;
  String? dateReceived;
  String? description;
  String? level;
  String? privacy;
  String? createdAt;
  String? updatedAt;

  AwardModel({
    this.id,
    this.userId,
    this.awardName,
    this.awardingBody,
    this.dateReceived,
    this.description,
    this.level,
    this.privacy,
    this.createdAt,
    this.updatedAt,
  });

  factory AwardModel.fromJson(Map<String, dynamic> json) {
    return AwardModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString(),
      awardName: json['award_name'] as String?,
      awardingBody: json['awarding_body'] as String?,
      dateReceived: json['date_received'] as String?,
      description: json['description'] as String?,
      level: json['level'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'award_name': awardName,
      'awarding_body': awardingBody,
      'date_received': dateReceived,
      'description': description,
      'level': level,
      'privacy': privacy,
    };
  }
}
