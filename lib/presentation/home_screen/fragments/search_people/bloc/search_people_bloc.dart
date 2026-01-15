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

  SearchPeopleBloc() : super(SearchPeoplePaginationInitialState()) {
    on<SearchPeopleLoadPageEvent>(_onGetUserInfo);
    on<GetPost>(_onGetUserInfo1);
    on<SetUserFollow>(_setUserFollow);

    on<SearchPeopleCheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == searchPeopleData.length - nextPageTrigger) {
        add(SearchPeopleLoadPageEvent(page: pageNumber));
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
  void dispose() {
    _loadingController.close();
  }

  Future<void> _onGetUserInfo(SearchPeopleLoadPageEvent event, Emitter<SearchPeopleState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    if (event.page == 1) {
      searchPeopleData.clear();
      pageNumber = 1;
      emit(SearchPeoplePaginationLoadingState());
      print(event.searchTerm);
    }
    // ProgressDialogUtils.showProgressDialog();
    try {
      SearchPeopleModel response = await apiManager.getSearchPeople('Bearer ${AppData.userToken}', '$pageNumber', event.searchTerm ?? '');
      numberOfPage = response.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        searchPeopleData.addAll(response.data ?? []);
      }
      emit(SearchPeoplePaginationLoadedState());

      // emit(DataLoaded(searchPeopleData));
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(SearchPeopleDataError(e.toString()));
    }
  }

  Future<void> _setUserFollow(SetUserFollow event, Emitter<SearchPeopleState> emit) async {
    // emit(DrugsDataInitial());
    // ProgressDialogUtils.showProgressDialog();

    try {
      var response = await apiManager.setUserFollow('Bearer ${AppData.userToken}', event.userId, event.follow ?? '');
      setLoading(false);
      emit(SearchPeoplePaginationLoadedState());
    } catch (e) {
      print(e);

      emit(SearchPeopleDataError('No Data Found'));
    }
  }

  Future<void> _onGetUserInfo1(GetPost event, Emitter<SearchPeopleState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    try {
      SearchPeopleModel response = await apiManager.getSearchPeople('Bearer ${AppData.userToken}', "1", '');
      print("ddd${response.data!.length}");
      searchPeopleData.clear();
      searchPeopleData.addAll(response.data ?? []);
      emit(SearchPeoplePaginationLoadedState());
      // emit(DataLoaded(searchPeopleData));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);
      emit(SearchPeopleDataError('No Data Found'));
    }
  }
}
