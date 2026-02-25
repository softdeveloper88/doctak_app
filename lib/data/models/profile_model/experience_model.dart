/// Model for Professional Experience (maps to professional_backgrounds table)
class ExperienceModel {
  int? id;
  String? userId;
  String? position;
  String? organization;
  String? location;
  String? startDate;
  String? endDate;
  int? currentStatus; // 1 = currently working
  String? description;
  String? createdAt;
  String? updatedAt;

  ExperienceModel({
    this.id,
    this.userId,
    this.position,
    this.organization,
    this.location,
    this.startDate,
    this.endDate,
    this.currentStatus,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString(),
      position: json['position'] as String?,
      organization: json['organization'] as String?,
      location: json['location'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      currentStatus: json['current_status'] is int
          ? json['current_status']
          : int.tryParse(json['current_status']?.toString() ?? ''),
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'position': position,
      'company_name': organization, // API expects company_name
      'location': location,
      'start_date': startDate,
      'end_date': currentStatus == 1 ? 'Present' : endDate,
      'description': description,
    };
  }

  bool get isCurrentlyWorking => currentStatus == 1;

  String get displayDateRange {
    final start = startDate ?? '';
    final end = isCurrentlyWorking ? 'Present' : (endDate ?? '');
    if (start.isEmpty && end.isEmpty) return '';
    return '$start - $end';
  }
}
