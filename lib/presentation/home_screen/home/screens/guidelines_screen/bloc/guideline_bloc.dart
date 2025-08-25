import 'dart:async';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuidelinesBloc extends Bloc<GuidelineEvent, GuidelineState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> guidelinesList = [];
  final int nextPageTrigger = 1;

  GuidelinesBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetJobs);
    on<GetPost>(_onGetJobs1);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == guidelinesList.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
  }

  _onGetJobs(LoadPageEvent event, Emitter<GuidelineState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    if (event.page == 1) {
      guidelinesList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
      print(event.searchTerm);
    }
    // ProgressDialogUtils.showProgressDialog();
    try {
      GuidelinesModel response = await apiManager.guideline(
          'Bearer ${AppData.userToken}',
          '${pageNumber}',
          event.searchTerm ?? '');
      numberOfPage = response.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        guidelinesList.addAll(response.data ?? []);
      }
      emit(PaginationLoadedState());

      // emit(DataLoaded(guidelinesList));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }

  _onGetJobs1(GetPost event, Emitter<GuidelineState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    try {
      GuidelinesModel response = await apiManager.guideline(
        'Bearer ${AppData.userToken}',
        "1",
        event.searchTerm,
      );
      print("ddd${response.data!.length}");
      guidelinesList.clear();
      guidelinesList.addAll(response.data ?? []);
      emit(PaginationLoadedState());
      // emit(DataLoaded(guidelinesList));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);

      emit(DataError('No Data Found'));
    }
  }
}
