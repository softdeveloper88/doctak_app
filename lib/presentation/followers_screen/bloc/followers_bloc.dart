import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/followers_model/follower_data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';

part 'followers_state.dart';
part 'followers_event.dart';

class FollowersBloc extends Bloc<FollowersEvent, FollowersState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  FollowerDataModel? followerDataModel;
  final int nextPageTrigger = 1;

  FollowersBloc() : super(FollowersPaginationInitialState()) {
    on<FollowersLoadPageEvent>(_onGetUserInfo);
    // on<GetPost>(_onGetUserInfo1);
    on<SetUserFollow>(_setUserFollow);
    // on<FollowersCheckIfNeedMoreDataEvent>((event, emit) async {
    //   // emit(PaginationLoadingState());
    //   if (event.index == searchPeopleData.length - nextPageTrigger) {
    //     add(FollowersLoadPageEvent(page: pageNumber));
    //   }
    // });
  }

  bool _isLoading = false;
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();

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

  _onGetUserInfo(
      FollowersLoadPageEvent event, Emitter<FollowersState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    // if (event.page == 1) {
    //   searchPeopleData.clear();
    //   pageNumber=1;
    //   emit(FollowersPaginationLoadingState());
    //   print(event.searchTerm);
    // }
    // ProgressDialogUtils.showProgressDialog();
    // try {
    followerDataModel = await postService.getUserFollower(
        'Bearer ${AppData.userToken}', event.userId.toString());

    // numberOfPage = response.lastPage ?? 0;
    // if (pageNumber < numberOfPage+1) {
    //   pageNumber = pageNumber + 1;
    //   searchPeopleData.addAll(response.data??[]);
    // }
    emit(FollowersPaginationLoadedState());

    // emit(DataLoaded(searchPeopleData));
    // } catch (e) {
    //   print(e);
    //
    //   // emit(PaginationLoadedState());
    //
    //   emit(FollowersDataError('No Data Found'));
    // }
  }

  _setUserFollow(SetUserFollow event, Emitter<FollowersState> emit) async {
    // emit(DrugsDataInitial());
    // ProgressDialogUtils.showProgressDialog();
    print(
      event.userId,
    );
    try {
      var response = await postService.setUserFollow(
          'Bearer ${AppData.userToken}', event.userId, event.follow ?? '');
      // setLoading(false);
      emit(FollowersPaginationLoadedState());
    } catch (e) {
      print(e);

      emit(FollowersDataError('No Data Found'));
    }
  }
}
