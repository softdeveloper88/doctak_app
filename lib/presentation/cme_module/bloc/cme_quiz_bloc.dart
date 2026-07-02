import 'dart:async';

import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cme_quiz_event.dart';
import 'cme_quiz_state.dart';

enum CmeQuizPhase { intro, question, review, result }

class CmeQuizBloc extends Bloc<CmeQuizEvent, CmeQuizState> {
  CmeQuizData? quiz;
  CmeQuizSubmissionResult? submissionResult;
  Map<String, dynamic> selectedAnswers = {};
  int currentQuestionIndex = 0;
  int remainingSeconds = 0;
  String? startedAt;
  CmeQuizPhase phase = CmeQuizPhase.intro;
  Timer? _countdownTimer;
  String? _eventId;

  CmeQuizBloc() : super(CmeQuizInitialState()) {
    on<CmeLoadQuizEvent>(_onLoadQuiz);
    on<CmeBeginQuizEvent>(_onBeginQuiz);
    on<CmeSelectAnswerEvent>(_onSelectAnswer);
    on<CmeToggleMultiAnswerEvent>(_onToggleMulti);
    on<CmeSetEssayAnswerEvent>(_onSetEssay);
    on<CmeSubmitQuizEvent>(_onSubmitQuiz);
    on<CmeGoToReviewEvent>(_onGoToReview);
    on<CmeResetQuizEvent>(_onResetQuiz);
    on<CmeTimerTickEvent>(_onTimerTick);
    on<CmeNavigateQuestionEvent>(_onNavigateQuestion);
  }

  Future<void> _onLoadQuiz(
    CmeLoadQuizEvent event,
    Emitter<CmeQuizState> emit,
  ) async {
    emit(CmeQuizLoadingState());
    try {
      final data = await CmeNodeApiService.getQuiz(
        event.eventId,
        moduleId: event.moduleId,
        reveal: event.reveal,
      );
      quiz = data;
      _eventId = event.eventId;
      selectedAnswers.clear();
      currentQuestionIndex = 0;
      submissionResult = null;
      startedAt = null;
      remainingSeconds = 0;
      phase = CmeQuizPhase.intro;
      _stopTimer();
      emit(CmeQuizLoadedState());
    } catch (e) {
      emit(CmeQuizErrorState(e.toString()));
    }
  }

  void _onBeginQuiz(CmeBeginQuizEvent event, Emitter<CmeQuizState> emit) {
    if (quiz == null) return;
    startedAt = DateTime.now().toUtc().toIso8601String();
    selectedAnswers.clear();
    currentQuestionIndex = 0;
    phase = CmeQuizPhase.question;
    if (quiz!.hasTimeLimit) {
      remainingSeconds = quiz!.timeLimit! * 60;
      _startCountdown();
    }
    emit(CmeQuizLoadedState());
  }

  void _onSelectAnswer(CmeSelectAnswerEvent event, Emitter<CmeQuizState> emit) {
    selectedAnswers[event.questionId] = event.answer;
    emit(CmeQuizAnswerSelectedState());
  }

  void _onToggleMulti(
    CmeToggleMultiAnswerEvent event,
    Emitter<CmeQuizState> emit,
  ) {
    final current = selectedAnswers[event.questionId];
    final list = current is List
        ? List<String>.from(current.map((e) => e.toString()))
        : <String>[];
    if (list.contains(event.value)) {
      list.remove(event.value);
    } else {
      list.add(event.value);
    }
    selectedAnswers[event.questionId] = list;
    emit(CmeQuizAnswerSelectedState());
  }

  void _onSetEssay(CmeSetEssayAnswerEvent event, Emitter<CmeQuizState> emit) {
    selectedAnswers[event.questionId] = event.text;
    emit(CmeQuizAnswerSelectedState());
  }

