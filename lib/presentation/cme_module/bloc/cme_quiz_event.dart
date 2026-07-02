import 'package:equatable/equatable.dart';

abstract class CmeQuizEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadQuizEvent extends CmeQuizEvent {
  final String eventId;
  final String? moduleId;
  final bool reveal;

  CmeLoadQuizEvent({
    required this.eventId,
    this.moduleId,
    this.reveal = false,
  });

  @override
  List<Object?> get props => [eventId, moduleId, reveal];
}

class CmeBeginQuizEvent extends CmeQuizEvent {}

class CmeSelectAnswerEvent extends CmeQuizEvent {
  final String questionId;
  final String answer;

  CmeSelectAnswerEvent({required this.questionId, required this.answer});

  @override
  List<Object?> get props => [questionId, answer];
}

class CmeToggleMultiAnswerEvent extends CmeQuizEvent {
  final String questionId;
  final String value;

  CmeToggleMultiAnswerEvent({required this.questionId, required this.value});

  @override
  List<Object?> get props => [questionId, value];
}

class CmeSetEssayAnswerEvent extends CmeQuizEvent {
  final String questionId;
  final String text;

  CmeSetEssayAnswerEvent({required this.questionId, required this.text});

  @override
  List<Object?> get props => [questionId, text];
}

class CmeSubmitQuizEvent extends CmeQuizEvent {
  final String eventId;

  CmeSubmitQuizEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeGoToReviewEvent extends CmeQuizEvent {}

class CmeResetQuizEvent extends CmeQuizEvent {}

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
