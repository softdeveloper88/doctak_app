class SurveyQuestion {
  final String id;
  final String question;
  final String questionType;
  final List<String> options;

  const SurveyQuestion({
    required this.id,
    required this.question,
    required this.questionType,
    this.options = const [],
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return SurveyQuestion(
      id: '${json['id'] ?? ''}',
      question: '${json['question'] ?? ''}',
      questionType: '${json['questionType'] ?? json['question_type'] ?? 'text'}',
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}

class SurveyDetail {
  final String id;
  final String title;
  final String? description;
  final String? surveyCategory;
  final int questionCount;
  final int responseCount;
  final bool hasResponded;
  final List<SurveyQuestion> questions;

  const SurveyDetail({
    required this.id,
    required this.title,
    this.description,
    this.surveyCategory,
    this.questionCount = 0,
    this.responseCount = 0,
    this.hasResponded = false,
    this.questions = const [],
  });

  factory SurveyDetail.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((e) => SurveyQuestion.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <SurveyQuestion>[];

    return SurveyDetail(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? 'Survey'}',
      description: json['description']?.toString(),
      surveyCategory: json['surveyCategory']?.toString(),
      questionCount: json['questionCount'] is num
          ? (json['questionCount'] as num).toInt()
          : questions.length,
      responseCount: json['responseCount'] is num
          ? (json['responseCount'] as num).toInt()
          : 0,
      hasResponded: json['hasResponded'] == true,
      questions: questions,
    );
  }
}
