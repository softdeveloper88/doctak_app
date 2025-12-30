import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Post> postList = [];
  final int nextPageTrigger = 1;
  var postData;

  // Connectivity monitoring for auto-retry
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  HomeBloc() : super(DataInitial()) {
    on<PostLoadPageEvent>(_onGetPosts);
    on<LoadSearchPageEvent>(_onGetSearchPosts);
    on<AdsSettingEvent>(_adsSettingApi);
    on<PostLikeEvent>(_onPostLike);
    on<DeletePostEvent>(_onDeletePost);
    on<DetailsPostEvent>(_onGetDetailsPosts);
    on<PostCheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(PostLoadPageEvent(page: pageNumber));
      }
    });

    // Start listening for connectivity changes to auto-retry pending likes
    _startConnectivityMonitoring();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasConnection && _pendingLikeRequests.isNotEmpty) {
        print(
          '📶 Network reconnected - retrying ${_pendingLikeRequests.length} pending likes',
        );
        retryPendingLikeRequests();
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  _onGetPosts(PostLoadPageEvent event, Emitter<HomeState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PostPaginationLoadingState());
    }
    try {
      var response1 = await apiManager.getPosts(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
      );
      final response = PostDataModel.fromJson(response1.response.data!);
      if (response1.response.statusCode == 302) {
        print(' Error 302 ${response1.response.data}');
        emit(PostDataError('An error occurred'));
      }
      print(response1);
      numberOfPage = response.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(response.posts?.data ?? []);
      }
      emit(PostPaginationLoadedState());
    } catch (e) {
      print(e);

      // emit(PostPaginationLoadedState());
      emit(PostDataError('An error occurred $e'));
    }
  }

  _onGetDetailsPosts(DetailsPostEvent event, Emitter<HomeState> emit) async {
    emit(PostPaginationLoadingState());

    try {
      if (event.commentId != 0) {
        print(event.commentId);
        postData = await apiManager.getDetailsPosts(
          'Bearer ${AppData.userToken}',
          event.commentId.toString(),
        );
      } else {
        postData = await apiManager.getDetailsLikesPosts(
          'Bearer ${AppData.userToken}',
          event.postId.toString(),
        );
      }
      print('post $postData');
      emit(PostPaginationLoadedState());
    } catch (e) {
      print(e);

      // emit(PostPaginationLoadedState());
      emit(PostDataError('An error occurred $e'));
    }
  }

  _onGetSearchPosts(LoadSearchPageEvent event, Emitter<HomeState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PostPaginationLoadingState());
    }
    try {
      PostDataModel response = await apiManager.getSearchPostList(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
        event.search ?? '',
      );
      print(response.toJson());
      numberOfPage = response.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(response.posts?.data ?? []);
      }
      emit(PostPaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);
      // emit(PostPaginationLoadedState());

      emit(PostDataError('An error occurred $e'));
    }
  }

  _onPostLike(PostLikeEvent event, Emitter<HomeState> emit) async {
    // Find the post in the list
    int index = postList.indexWhere(
      (element) => element.id.toString() == event.postId.toString(),
    );

    if (index < 0) {
      print('⚠️ Post not found in list: ${event.postId}');
      return;
    }

    // Determine current like state
    bool wasLiked = postList[index].likes!
        .where(
          (element) =>
              element.userId.toString() == AppData.logInUserId.toString(),
        )
        .isNotEmpty;

    print(
      '👍 Optimistic like/unlike for post ${event.postId}, wasLiked: $wasLiked',
    );

    // OPTIMISTIC UPDATE: Update UI immediately
    if (wasLiked) {
      // Remove like optimistically
      postList[index].likes!.removeWhere(
        (element) =>
            element.userId.toString() == AppData.logInUserId.toString(),
      );
    } else {
      // Add like optimistically
      postList[index].likes!.add(
        Likes(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          userId: AppData.logInUserId,
          postId: event.postId.toString(),
        ),
      );
    }

    // Emit state immediately for instant UI feedback
    emit(PostPaginationLoadedState());

    // Now make the API call in the background
    try {
      var response = await apiManager.like(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
      );
      print('✅ Like API success: ${response.data}');

      // API succeeded - UI already reflects correct state
      // Optionally emit again to ensure consistency
      emit(PostPaginationLoadedState());
    } catch (e) {
      print('❌ Like API failed: $e');

      // ROLLBACK: Revert the optimistic update on failure
      int currentIndex = postList.indexWhere(
        (element) => element.id.toString() == event.postId.toString(),
      );

      if (currentIndex >= 0) {
        if (wasLiked) {
          // Restore the like
          postList[currentIndex].likes!.add(
            Likes(
              id: 1,
              userId: AppData.logInUserId,
              postId: event.postId.toString(),
            ),
          );
        } else {
          // Remove the optimistic like
          postList[currentIndex].likes!.removeWhere(
            (element) =>
                element.userId.toString() == AppData.logInUserId.toString(),
          );
        }

        // Emit state with rolled-back data
        emit(PostPaginationLoadedState());

        // Queue for retry if it's a network error
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('Network') ||
            e.toString().contains('Connection')) {
          print('📝 Queuing like request for retry when network returns');
          _queueFailedLikeRequest(event.postId.toString(), !wasLiked);
        }
      }
    }
  }

  // Queue for failed like requests (simple in-memory queue)
  final Map<String, bool> _pendingLikeRequests = {};

  void _queueFailedLikeRequest(String postId, bool shouldLike) {
    _pendingLikeRequests[postId] = shouldLike;
    print('📋 Pending like requests: ${_pendingLikeRequests.length}');
  }

  // Method to retry pending like requests (can be called when network returns)
  Future<void> retryPendingLikeRequests() async {
    if (_pendingLikeRequests.isEmpty) return;

    print('🔄 Retrying ${_pendingLikeRequests.length} pending like requests');
    final requestsCopy = Map<String, bool>.from(_pendingLikeRequests);

    for (var entry in requestsCopy.entries) {
      try {
        await apiManager.like('Bearer ${AppData.userToken}', entry.key);
        print('✅ Retry successful for post ${entry.key}');
        _pendingLikeRequests.remove(entry.key);
      } catch (e) {
        print('❌ Retry failed for post ${entry.key}: $e');
        // Keep in queue for next retry
      }
    }
  }

  _onDeletePost(DeletePostEvent event, Emitter<HomeState> emit) async {
    // try {
    var response = await apiManager.deletePost(
      'Bearer ${AppData.userToken}',
      event.postId.toString(),
    );
    postList.removeAt(
      postList.indexWhere((element) => element.id == event.postId),
    );
    // int index=postList.indexWhere((element) => element.id.toString()==event.postId.toString());
    // bool isLike=postList[index].likes!.where((element) => element.postId.toString()==event.postId.toString()).isEmpty;
    // if(isLike) {
    //   postList[index].likes!.add(Likes(
    //       id: 1,
    //       userId: AppData.logInUserId,
    //       postId: event.postId.toString()
    //   ));
    // }else{
    //
    //   postList[index].likes!.removeLast();
    // }
    // numberOfPage = response.posts?.lastPage ?? 0;
    // if (pageNumber < numberOfPage + 1) {
    //   pageNumber = pageNumber + 1;
    // }
    // numberOfPage = response.posts?.lastPage ?? 0;
    // if (pageNumber < numberOfPage + 1) {
    //   pageNumber = pageNumber + 1;
    //   postList.addAll(response.postComments ?? []);
    // }
    print(response.data);
    emit(PostPaginationLoadedState());

    // emit(DataLoaded(postList));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PostPaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }

  Future<void> _adsSettingApi(
    AdsSettingEvent event,
    Emitter<HomeState> emit,
  ) async {
    print('call ads api');
    try {
      AppData.adsSettingModel = await apiManager.advertisementSetting(
        'Bearer ${AppData.userToken}',
      );
      print("ads data  ${AppData.adsSettingModel.toJson()}");
      AppData.listAdsType = await apiManager.advertisementTypes(
        'Bearer ${AppData.userToken}',
      );

      // banner ads
      AppData.isShowGoogleBannerAds =
          (AppData.listAdsType
              .where(
                (element) =>
                    element.type == 'banner' && element.provider == 'Google',
              )
              .isNotEmpty) &&
          ((AppData.adsSettingModel.data
                  ?.where(
                    (element) =>
                        element.advertisementType == 'banner' &&
                        element.provider == 'Google' &&
                        element.isAdvertisementOn == 1,
                  )
                  .isNotEmpty ??
              false));
      AppData.androidBannerAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'banner' && element.provider == 'Google',
          )
          .firstOrNull
          ?.androidId;
      AppData.iosBannerAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'banner' && element.provider == 'Google',
          )
          .firstOrNull
          ?.iosId;
      // native ads
      AppData.isShowGoogleNativeAds =
          (AppData.listAdsType
              .where(
                (element) =>
                    element.type == 'native' && element.provider == 'Google',
              )
              .isNotEmpty) &&
          ((AppData.adsSettingModel.data
                  ?.where(
                    (element) =>
                        element.advertisementType == 'native' &&
                        element.provider == 'Google' &&
                        element.isAdvertisementOn == 1,
                  )
                  .isNotEmpty ??
              false));
      AppData.androidNativeAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'native' && element.provider == 'Google',
          )
          .firstOrNull
          ?.androidId;
      AppData.iosNativeAdsId = AppData.listAdsType
          .where(
            (element) =>
                element.type == 'native' && element.provider == 'Google',
          )
          .firstOrNull
          ?.iosId;
      print(
        AppData.listAdsType
            .where(
              (element) =>
                  element.type == 'native' && element.provider == 'Google',
            )
            .isNotEmpty,
      );
      print(
        AppData.adsSettingModel.data
            ?.where(
              (element) =>
                  element.advertisementType == 'native' &&
                  element.provider == 'Google' &&
                  element.isAdvertisementOn == '1',
            )
            .isNotEmpty,
      );
      print("dot1 ${AppData.isShowGoogleBannerAds}");
      print("dot ${AppData.isShowGoogleNativeAds}");
      print("dot ${AppData.androidBannerAdsId}");
      print("native Ads ${AppData.androidNativeAdsId}");
    } catch (e) {
      // emit(CountriesDataError('$e'));
    }
  }

  //  _onGetPosts1(GetPost event, Emitter<HomeState> emit) async {
  //   emit(DataInitial());
  //   // ProgressDialogUtils.showProgressDialog();
  //   try {
  //     final response = await postService.getPosts(
  //         'Bearer ${AppData.userToken}',
  //         '1');
  //     // if (response.==true) {
  //     //   ProgressDialogUtils.hideProgressDialog();
  //       emit(DataLoaded(response));
  //     // } else {
  //     //   ProgressDialogUtils.hideProgressDialog();
  //     //   emit(LoginFailure(error: 'Invalid credentials'));
  //     // }
  //   } catch (e) {
  //     print(e);
  //     emit(DataError('An error occurred'));
  //   }
  // }
}
