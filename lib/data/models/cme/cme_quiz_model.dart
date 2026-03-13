class CmeQuizData {
  final String? id;
  final String? eventId;
  final String? moduleId;
  final String? title;
  final String? description;
  final int? timeLimit; // in minutes
  final int? passingScore;
  final int? totalQuestions;
  final int? maxAttempts;
  final bool? shuffleQuestions;
  final bool? showResults;
  final String? status; // active, draft, closed
  final List<CmeQuizQuestion>? questions;
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
    this.latestAttempt,
    this.attemptsUsed,
  });

  factory CmeQuizData.fromJson(Map<String, dynamic> json) {
    return CmeQuizData(
      id: json['id'],
      eventId: json['event_id'],
      moduleId: json['module_id'],
      title: json['title'],
      description: json['description'],
      timeLimit: json['time_limit'],
      passingScore: json['passing_score'],
      totalQuestions: json['total_questions'],
      maxAttempts: json['max_attempts'],
      shuffleQuestions: json['shuffle_questions'],
      showResults: json['show_results'],
      status: json['status'],
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => CmeQuizQuestion.fromJson(q))
              .toList()
          : null,
      latestAttempt: json['latest_attempt'] != null
          ? CmeQuizAttempt.fromJson(json['latest_attempt'])
          : null,
      attemptsUsed: json['attempts_used'],
    );
  }

  bool get canAttempt =>
      status == 'active' &&
      (maxAttempts == null || (attemptsUsed ?? 0) < maxAttempts!);

  bool get hasTimeLimit => timeLimit != null && timeLimit! > 0;
}

class CmeQuizQuestion {
  final String? id;
  final String? questionText;
  final String? questionType; // multiple_choice, true_false, short_answer
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
      id: json['id'],
      questionText: json['question_text'] ?? json['question'],
      questionType: json['question_type'] ?? json['type'],
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => CmeQuizOption.fromJson(o))
              .toList()
          : null,
      points: json['points'],
      explanation: json['explanation'],
      imageUrl: json['image_url'],
      orderIndex: json['order_index'] ?? json['order'],
    );
  }

  bool get isMultipleChoice => questionType == 'multiple_choice';
  bool get isTrueFalse => questionType == 'true_false';
  bool get isShortAnswer => questionType == 'short_answer';
}

class CmeQuizOption {
  final String? id;
  final String? text;
  final bool? isCorrect; // only available after submission/in results
  final String? label; // A, B, C, D

  CmeQuizOption({this.id, this.text, this.isCorrect, this.label});

  factory CmeQuizOption.fromJson(Map<String, dynamic> json) {
    return CmeQuizOption(
      id: json['id'],
      text: json['text'] ?? json['option_text'],
      isCorrect: json['is_correct'],
      label: json['label'],
    );
  }
}

class CmeQuizAttempt {
  final String? id;
  final String? quizId;
  final int? score;
  final int? totalPoints;
  final double? percentage;
  final bool? passed;
  final String? completedAt;
  final int? timeTaken; // in seconds
  final List<CmeQuizAnswerResult>? answers;

  CmeQuizAttempt({
    this.id,
    this.quizId,
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
      id: json['id'],
      quizId: json['quiz_id'],
      score: json['score'],
      totalPoints: json['total_points'],
      percentage: (json['percentage'] as num?)?.toDouble(),
      passed: json['passed'],
      completedAt: json['completed_at'],
      timeTaken: json['time_taken'],
      answers: json['answers'] != null
          ? (json['answers'] as List)
              .map((a) => CmeQuizAnswerResult.fromJson(a))
              .toList()
          : null,
    );
  }

  String get displayScore => '$score/$totalPoints';

  String get displayPercentage =>
      '${percentage?.toStringAsFixed(1) ?? '0'}%';

  String get displayTimeTaken {
    if (timeTaken == null) return '';
    final minutes = timeTaken! ~/ 60;
    final seconds = timeTaken! % 60;
    return '${minutes}m ${seconds}s';
  }
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
      questionId: json['question_id'],
      selectedAnswer: json['selected_answer']?.toString(),
      isCorrect: json['is_correct'],
      correctAnswer: json['correct_answer']?.toString(),
      explanation: json['explanation'],
      pointsEarned: json['points_earned'],
    );
  }
}
