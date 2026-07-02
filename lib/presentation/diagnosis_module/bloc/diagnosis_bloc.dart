import 'package:doctak_app/data/apiClient/diagnosis/diagnosis_api_service.dart';
import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'diagnosis_event.dart';
import 'diagnosis_state.dart';

class DiagnosisBloc extends Bloc<DiagnosisEvent, DiagnosisState> {
  // List pagination state
  int pageNumber = 1;
  int numberOfPages = 1;
  List<DiagnosisModel> diagnosisList = [];
  DiagnosisOverview? overview;
  final int nextPageTrigger = 3;
  bool _isLoadingMore = false;

  // Current filters
  String currentSearch = '';
  String? currentContentType;
  String? currentGender;

  bool get hasMorePages => pageNumber <= numberOfPages;

  DiagnosisBloc() : super(DiagnosisInitialState()) {
    on<LoadDiagnosisList>(_onLoadList);
    on<LoadMoreDiagnoses>(_onLoadMore);
    on<LoadDiagnosisDetail>(_onLoadDetail);
    on<SubmitDiagnosis>(_onSubmit);
    on<UpdateDiagnosis>(_onUpdate);
    on<DeleteDiagnosis>(_onDelete);
    on<AnalyzeDiagnosis>(_onAnalyze);
    on<SearchSimilarCases>(_onSearchSimilar);
  }

  Future<void> _onLoadList(
      LoadDiagnosisList event, Emitter<DiagnosisState> emit) async {
    if (event.refresh || diagnosisList.isEmpty) {
      diagnosisList.clear();
      pageNumber = 1;
      _isLoadingMore = false;
      currentSearch = event.search ?? '';
      currentContentType = event.contentType;
      currentGender = event.gender;
      emit(DiagnosisListLoadingState());
    } else if (pageNumber > numberOfPages || _isLoadingMore) {
      // Already loaded all pages or currently loading — skip
      return;
    } else {
      _isLoadingMore = true;
      emit(DiagnosisListLoadingMoreState());
    }

    try {
      final response = await DiagnosisApiService.getDiagnoses(
        page: pageNumber,
        search: currentSearch.isNotEmpty ? currentSearch : null,
        contentType: currentContentType,
        gender: currentGender,
      );

      numberOfPages = response.lastPage;
      overview = response.overview;

      if (pageNumber <= numberOfPages) {
        pageNumber++;
        diagnosisList.addAll(response.diagnoses);
      }
      _isLoadingMore = false;
      emit(DiagnosisListLoadedState());
    } catch (e) {
      _isLoadingMore = false;
      if (diagnosisList.isEmpty) {
        emit(DiagnosisListErrorState('$e'));
      } else {
        emit(DiagnosisListLoadedState());
      }
    }
  }

  Future<void> _onLoadMore(
      LoadMoreDiagnoses event, Emitter<DiagnosisState> emit) async {
    if (event.index >= diagnosisList.length - nextPageTrigger &&
        !_isLoadingMore &&
        pageNumber <= numberOfPages) {
      add(LoadDiagnosisList(
        search: currentSearch,
        contentType: currentContentType,
        gender: currentGender,
      ));
    }
  }

  Future<void> _onLoadDetail(
      LoadDiagnosisDetail event, Emitter<DiagnosisState> emit) async {
    emit(DiagnosisDetailLoadingState());
    try {
      final response = await DiagnosisApiService.getDiagnosis(event.id);
      emit(DiagnosisDetailLoadedState(response));
    } catch (e) {
      emit(DiagnosisDetailErrorState('$e'));
    }
  }

  Future<void> _onSubmit(
      SubmitDiagnosis event, Emitter<DiagnosisState> emit) async {
    emit(DiagnosisSubmittingState());
    try {
      final response =
          await DiagnosisApiService.storeDiagnosis(event.diagnosis);
      if (response.status) {
        emit(DiagnosisSubmittedState(response));
      } else {
        emit(DiagnosisSubmitErrorState(response.message));
      }
    } catch (e) {
      emit(DiagnosisSubmitErrorState('$e'));
    }
  }

  Future<void> _onUpdate(
      UpdateDiagnosis event, Emitter<DiagnosisState> emit) async {
    emit(DiagnosisSubmittingState());
    try {
      final response =
          await DiagnosisApiService.updateDiagnosis(event.id, event.diagnosis);
      if (response.status) {
        emit(DiagnosisSubmittedState(response));
      } else {
        emit(DiagnosisSubmitErrorState(response.message));
      }
    } catch (e) {
      emit(DiagnosisSubmitErrorState('$e'));
    }
  }

  Future<void> _onDelete(
      DeleteDiagnosis event, Emitter<DiagnosisState> emit) async {
    try {
      await DiagnosisApiService.deleteDiagnosis(event.id);
      diagnosisList.removeWhere((d) => d.id == event.id);
      emit(DiagnosisDeletedState());
    } catch (e) {
      emit(DiagnosisDeleteErrorState('$e'));
    }
  }

  Future<void> _onAnalyze(
      AnalyzeDiagnosis event, Emitter<DiagnosisState> emit) async {
    emit(DiagnosisAnalyzingState());
    try {
      final response =
          await DiagnosisApiService.analyzeDiagnosis(event.id, event.contentType);
      if (response.status) {
        emit(DiagnosisAnalyzedState(response));
      } else {
        emit(DiagnosisAnalyzeErrorState('Analysis failed'));
      }
    } catch (e) {
      emit(DiagnosisAnalyzeErrorState('$e'));
    }
  }

  Future<void> _onSearchSimilar(
      SearchSimilarCases event, Emitter<DiagnosisState> emit) async {
    emit(SimilarCasesLoadingState());
    try {
      final cases =
          await DiagnosisApiService.searchSimilar(event.complaint);
      emit(SimilarCasesLoadedState(cases));
    } catch (e) {
      emit(SimilarCasesLoadedState([]));
    }
  }
}
