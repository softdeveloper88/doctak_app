import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchPeopleBloc extends Bloc<SearchPeopleEvent, SearchPeopleState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> searchPeopleData = [];
  final int nextPageTrigger = 1;

  // Track current search context so pagination uses the same term as the initial load
  String _currentSearchTerm = '';

  SearchPeopleBloc() : super(SearchPeoplePaginationInitialState()) {
    on<SearchPeopleLoadPageEvent>(_onGetUserInfo);
    on<GetPost>(_onGetUserInfo1);
    on<SetUserFollow>(_setUserFollow);

    on<SearchPeopleCheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == searchPeopleData.length - nextPageTrigger) {
        add(SearchPeopleLoadPageEvent(page: pageNumber, searchTerm: _currentSearchTerm));
      }
    });
  }
  bool _isLoading = false;
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();

  // Getter for loading state stream
  Stream<bool> get loadingStream => _loadingController.stream;

  // Function to set loading state
  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    _loadingController.sink.add(_isLoading);
  }

  // Dispose method to close stream controller
  @override
  Future<void> close() {
    _loadingController.close();
    return super.close();
  }

  Future<void> _onGetUserInfo(SearchPeopleLoadPageEvent event, Emitter<SearchPeopleState> emit) async {
    if (event.page == 1) {
      searchPeopleData.clear();
      pageNumber = 1;
      // Store search context for subsequent pagination requests
      _currentSearchTerm = event.searchTerm ?? '';
      emit(SearchPeoplePaginationLoadingState());
    }
    try {
      SearchPeopleModel response = await apiManager.getSearchPeople('Bearer ${AppData.userToken}', '$pageNumber', _currentSearchTerm);
      if (isClosed) return;
      numberOfPage = response.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        searchPeopleData.addAll(response.data ?? []);
      }
      emit(SearchPeoplePaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
      emit(SearchPeopleDataError(e.toString()));
    }
  }

  Future<void> _setUserFollow(SetUserFollow event, Emitter<SearchPeopleState> emit) async {
    try {
      var response = await apiManager.setUserFollow('Bearer ${AppData.userToken}', event.userId, event.follow ?? '');
      if (isClosed) return;
      setLoading(false);
      emit(SearchPeoplePaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
      emit(SearchPeopleDataError('No Data Found'));
    }
  }

  Future<void> _onGetUserInfo1(GetPost event, Emitter<SearchPeopleState> emit) async {
    try {
      SearchPeopleModel response = await apiManager.getSearchPeople('Bearer ${AppData.userToken}', "1", '');
      if (isClosed) return;
      searchPeopleData.clear();
      searchPeopleData.addAll(response.data ?? []);
      emit(SearchPeoplePaginationLoadedState());
    } catch (e) {
      if (isClosed) return;
      emit(SearchPeopleDataError('No Data Found'));
    }
  }
}
