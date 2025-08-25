import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_model/post_likes_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
part 'likes_event.dart';
part 'likes_state.dart';

class LikesBloc extends Bloc<LikesEvent, LikesState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<PostComments> postList = [];
  final int nextPageTrigger = 1;
  List<PostLikesModel> postLikesList = [];

  LikesBloc() : super(DataInitial()) {
    on<LoadPageEvent>(_onPostUserLikes);
  }

  _onPostUserLikes(LoadPageEvent event, Emitter<LikesState> emit) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    try {
      postLikesList = await apiManager.getPostUserLikes(
        'Bearer ${AppData.userToken}',
        event.postId.toString(),
      );

      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
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
