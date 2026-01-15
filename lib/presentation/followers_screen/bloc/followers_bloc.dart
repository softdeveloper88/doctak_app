import 'dart:async';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/followers_model/follower_data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'followers_state.dart';
part 'followers_event.dart';

class FollowersBloc extends Bloc<FollowersEvent, FollowersState> {
  final ApiServiceManager apiManager = ApiServiceManager();
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

  Future<void> _onGetUserInfo(FollowersLoadPageEvent event, Emitter<FollowersState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    // if (event.page == 1) {
    //   searchPeopleData.clear();
    //   pageNumber=1;
    //   emit(FollowersPaginationLoadingState());
    //   print(event.searchTerm);
    // }
    try {
      final response = await apiManager.getUserFollower('Bearer ${AppData.userToken}', event.userId.toString());

      print('🔍 DEBUG: Full API Response: $response');
      print('🔍 DEBUG: Response Type: ${response.runtimeType}');

      // Check if response is already a FollowerDataModel (from SharedApiService)
      if (response is FollowerDataModel) {
        print('✅ Response is already FollowerDataModel');
        followerDataModel = response;
        print('🔍 DEBUG: Followers count: ${followerDataModel?.followers?.length ?? 0}');
        print('🔍 DEBUG: Following count: ${followerDataModel?.following?.length ?? 0}');
        print('🔍 DEBUG: User data exists: ${followerDataModel?.user != null}');
      }
      // Otherwise, try to parse from Map
      else if (response is Map<String, dynamic>) {
        print('🔍 DEBUG: Response Keys: ${response.keys.toList()}');

        try {
          // Check if response has the expected structure
          if (response.containsKey('followers') && response.containsKey('following')) {
            // Response has expected structure
            followerDataModel = FollowerDataModel.fromJson(response);
          } else {
            // Response doesn't have expected structure, adapt it
            print('🔄 DEBUG: Adapting response structure for FollowerDataModel');

            // Create a proper structure
            final adaptedResponse = {
              'total_follows': {'total_followers': '0', 'total_followings': '0'},
              'profile_picture': response['user']?['profile_pic'],
              'cover_picture': response['user']?['background'],
              'total_posts': 0,
              'user': response['user'],
              'followers': response['followers'] ?? [],
              'following': response['following'] ?? [],
            };

            // If there are specific followers/following arrays in the response at different keys
            if (response.containsKey('data')) {
              if (response['data'] is Map && response['data']['followers'] != null) {
                adaptedResponse['followers'] = response['data']['followers'];
              }
              if (response['data'] is Map && response['data']['following'] != null) {
                adaptedResponse['following'] = response['data']['following'];
              }
            }

            followerDataModel = FollowerDataModel.fromJson(adaptedResponse);
          }

          print('🔍 DEBUG: Parsed followers count: ${followerDataModel?.followers?.length ?? 0}');
          print('🔍 DEBUG: Parsed following count: ${followerDataModel?.following?.length ?? 0}');
          print('🔍 DEBUG: User data exists: ${followerDataModel?.user != null}');
        } catch (e) {
          print('❌ Error parsing FollowerDataModel: $e');
          print('❌ Response structure: ${response.toString()}');
          followerDataModel = null;
        }
      } else {
        print('❌ Response is neither FollowerDataModel nor Map<String, dynamic>: ${response.runtimeType}');
        followerDataModel = null;
      }

      emit(FollowersPaginationLoadedState());
    } catch (e) {
      print('❌ Error getting user followers: $e');
      followerDataModel = null;
      emit(FollowersPaginationErrorState(error: e.toString()));
    }

    // emit(DataLoaded(searchPeopleData));
    // } catch (e) {
    //   print(e);
    //
    //   // emit(PaginationLoadedState());
    //
    //   emit(FollowersDataError('No Data Found'));
    // }
  }

  Future<void> _setUserFollow(SetUserFollow event, Emitter<FollowersState> emit) async {
    // emit(DrugsDataInitial());
    // ProgressDialogUtils.showProgressDialog();
    print(event.userId);
    try {
      await apiManager.setUserFollow('Bearer ${AppData.userToken}', event.userId, event.follow);
      // setLoading(false);
      emit(FollowersPaginationLoadedState());
    } catch (e) {
      print(e);

      emit(FollowersDataError('No Data Found'));
    }
  }
}