  Future<void> _onSubmitQuiz(
    CmeSubmitQuizEvent event,
    Emitter<CmeQuizState> emit,
  ) async {
    if (quiz?.id == null || startedAt == null) return;
    emit(CmeQuizSubmittingState());
    _stopTimer();
    try {
      submissionResult = await CmeNodeApiService.submitQuiz(
        event.eventId,
        quizId: quiz!.id!,
        answers: selectedAnswers,
        startedAt: startedAt,
      );
      final refreshed = await CmeNodeApiService.getQuiz(
        event.eventId,
        moduleId: quiz!.moduleId,
      );
      if (refreshed != null) quiz = refreshed;
      phase = CmeQuizPhase.result;
      emit(CmeQuizSubmittedState());
    } catch (e) {
      emit(CmeQuizErrorState(e.toString()));
    }
  }

  void _onGoToReview(CmeGoToReviewEvent event, Emitter<CmeQuizState> emit) {
    phase = CmeQuizPhase.review;
    emit(CmeQuizLoadedState());
  }

  void _onResetQuiz(CmeResetQuizEvent event, Emitter<CmeQuizState> emit) {
    submissionResult = null;
    selectedAnswers.clear();
    currentQuestionIndex = 0;
    startedAt = null;
    remainingSeconds = 0;
    phase = CmeQuizPhase.intro;
    _stopTimer();
    emit(CmeQuizLoadedState());
  }

  void _onTimerTick(CmeTimerTickEvent event, Emitter<CmeQuizState> emit) {
    remainingSeconds = event.remainingSeconds;
    if (remainingSeconds <= 0) {
      emit(CmeQuizTimerExpiredState());
    } else {
      emit(CmeQuizTimerUpdateState(remainingSeconds));
    }
  }

  void _onNavigateQuestion(
    CmeNavigateQuestionEvent event,
    Emitter<CmeQuizState> emit,
  ) {
    currentQuestionIndex = event.questionIndex;
    phase = CmeQuizPhase.question;
    emit(CmeQuizLoadedState());
  }

  void _startCountdown() {
    final eventId = _eventId;
    if (eventId == null) return;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      if (remainingSeconds <= 0) {
        timer.cancel();
        add(CmeTimerTickEvent(remainingSeconds: 0));
        add(CmeSubmitQuizEvent(eventId: eventId));
      } else {
        add(CmeTimerTickEvent(remainingSeconds: remainingSeconds));
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
  }

  String? get eventId => quiz?.eventId;

  int get totalQuestions => quiz?.questions?.length ?? 0;

  int get answeredCount {
    final questions = quiz?.questions ?? [];
    return questions.where((q) {
      final id = q.id;
      if (id == null) return false;
      final answer = selectedAnswers[id];
      if (answer == null) return false;
      if (answer is List) return answer.isNotEmpty;
      return answer.toString().trim().isNotEmpty;
    }).length;
  }

  bool isQuestionAnswered(String? questionId) {
    if (questionId == null) return false;
    final answer = selectedAnswers[questionId];
    if (answer == null) return false;
    if (answer is List) return answer.isNotEmpty;
    return answer.toString().trim().isNotEmpty;
  }

  dynamic answerFor(String? questionId) => questionId == null ? null : selectedAnswers[questionId];

  String answerSummary(CmeQuizQuestion question) {
    final answer = answerFor(question.id);
    if (answer is List) return answer.join(', ');
    if (answer == null) return '';
    return answer.toString();
  }

  void goNextQuestion() {
    if (currentQuestionIndex < totalQuestions - 1) {
      add(CmeNavigateQuestionEvent(questionIndex: currentQuestionIndex + 1));
    } else {
      add(CmeGoToReviewEvent());
    }
  }

  void goPreviousQuestion() {
    if (phase == CmeQuizPhase.review) {
      phase = CmeQuizPhase.question;
      currentQuestionIndex = totalQuestions - 1;
      add(CmeNavigateQuestionEvent(questionIndex: currentQuestionIndex));
      return;
    }
    if (currentQuestionIndex > 0) {
      add(CmeNavigateQuestionEvent(questionIndex: currentQuestionIndex - 1));
    }
  }

  String get timerDisplay {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
