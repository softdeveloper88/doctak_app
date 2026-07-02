class ProfileCompletedSurvey {
  final String id;
  final String title;
  final String? description;
  final String? surveyType;
  final String? surveyCategory;
  final int questionCount;
  final String? organizationName;
  final String? respondedAt;

  const ProfileCompletedSurvey({
    required this.id,
    required this.title,
    this.description,
    this.surveyType,
    this.surveyCategory,
    this.questionCount = 0,
    this.organizationName,
    this.respondedAt,
  });

  factory ProfileCompletedSurvey.fromJson(Map<String, dynamic> json) {
    int parseCount(dynamic v) =>
        v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;

    return ProfileCompletedSurvey(
      id: '${json['id'] ?? ''}',
      title: (json['title'] ?? 'Survey').toString(),
      description: json['description']?.toString(),
      surveyType: json['surveyType']?.toString() ?? json['survey_type']?.toString(),
      surveyCategory:
          json['surveyCategory']?.toString() ?? json['survey_category']?.toString(),
      questionCount: parseCount(json['questionCount'] ?? json['question_count']),
      organizationName:
          json['organizationName']?.toString() ?? json['organization_name']?.toString(),
      respondedAt: json['respondedAt']?.toString() ?? json['responded_at']?.toString(),
    );
  }
}
