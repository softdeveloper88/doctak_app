import 'package:dio/dio.dart';
import 'package:doctak_app/core/errors/failures.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'drugs_event.dart';
import 'drugs_state.dart';

class DrugsBloc extends Bloc<DrugsEvent, DrugsState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> drugsData = [];
  final int nextPageTrigger = 1;

  DrugsBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetJobs);
    on<GetPost>(_onGetJobs1);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == drugsData.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
  }

  _onGetJobs(LoadPageEvent event, Emitter<DrugsState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    if (event.page == 1) {
      drugsData.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
      print(event.countryId);
      print(event.searchTerm);
      print(event.type);
    }

    // ProgressDialogUtils.showProgressDialog();
    // try {
    DrugsModel response = await postService.getDrugsList(
        'Bearer ${AppData.userToken}',
        '${pageNumber}',
        event.countryId ?? "1",
        event.searchTerm ?? '',
        event.type == 'Generic' ? 'Active' : "Brand");
    numberOfPage = response.data?.lastPage ?? 0;
    if (pageNumber < numberOfPage + 1) {
      pageNumber = pageNumber + 1;
      drugsData.addAll(response.data?.data ?? []);
    }
    print(drugsData.toList());
    emit(PaginationLoadedState());

    // emit(DataLoaded(drugsData));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }

  _onGetJobs1(GetPost event, Emitter<DrugsState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();
    print('33' + event.type);
    // emit(PaginationLoadingState());
    // try {
    final response = await postService.getDrugsList(
        'Bearer ${AppData.userToken}',
        "1",
        event.countryId,
        event.searchTerm,
        event.type);
    print("ddd${response.data?.data!.length}");
    drugsData.clear();
    drugsData.addAll(response.data?.data ?? []);
    emit(PaginationLoadedState());
    // emit(DataLoaded(drugsData));
    // } catch (e) {
    //   // ProgressDialogUtils.hideProgressDialog();
    //   print(e);
    //
    //   emit(DataError('No Data Found'));
    // }
  }
}
