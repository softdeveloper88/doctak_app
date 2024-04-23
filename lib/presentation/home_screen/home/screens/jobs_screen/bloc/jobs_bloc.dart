
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'jobs_event.dart';
import 'jobs_state.dart';

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> drugsData = [];
  final int nextPageTrigger = 1;

  JobsBloc() : super(PaginationInitialState()) {
    on<JobLoadPageEvent>(_onGetJobs);
    on<GetPost>(_onGetJobs1);
    on<JobCheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == drugsData.length - nextPageTrigger) {
        add(JobLoadPageEvent(page: pageNumber));
      }
    });
  }

  _onGetJobs(JobLoadPageEvent event, Emitter<JobsState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    print('search text ${event.searchTerm}');
    print('country id ${event.countryId}');
    print('country id ${event.isExpired}');
    if (event.page == 1) {
      drugsData.clear();
      pageNumber=1;
      emit(PaginationLoadingState());
      print(event.countryId);
      print(event.searchTerm);
    }
    // ProgressDialogUtils.showProgressDialog();
    try {
      JobsModel response = await postService.getJobsList(
          'Bearer ${AppData.userToken}',
          '${pageNumber}',
          event.countryId??"1",
          event.searchTerm??'',
         event.isExpired=='New'? "false":'true');
      numberOfPage = response.jobs?.lastPage ?? 0;
      if (pageNumber < numberOfPage+1) {
        pageNumber = pageNumber + 1;
        drugsData.addAll(response.jobs?.data ?? []);
      }
      emit(PaginationLoadedState());

      // emit(DataLoaded(drugsData));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }

  _onGetJobs1(GetPost event, Emitter<JobsState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    try {
      JobsModel response = await postService.getJobsList(
          'Bearer ${AppData.userToken}',
          "1",
          event.countryId,
          event.searchTerm,
         'false'
      );
      print("ddd${response.jobs?.data!.length}");
      drugsData.clear();
      drugsData.addAll(response.jobs?.data ?? []);
      emit(PaginationLoadedState());
      // emit(DataLoaded(drugsData));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);

      emit(DataError('No Data Found'));
    }
  }
}
