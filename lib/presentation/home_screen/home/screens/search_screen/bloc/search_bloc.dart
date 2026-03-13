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

  // Track current filter context so pagination uses the same country/search as the initial load
  String _currentCountryId = '';
  String _currentSearchTerm = '';

  SearchBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetJobs);
    on<GetPost>(_onGetJobs1);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == drugsData.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber, countryId: _currentCountryId, searchTerm: _currentSearchTerm));
      }
    });
  }
  Future<void> _onGetJobs(LoadPageEvent event, Emitter<SearchState> emit) async {
    if (event.page == 1) {
      drugsData.clear();
      pageNumber = 1;
      // Store filter context for subsequent pagination requests
      _currentCountryId = event.countryId ?? '';
      _currentSearchTerm = event.searchTerm ?? '';
      emit(PaginationLoadingState());
    }
    
    try {
      JobsModel response = await apiManager.getSearchJobsList(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
        _currentCountryId,
        _currentSearchTerm,
      );
      if (isClosed) return;
      numberOfPage = response.jobs?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        drugsData.addAll(response.jobs?.data ?? []);
      }
      emit(PaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
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
    try {
      final response = await apiManager.getJobsList(
        'Bearer ${AppData.userToken}',
        "1",
        event.countryId,
        event.searchTerm,
        '',
      );
      if (isClosed) return;
      drugsData.clear();
      drugsData.addAll(response.jobs?.data ?? []);
      emit(PaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
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
