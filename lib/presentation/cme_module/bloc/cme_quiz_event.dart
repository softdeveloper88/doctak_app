import 'package:equatable/equatable.dart';

abstract class CmeQuizEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadQuizEvent extends CmeQuizEvent {
  final String eventId;
  final String moduleId;
  final String quizId;

  CmeLoadQuizEvent({
    required this.eventId,
    required this.moduleId,
    required this.quizId,
  });

  @override
  List<Object?> get props => [eventId, moduleId, quizId];
}

class CmeSelectAnswerEvent extends CmeQuizEvent {
  final String questionId;
  final String answer;

  CmeSelectAnswerEvent({required this.questionId, required this.answer});

  @override
  List<Object?> get props => [questionId, answer];
}

class CmeSubmitQuizEvent extends CmeQuizEvent {
  final String eventId;
  final String moduleId;
  final String quizId;

  CmeSubmitQuizEvent({
    required this.eventId,
    required this.moduleId,
    required this.quizId,
  });

  @override
  List<Object?> get props => [eventId, moduleId, quizId];
}

class CmeAutoSaveQuizEvent extends CmeQuizEvent {
  final String eventId;
  final String moduleId;
  final String quizId;

  CmeAutoSaveQuizEvent({
    required this.eventId,
    required this.moduleId,
    required this.quizId,
  });

  @override
  List<Object?> get props => [eventId, moduleId, quizId];
}

class CmeLoadQuizResultsEvent extends CmeQuizEvent {
  final String eventId;
  final String moduleId;
  final String quizId;
  final String resultId;

  CmeLoadQuizResultsEvent({
    required this.eventId,
    required this.moduleId,
    required this.quizId,
    required this.resultId,
  });

  @override
  List<Object?> get props => [eventId, moduleId, quizId, resultId];
}

class CmeTimerTickEvent extends CmeQuizEvent {
  final int remainingSeconds;

  CmeTimerTickEvent({required this.remainingSeconds});

  @override
  List<Object?> get props => [remainingSeconds];
}

class CmeNavigateQuestionEvent extends CmeQuizEvent {
  final int questionIndex;

  CmeNavigateQuestionEvent({required this.questionIndex});

  @override
  List<Object?> get props => [questionIndex];
}
