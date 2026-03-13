import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/jobs_model/job_applicants_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_detail_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:overlay_support/overlay_support.dart';

import 'jobs_event.dart';
import 'jobs_state.dart';

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> drugsData = [];
  JobDetailModel jobDetailModel = JobDetailModel();
  JobApplicantsModel? jobApplicantsModel = JobApplicantsModel();
  final int nextPageTrigger = 1;

  // Track current filter context so pagination uses the same country/search as the initial load
  String _currentCountryId = '';
  String _currentSearchTerm = '';

  JobsBloc() : super(PaginationInitialState()) {
    on<JobLoadPageEvent>(_onGetJobs);
    on<GetPost>(_onGetJobs1);
    on<JobDetailPageEvent>(_onGetJobDetail);
    on<WithDrawApplicant>(_withDrawApplicant);
    on<ShowApplicantEvent>(_showApplicant);
    on<JobCheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == drugsData.length - nextPageTrigger) {
        add(JobLoadPageEvent(page: pageNumber, countryId: _currentCountryId, searchTerm: _currentSearchTerm));
      }
    });
  }

  Future<void> _onGetJobs(JobLoadPageEvent event, Emitter<JobsState> emit) async {
    if (event.page == 1) {
      drugsData.clear();
      pageNumber = 1;
      // Store filter context for subsequent pagination requests
      _currentCountryId = event.countryId ?? '';
      _currentSearchTerm = event.searchTerm ?? '';
      emit(PaginationLoadingState());
    }
    try {
      JobsModel response = await apiManager.getJobsList('Bearer ${AppData.userToken}', '$pageNumber', _currentCountryId, _currentSearchTerm, "");
      if (isClosed) return;
      numberOfPage = response.jobs?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        drugsData.addAll(response.jobs?.data ?? []);
      }
      emit(PaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _onGetJobDetail(JobDetailPageEvent event, Emitter<JobsState> emit) async {
    emit(PaginationLoadingState());
    try {
      // Use the SharedApiService directly for job details
      final response = await apiManager.sharedApi.getJobDetails(jobId: event.jobId.toString());
      if (isClosed) return;
      if (response.success) {
        jobDetailModel = response.data!; // response.data is already a JobDetailModel
        emit(PaginationLoadedState());
      } else {
        emit(DataError(response.message ?? 'Failed to get job details'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _onGetJobs1(GetPost event, Emitter<JobsState> emit) async {
    try {
      JobsModel response = await apiManager.getJobsList('Bearer ${AppData.userToken}', "1", event.countryId, event.searchTerm, ""); // Empty string to get all jobs
      if (isClosed) return;
      drugsData.clear();
      drugsData.addAll(response.jobs?.data ?? []);
      emit(PaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _withDrawApplicant(WithDrawApplicant event, Emitter<JobsState> emit) async {
    emit(PaginationLoadingState());
    try {
      // Use the SharedApiService for withdrawing application
      final response = await apiManager.sharedApi.withdrawJobApplication(jobId: event.jobId.toString());
      if (isClosed) return;
      if (response.success) {
        toast(response.data?['message'] ?? 'Application withdrawn successfully');

        // Reload job details after successful withdrawal
        add(JobDetailPageEvent(jobId: event.jobId));
        return; // Return early to let JobDetailPageEvent handle the emission
      } else {
        emit(PaginationLoadedState());
        toast(response.message ?? 'Failed to withdraw application');
      }
    } catch (e) {
      if (isClosed) return;
      emit(PaginationLoadedState());
      toast('Failed to withdraw application');
    }
  }

  Future<void> _showApplicant(ShowApplicantEvent event, Emitter<JobsState> emit) async {
    emit(PaginationLoadingState());
    try {
      // Use the SharedApiService for getting job applicants
      final response = await apiManager.sharedApi.getJobApplicants(jobId: event.jobId.toString());
      if (isClosed) return;
      if (response.success) {
        jobApplicantsModel = response.data!; // response.data is already a JobApplicantsModel
        emit(PaginationLoadedState());
      } else {
        emit(DataError(response.message ?? 'Failed to get job applicants'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(DataError('Failed to get job applicants'));
    }
  }
}
