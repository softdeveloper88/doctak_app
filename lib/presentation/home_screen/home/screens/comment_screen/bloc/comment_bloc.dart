import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'comment_event.dart';

part 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<PostComments> postList = [];
  final int nextPageTrigger = 1;

  CommentBloc() : super(DataInitial()) {
    on<LoadPageEvent>(_onGetPosts);
    on<PostCommentEvent>(_onPostComment);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(LoadPageEvent(postId: pageNumber));
      }
    });
  }

  _onGetPosts(LoadPageEvent event, Emitter<CommentState> emit) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;
    emit(PaginationLoadingState());
    // }
    try {
      PostCommentModel response = await postService.getPostComments(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
      );
      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
      postList.addAll(response.postComments ?? []);
      // }
      emit(PaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);
      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  _onPostComment(PostCommentEvent event, Emitter<CommentState> emit) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    try {
      var response = await postService.makeComment(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
        event.comment ?? "",
      );
      postList.insert(
          0,
          PostComments(
              id: 0,
              userId: AppData.logInUserId,
              postId: event.postId.toString(),
              comment: event.comment ?? "",
              createdAt: DateTime.now().toString(),
              updatedAt: DateTime.now().toString(),
              profilePic: AppData.profile_pic,
              name: AppData.name));
      // }
      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
      //   postList.addAll(response.postComments ?? []);
      // }
      emit(PaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }
}
