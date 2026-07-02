class CmeQuizData {
  final String? id;
  final String? eventId;
  final String? moduleId;
  final String? title;
  final String? description;
  final int? timeLimit;
  final int? passingScore;
  final int? totalQuestions;
  final int? maxAttempts;
  final bool? shuffleQuestions;
  final bool? showResults;
  final String? status;
  final List<CmeQuizQuestion>? questions;
  final List<CmeQuizAttempt>? myAttempts;
  final CmeQuizAttempt? latestAttempt;
  final int? attemptsUsed;

  CmeQuizData({
    this.id,
    this.eventId,
    this.moduleId,
    this.title,
    this.description,
    this.timeLimit,
    this.passingScore,
    this.totalQuestions,
    this.maxAttempts,
    this.shuffleQuestions,
    this.showResults,
    this.status,
    this.questions,
    this.myAttempts,
    this.latestAttempt,
    this.attemptsUsed,
  });

  factory CmeQuizData.fromJson(Map<String, dynamic> json) {
    return CmeQuizData(
      id: json['id']?.toString(),
      eventId: json['event_id']?.toString(),
      moduleId: json['module_id']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      timeLimit: _asInt(json['time_limit']),
      passingScore: _asInt(json['passing_score']),
      totalQuestions: _asInt(json['total_questions']),
      maxAttempts: _asInt(json['max_attempts']),
      shuffleQuestions: json['shuffle_questions'] == true,
      showResults: json['show_results'] == true,
      status: json['status']?.toString(),
      questions: _parseQuestions(json['questions']),
      myAttempts: _parseAttempts(json['my_attempts'] ?? json['myAttempts']),
      latestAttempt: json['latest_attempt'] != null
          ? CmeQuizAttempt.fromJson(Map<String, dynamic>.from(json['latest_attempt'] as Map))
          : null,
      attemptsUsed: _asInt(json['attempts_used']),
    );
  }

  factory CmeQuizData.fromNodeJson(Map<String, dynamic> json) {
    final attempts = _parseAttempts(json['myAttempts']);
    return CmeQuizData(
      id: json['id']?.toString(),
      eventId: json['eventId']?.toString(),
      moduleId: json['moduleId']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      timeLimit: _asInt(json['timeLimitMinutes']),
      passingScore: _asInt(json['passingScore']) ?? 70,
      maxAttempts: _asInt(json['maxAttempts']) ?? 3,
      shuffleQuestions: json['randomizeQuestions'] == true,
      showResults: json['showResultsImmediately'] == true,
      questions: _parseQuestions(json['questions']),
      myAttempts: attempts,
      attemptsUsed: attempts?.length,
    );
  }

  static List<CmeQuizQuestion>? _parseQuestions(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .map((q) => CmeQuizQuestion.fromNodeJson(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  static List<CmeQuizAttempt>? _parseAttempts(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .map((a) => CmeQuizAttempt.fromNodeJson(Map<String, dynamic>.from(a as Map)))
        .toList();
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  int get attemptsLeft {
    final max = maxAttempts ?? 0;
    if (max >= 999) return 999;
    final used = myAttempts?.length ?? attemptsUsed ?? 0;
    return (max - used).clamp(0, max);
  }

  bool get passed => myAttempts?.any((a) => a.passed == true) ?? false;

  bool get canAttempt => attemptsLeft > 0 && !passed;

  bool get hasTimeLimit => timeLimit != null && timeLimit! > 0;
}

class CmeQuizQuestion {
  final String? id;
  final String? questionText;
  final String? questionType;
  final List<CmeQuizOption>? options;
  final int? points;
  final String? explanation;
  final String? imageUrl;
  final int? orderIndex;

  CmeQuizQuestion({
    this.id,
    this.questionText,
    this.questionType,
    this.options,
    this.points,
    this.explanation,
    this.imageUrl,
    this.orderIndex,
  });

  factory CmeQuizQuestion.fromJson(Map<String, dynamic> json) {
    return CmeQuizQuestion(
      id: json['id']?.toString(),
      questionText: json['question_text']?.toString() ?? json['question']?.toString(),
      questionType: json['question_type']?.toString() ?? json['type']?.toString(),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => CmeQuizOption.fromJson(
                    o is Map<String, dynamic>
                        ? o
                        : o is Map
                            ? Map<String, dynamic>.from(o)
                            : {'text': '$o'},
                  ))
              .toList()
          : null,
      points: CmeQuizData._asInt(json['points']),
      explanation: json['explanation']?.toString(),
      imageUrl: json['image_url']?.toString(),
      orderIndex: CmeQuizData._asInt(json['order_index'] ?? json['order']),
    );
  }

  factory CmeQuizQuestion.fromNodeJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<CmeQuizOption>? options;
    if (rawOptions is List) {
      options = rawOptions.asMap().entries.map((entry) {
        final value = entry.value;
        if (value is Map) {
          return CmeQuizOption.fromJson(Map<String, dynamic>.from(value));
        }
        final text = value.toString();
        return CmeQuizOption(
          id: text,
          text: text,
          label: String.fromCharCode(65 + entry.key),
        );
      }).toList();
    }

    return CmeQuizQuestion(
      id: json['id']?.toString(),
      questionText: json['questionText']?.toString(),
      questionType: json['questionType']?.toString(),
      options: options,
      points: CmeQuizData._asInt(json['points']) ?? 1,
      explanation: json['explanation']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      orderIndex: CmeQuizData._asInt(json['orderIndex']),
    );
  }

  bool get isMultipleChoice => questionType == 'multiple_choice';
  bool get isMultipleSelect => questionType == 'multiple_select';
  bool get isTrueFalse => questionType == 'true_false';
  bool get isEssay => questionType == 'essay';
  bool get isShortAnswer => questionType == 'short_answer' || isEssay;

  String get typeHint {
    if (isMultipleSelect) return 'Select all that apply';
    if (isEssay) return 'Written response';
    if (isTrueFalse) return 'True or false';
    return 'Choose one answer';
  }
}

class CmeQuizOption {
  final String? id;
  final String? text;
  final bool? isCorrect;
  final String? label;

  CmeQuizOption({this.id, this.text, this.isCorrect, this.label});

  factory CmeQuizOption.fromJson(Map<String, dynamic> json) {
    final text = json['text']?.toString() ?? json['option_text']?.toString();
    return CmeQuizOption(
      id: json['id']?.toString() ?? text,
      text: text,
      isCorrect: json['is_correct'] == true,
      label: json['label']?.toString(),
    );
  }

  String get value => text ?? id ?? '';
}

class CmeQuizAttempt {
  final String? id;
  final String? quizId;
  final int? attemptNumber;
  final int? score;
  final int? totalPoints;
  final double? percentage;
  final bool? passed;
  final String? completedAt;
  final int? timeTaken;
  final List<CmeQuizAnswerResult>? answers;

  CmeQuizAttempt({
    this.id,
    this.quizId,
    this.attemptNumber,
    this.score,
    this.totalPoints,
    this.percentage,
    this.passed,
    this.completedAt,
    this.timeTaken,
    this.answers,
  });

  factory CmeQuizAttempt.fromJson(Map<String, dynamic> json) {
    return CmeQuizAttempt(
      id: json['id']?.toString(),
      quizId: json['quiz_id']?.toString(),
      attemptNumber: CmeQuizData._asInt(json['attempt_number']),
      score: CmeQuizData._asInt(json['score']),
      totalPoints: CmeQuizData._asInt(json['total_points']),
      percentage: (json['percentage'] as num?)?.toDouble(),
      passed: json['passed'] == true,
      completedAt: json['completed_at']?.toString(),
      timeTaken: CmeQuizData._asInt(json['time_taken']),
      answers: json['answers'] != null
          ? (json['answers'] as List)
              .map((a) => CmeQuizAnswerResult.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList()
          : null,
    );
  }

  factory CmeQuizAttempt.fromNodeJson(Map<String, dynamic> json) {
    final score = json['score'];
    return CmeQuizAttempt(
      id: json['id']?.toString(),
      quizId: json['quizId']?.toString(),
      attemptNumber: CmeQuizData._asInt(json['attemptNumber']),
      score: score is num ? score.round() : CmeQuizData._asInt(score),
      totalPoints: CmeQuizData._asInt(json['totalPoints']),
      percentage: score is num ? score.toDouble() : null,
      passed: json['passed'] == true,
      completedAt: json['endTime']?.toString(),
      timeTaken: CmeQuizData._asInt(json['timeTakenSeconds']),
    );
  }

  String get displayScore => '$score/$totalPoints';

  String get displayPercentage => '${percentage?.round() ?? score ?? 0}%';

  String get displayTimeTaken {
    if (timeTaken == null) return '';
    final minutes = timeTaken! ~/ 60;
    final seconds = timeTaken! % 60;
    return '${minutes}m ${seconds}s';
  }
}

class CmeQuizSubmissionResult {
  const CmeQuizSubmissionResult({
    required this.score,
    required this.totalPoints,
    required this.earnedPoints,
    required this.passed,
    required this.passingScore,
    required this.pendingEssayReview,
    this.attemptId,
  });

  factory CmeQuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    return CmeQuizSubmissionResult(
      attemptId: json['attemptId']?.toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      totalPoints: CmeQuizData._asInt(json['totalPoints']) ?? 0,
      earnedPoints: CmeQuizData._asInt(json['earnedPoints']) ?? 0,
      passed: json['passed'] == true,
      passingScore: CmeQuizData._asInt(json['passingScore']) ?? 70,
      pendingEssayReview: json['pendingEssayReview'] == true,
    );
  }

  final String? attemptId;
  final double score;
  final int totalPoints;
  final int earnedPoints;
  final bool passed;
  final int passingScore;
  final bool pendingEssayReview;
}

class CmeQuizAnswerResult {
  final String? questionId;
  final String? selectedAnswer;
  final bool? isCorrect;
  final String? correctAnswer;
  final String? explanation;
  final int? pointsEarned;

  CmeQuizAnswerResult({
    this.questionId,
    this.selectedAnswer,
    this.isCorrect,
    this.correctAnswer,
    this.explanation,
    this.pointsEarned,
  });

  factory CmeQuizAnswerResult.fromJson(Map<String, dynamic> json) {
    return CmeQuizAnswerResult(
      questionId: json['question_id']?.toString(),
      selectedAnswer: json['selected_answer']?.toString(),
      isCorrect: json['is_correct'] == true,
      correctAnswer: json['correct_answer']?.toString(),
      explanation: json['explanation']?.toString(),
      pointsEarned: CmeQuizData._asInt(json['points_earned']),
    );
  }
}
