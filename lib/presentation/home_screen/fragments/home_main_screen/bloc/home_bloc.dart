import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Post> postList = [];
  final int nextPageTrigger = 1;

  HomeBloc() : super(DataInitial()) {
    on<PostLoadPageEvent>(_onGetPosts);
    on<LoadSearchPageEvent>(_onGetSearchPosts);
    on<PostLikeEvent>(_onPostLike);
    on<PostCheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(PostLoadPageEvent(page: pageNumber));
      }
    });
  }

  _onGetPosts(PostLoadPageEvent event, Emitter<HomeState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PostPaginationLoadingState());
    }
    try {
      PostDataModel response = await postService.getPosts(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
      );
      numberOfPage = response.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(response.posts?.data ?? []);
      }
      emit(PostPaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);

      emit(PostPaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }
  _onGetSearchPosts(LoadSearchPageEvent event, Emitter<HomeState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PostPaginationLoadingState());
    }
    try {
      PostDataModel response = await postService.getSearchPostList(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
        event.search??'',
      );
      numberOfPage = response.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(response.posts?.data ?? []);
      }
      emit(PostPaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);

      emit(PostPaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }
  _onPostLike(PostLikeEvent event, Emitter<HomeState> emit) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    try {
      var response = await postService.like(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
      );

      int index=postList.indexWhere((element) => element.id.toString()==event.postId.toString());
      bool isLike=postList[index].likes!.where((element) => element.postId.toString()==event.postId.toString()).isEmpty;
      if(isLike) {
        postList[index].likes!.add(Likes(
            id: 1,
            userId: AppData.logInUserId,
            postId: event.postId.toString()
        ));
      }else{

        postList[index].likes!.removeLast();
      }
      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
      // }
      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
      //   postList.addAll(response.postComments ?? []);
      // }
      emit(PostPaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);

      emit(PostPaginationLoadedState());

      // emit(DataError('An error occurred $e'));
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
