import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_learning_path_model.dart';
import 'cme_learning_path_event.dart';
import 'cme_learning_path_state.dart';

class CmeLearningPathBloc
    extends Bloc<CmeLearningPathEvent, CmeLearningPathState> {
  List<CmeLearningPathData> browsePaths = [];
  List<CmeLearningPathData> enrolledPaths = [];
  List<CmeLearningPathData> completedPaths = [];
  CmeLearningPathData? selectedPath;

  int pageNumber = 1;
  int numberOfPage = 1;
  int nextPageTrigger = 1;

  CmeLearningPathBloc() : super(CmeLearningPathInitialState()) {
    on<CmeBrowseLearningPathsEvent>(_onBrowse);
    on<CmeLoadMyEnrolledPathsEvent>(_onLoadEnrolled);
    on<CmeLoadMyCompletedPathsEvent>(_onLoadCompleted);
    on<CmeLoadPathDetailEvent>(_onLoadDetail);
    on<CmeEnrollInPathEvent>(_onEnroll);
    on<CmeUnenrollFromPathEvent>(_onUnenroll);
    on<CmePausePathEvent>(_onPause);
    on<CmeResumePathEvent>(_onResume);
    on<CmeCheckIfNeedMorePathsEvent>(_onCheckMore);
  }

  Future<void> _onBrowse(
      CmeBrowseLearningPathsEvent event, Emitter<CmeLearningPathState> emit) async {
    if (event.page == 1) {
      browsePaths.clear();
      pageNumber = 1;
    }
    emit(CmeLearningPathLoadingState());
    try {
      final data =
          await CmeApiService.browseLearningPaths(page: event.page);
      final paths = (data['data'] ?? data['learning_paths'] ?? []) as List;
      final newPaths = paths
          .map((p) => CmeLearningPathData.fromJson(p as Map<String, dynamic>))
          .toList();
      browsePaths.addAll(newPaths);

      numberOfPage = data['last_page'] ?? 1;
      pageNumber = event.page + 1;

      emit(CmeLearningPathLoadedState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onLoadEnrolled(
      CmeLoadMyEnrolledPathsEvent event, Emitter<CmeLearningPathState> emit) async {
    emit(CmeLearningPathLoadingState());
    try {
      final data = await CmeApiService.getMyEnrolledPaths();
      final paths =
          (data['data'] ?? data['learning_paths'] ?? []) as List;
      enrolledPaths = paths
          .map((p) => CmeLearningPathData.fromJson(p as Map<String, dynamic>))
          .toList();
      emit(CmeLearningPathLoadedState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onLoadCompleted(
      CmeLoadMyCompletedPathsEvent event, Emitter<CmeLearningPathState> emit) async {
    emit(CmeLearningPathLoadingState());
    try {
      final data = await CmeApiService.getMyCompletedPaths();
      final paths =
          (data['data'] ?? data['learning_paths'] ?? []) as List;
      completedPaths = paths
          .map((p) => CmeLearningPathData.fromJson(p as Map<String, dynamic>))
          .toList();
      emit(CmeLearningPathLoadedState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onLoadDetail(
      CmeLoadPathDetailEvent event, Emitter<CmeLearningPathState> emit) async {
    emit(CmeLearningPathLoadingState());
    try {
      final data =
          await CmeApiService.getLearningPathDetail(event.pathId);
      selectedPath = CmeLearningPathData.fromJson(
          data['learning_path'] ?? data);
      emit(CmeLearningPathDetailLoadedState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onEnroll(
      CmeEnrollInPathEvent event, Emitter<CmeLearningPathState> emit) async {
    try {
      final data =
          await CmeApiService.enrollInLearningPath(event.pathId);
      emit(CmeLearningPathEnrolledState(
        message: data['message']?.toString() ?? 'Enrolled successfully',
      ));
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onUnenroll(
      CmeUnenrollFromPathEvent event, Emitter<CmeLearningPathState> emit) async {
    try {
      await CmeApiService.unenrollFromLearningPath(event.enrollmentId);
      emit(CmeLearningPathUnenrolledState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onPause(
      CmePausePathEvent event, Emitter<CmeLearningPathState> emit) async {
    try {
      await CmeApiService.pauseLearningPath(event.enrollmentId);
      emit(CmeLearningPathPausedState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  Future<void> _onResume(
      CmeResumePathEvent event, Emitter<CmeLearningPathState> emit) async {
    try {
      await CmeApiService.resumeLearningPath(event.enrollmentId);
      emit(CmeLearningPathResumedState());
    } catch (e) {
      emit(CmeLearningPathErrorState(e.toString()));
    }
  }

  void _onCheckMore(
      CmeCheckIfNeedMorePathsEvent event, Emitter<CmeLearningPathState> emit) {
    if (pageNumber <= numberOfPage &&
        event.index == browsePaths.length - nextPageTrigger) {
      add(CmeBrowseLearningPathsEvent(page: pageNumber));
    }
  }
}
