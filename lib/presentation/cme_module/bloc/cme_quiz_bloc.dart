import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'cme_quiz_event.dart';
import 'cme_quiz_state.dart';

class CmeQuizBloc extends Bloc<CmeQuizEvent, CmeQuizState> {
  CmeQuizData? quiz;
  CmeQuizAttempt? results;
  Map<String, String> selectedAnswers = {};
  int currentQuestionIndex = 0;
  int remainingSeconds = 0;
  Timer? _autoSaveTimer;
  Timer? _countdownTimer;

  CmeQuizBloc() : super(CmeQuizInitialState()) {
    on<CmeLoadQuizEvent>(_onLoadQuiz);
    on<CmeSelectAnswerEvent>(_onSelectAnswer);
    on<CmeSubmitQuizEvent>(_onSubmitQuiz);
    on<CmeAutoSaveQuizEvent>(_onAutoSave);
    on<CmeLoadQuizResultsEvent>(_onLoadResults);
    on<CmeTimerTickEvent>(_onTimerTick);
    on<CmeNavigateQuestionEvent>(_onNavigateQuestion);
  }

  Future<void> _onLoadQuiz(
      CmeLoadQuizEvent event, Emitter<CmeQuizState> emit) async {
    emit(CmeQuizLoadingState());
    try {
      final data = await CmeApiService.getQuiz(
          event.eventId, event.moduleId, event.quizId);
      quiz = CmeQuizData.fromJson(data['quiz'] ?? data);
      selectedAnswers.clear();
      currentQuestionIndex = 0;

      // Start countdown timer if quiz has time limit
      if (quiz!.hasTimeLimit) {
        remainingSeconds = quiz!.timeLimit! * 60;
        _startCountdown(event.eventId, event.moduleId, event.quizId);
      }

      // Start auto-save timer (every 30 seconds)
      _startAutoSave(event.eventId, event.moduleId, event.quizId);

      emit(CmeQuizLoadedState());
    } catch (e) {
      emit(CmeQuizErrorState(e.toString()));
    }
  }

  Future<void> _onSelectAnswer(
      CmeSelectAnswerEvent event, Emitter<CmeQuizState> emit) async {
    selectedAnswers[event.questionId] = event.answer;
    emit(CmeQuizAnswerSelectedState());
  }

  Future<void> _onSubmitQuiz(
      CmeSubmitQuizEvent event, Emitter<CmeQuizState> emit) async {
    emit(CmeQuizSubmittingState());
    _stopTimers();
    try {
      final answers = selectedAnswers
          .map((key, value) => MapEntry(key.toString(), value));
      final data = await CmeApiService.submitQuiz(
          event.eventId, event.moduleId, event.quizId, answers);
      if (data['result'] != null) {
        results = CmeQuizAttempt.fromJson(data['result']);
      }
      emit(CmeQuizSubmittedState(
        message: data['message'] ?? 'Quiz submitted successfully',
      ));
    } catch (e) {
      emit(CmeQuizErrorState(e.toString()));
    }
  }

  Future<void> _onAutoSave(
      CmeAutoSaveQuizEvent event, Emitter<CmeQuizState> emit) async {
    if (selectedAnswers.isEmpty) return;
    try {
      final answers = selectedAnswers
          .map((key, value) => MapEntry(key.toString(), value));
      await CmeApiService.autoSaveQuiz(
          event.eventId, event.moduleId, event.quizId, answers);
      emit(CmeQuizAutoSavedState());
    } catch (_) {
      // Silent fail for auto-save
    }
  }

  Future<void> _onLoadResults(
      CmeLoadQuizResultsEvent event, Emitter<CmeQuizState> emit) async {
    emit(CmeQuizLoadingState());
    try {
      final data = await CmeApiService.getQuizResults(
          event.eventId, event.moduleId, event.quizId, event.resultId);
      results = CmeQuizAttempt.fromJson(data['result'] ?? data);
      emit(CmeQuizResultsLoadedState());
    } catch (e) {
      emit(CmeQuizErrorState(e.toString()));
    }
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
      CmeNavigateQuestionEvent event, Emitter<CmeQuizState> emit) {
    currentQuestionIndex = event.questionIndex;
    emit(CmeQuizLoadedState());
  }

  void _startCountdown(String eventId, String moduleId, String quizId) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      if (remainingSeconds <= 0) {
        timer.cancel();
        add(CmeTimerTickEvent(remainingSeconds: 0));
        // Auto-submit when time expires
        add(CmeSubmitQuizEvent(
            eventId: eventId, moduleId: moduleId, quizId: quizId));
      } else {
        add(CmeTimerTickEvent(remainingSeconds: remainingSeconds));
      }
    });
  }

  void _startAutoSave(String eventId, String moduleId, String quizId) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(CmeAutoSaveQuizEvent(
          eventId: eventId, moduleId: moduleId, quizId: quizId));
    });
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _autoSaveTimer?.cancel();
  }

  int get totalQuestions => quiz?.questions?.length ?? 0;
  int get answeredCount => selectedAnswers.length;
  bool get allAnswered => answeredCount == totalQuestions;

  String get timerDisplay {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() {
    _stopTimers();
    return super.close();
  }
}
