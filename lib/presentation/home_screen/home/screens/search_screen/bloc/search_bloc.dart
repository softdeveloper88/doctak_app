import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> drugsData = [];
  final int nextPageTrigger = 1;

  SearchBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetJobs);
    on<GetPost>(_onGetJobs1);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == drugsData.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
  }
  Future<void> _onGetJobs(LoadPageEvent event, Emitter<SearchState> emit) async {
    print('33 ${event.page}');
    if (event.page == 1) {
      drugsData.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
      print(event.countryId);
      print(event.searchTerm);
      print(event.type);
    }
    
    try {
      JobsModel response = await apiManager.getSearchJobsList(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
        event.countryId ?? "1",
        event.searchTerm ?? '',
      );
      numberOfPage = response.jobs?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        drugsData.addAll(response.jobs?.data ?? []);
      }
      emit(PaginationLoadedState());
    } catch (e) {
      print('Error loading jobs: $e');
      // Show user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Too many requests')) {
        emit(DataError('Please wait a moment before searching again'));
      } else if (errorMessage.contains('Server error')) {
        emit(DataError('Server is temporarily unavailable'));
      } else {
        emit(DataError('Unable to load jobs. Please try again.'));
      }
    }
  }

  Future<void> _onGetJobs1(GetPost event, Emitter<SearchState> emit) async {
    print('33${event.type}');
    try {
      final response = await apiManager.getJobsList(
        'Bearer ${AppData.userToken}',
        "1",
        event.countryId,
        event.searchTerm,
        '',
      );
      print("ddd${response.jobs?.data!.length}");
      drugsData.clear();
      drugsData.addAll(response.jobs?.data ?? []);
      emit(PaginationLoadedState());
    } catch (e) {
      print('Error loading jobs: $e');
      // Show user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Too many requests')) {
        emit(DataError('Please wait a moment before searching again'));
      } else if (errorMessage.contains('Server error')) {
        emit(DataError('Server is temporarily unavailable'));
      } else if (errorMessage.isEmpty || errorMessage == 'null') {
        emit(DataError('No Data Found'));
      } else {
        emit(DataError(errorMessage.replaceAll('Exception: ', '')));
      }
    }
  }
}
