import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_comment_model/reply_comment_model.dart';
import 'package:doctak_app/data/models/post_comment_model/reply_comment_response.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'comment_event.dart';

part 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  List<PostComments> postList = [];
  List<CommentsModel> replyCommentList = [];
  final int nextPageTrigger = 1;

  CommentBloc() : super(DataInitial()) {
    on<LoadPageEvent>(_onGetPosts);
    on<PostCommentEvent>(_onPostComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<FetchReplyComment>(_onGetReplyComment);
    on<LikeReplyComment>(_onCommentReplyLike);
    on<ReplyComment>(_onPostCommentReply);
    on<UpdateReplyCommentEvent>(_onUpdateReplyComment);
    on<DeleteReplyCommentEvent>(_onDeleteReplyComment);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(LoadPageEvent(postId: event.postId, page: pageNumber));
      }
    });
  }

  _onGetPosts(LoadPageEvent event, Emitter<CommentState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      try {
        Dio dio = Dio();
        Response response1 = await dio.get(
          '${AppData.remoteUrl2}/posts/${event.postId}/comments?page=${event.page}', // Add query parameters
          options: Options(
            headers: {
              'Authorization': 'Bearer ${AppData.userToken}', // Set headers
            },
          ),
        );
        print("response ${response1.data}");
        PostCommentModel response = PostCommentModel.fromJson(response1.data);
        numberOfPage = response.comments?.lastPage ?? 0;
        if (pageNumber < numberOfPage + 1) {
          pageNumber = pageNumber + 1;
        }
        postList.addAll(response.comments?.data ?? []);
        emit(PaginationLoadedState());
      } catch (e) {
        print("error: $e");
        emit(DataError('No Data Found'));
      }
      // postList.addAll(response.comments?.data ?? []);

      // emit(DataLoaded(drugsData));
      // } catch (e) {
      //   // ProgressDialogUtils.hideProgressDialog();
      //   print(e);
      //
      //   emit(DataError('No Data Found'));
      // }
      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
      // }
      // emit(PaginationLoadedState());

      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);
      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  _onGetReplyComment(
    FetchReplyComment event,
    Emitter<CommentState> emit,
  ) async {
    // if (event.page == 1) {
    //   postList.clear();
    //   pageNumber = 1;
    emit(PaginationLoadingState());
    // }
    try {
      try {
        Dio dio = Dio();

        Response response1 = await dio.post(
          '${AppData.remoteUrl2}/fetch-comment-replies', // Add query parameters
          options: Options(
            headers: {
              'Authorization': 'Bearer ${AppData.userToken}', // Set headers
            },
          ),
          data: FormData.fromMap({
            'post_id': event.postId,
            'comment_id': event.commentId,
          }),
        );
        print("response ${response1.data}");
        ReplyCommentModel response = ReplyCommentModel.fromJson(response1.data);
        // numberOfPage = response.pagination?.total ?? 0;
        // if (pageNumber < numberOfPage + 1) {
        //   pageNumber = pageNumber + 1;
        // }
        // postList.addAll(response.comments?.data ?? []);
        print(response);
        replyCommentList.addAll(response.comments ?? []);
        emit(PaginationLoadedState());
      } catch (e) {
        print("error: $e");
        emit(DataError('No Data Found'));
      }
      // postList.addAll(response.comments?.data ?? []);

      // emit(DataLoaded(drugsData));
      // } catch (e) {
      //   // ProgressDialogUtils.hideProgressDialog();
      //   print(e);
      //
      //   emit(DataError('No Data Found'));
      // }
      // numberOfPage = response.posts?.lastPage ?? 0;
      // if (pageNumber < numberOfPage + 1) {
      //   pageNumber = pageNumber + 1;
      // }
      // emit(PaginationLoadedState());

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
    // try {
    final now = DateTime.now();
    final formattedDateTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(now); // Custom format
    postList.add(
      PostComments(
        id: -1,
        comment: event.comment,
        createdAt: formattedDateTime,
        userHasLiked: false,
        reactionCount: 0,
        replyCount: 0,
        commenter: Commenter(
          id: AppData.logInUserId,
          firstName: AppData.name,
          lastName: '',
        ),
      ),
    );
    var response = await apiManager.makeComment(
      'Bearer ${AppData.userToken}',
      event.postId.toString(),
      event.comment ?? "",
    );

    print(response.data);
    showToast('Comment post successfully');
    // add(LoadPageEvent(postId:event.postId,page: pageNumber));
    // PostCommentModel response1 = await postService.getPostComments(
    //   'Bearer ${AppData.userToken}',
    //   event.postId.toString(),
    // );
    // // numberOfPage = response.posts?.lastPage ?? 0;
    // // if (pageNumber < numberOfPage + 1) {
    // //   pageNumber = pageNumber + 1;
    // postList.clear();
    // postList.addAll(response1.comments?.data ?? []);
    // }
    // numberOfPage = response.posts?.lastPage ?? 0;
    // if (pageNumber < numberOfPage + 1) {
    //   pageNumber = pageNumber + 1;

    // postList.addAll(response.data.postComments ?? []);
    // }
    emit(PaginationLoadedState());

    // emit(DataLoaded(postList));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }

  _onCommentReplyLike(
    LikeReplyComment event,
    Emitter<CommentState> emit,
  ) async {
    try {
      Dio dio = Dio();
      Response response1 = await dio.post(
        '${AppData.remoteUrl2}/comments/${event.commentId}/like', // Add query parameters
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ),
      );
      showToast('Comment Like successfully');
      emit(PaginationLoadedState());
    } catch (e) {
      print(e);

      emit(DataError('An error occurred $e'));
    }
  }

  _onPostCommentReply(ReplyComment event, Emitter<CommentState> emit) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    try {
      Dio dio = Dio();

      Response response1 = await dio.post(
        '${AppData.remoteUrl2}/reply-comment', // Add query parameters
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ),
        data: FormData.fromMap({
          'post_id': event.postId,
          'comment_id': event.commentId,
          'comment_text': event.commentText,
        }),
      );

      ReplyCommentResponse response = ReplyCommentResponse.fromJson(
        response1.data,
      );
      showToast('Comment post successfully');
      final now = DateTime.now();
      final formattedDateTime = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(now); // Custom format
      replyCommentList.add(
        CommentsModel(
          id: response.comment?.id,
          commenterId: AppData.logInUserId,
          commentableId: event.postId,
          comment: event.commentText,
          createdAt: formattedDateTime,
          commenter: ReplyCommenter(
            name: AppData.name,
            profilePic: AppData.imageUrl,
          ),
        ),
      );
      emit(PaginationLoadedState());
    } catch (e) {
      print("error: $e");
      emit(DataError('No Data Found'));
    }
    // try {
    // final now = DateTime.now();
    // final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now); // Custom format
    // postList.add(PostComments(
    //   id: -1,
    //   comment:event.comment,
    //   createdAt: formattedDateTime,
    //   userHasLiked: false,
    //   reactionCount:0,
    //   replyCount:0,
    //   commenter: Commenter(
    //     id: AppData.logInUserId,
    //     firstName: AppData.name,
    //     lastName: '',
    //   ),
    // ));
    // var response = await postService.makeComment(
    //   'Bearer ${AppData.userToken}',
    //   event.postId.toString(),
    //   event.comment ?? "",
    // );

    // print(response.data);
    // showToast('Comment post successfully');
    // // add(LoadPageEvent(postId:event.postId,page: pageNumber));
    // // PostCommentModel response1 = await postService.getPostComments(
    // //   'Bearer ${AppData.userToken}',
    // //   event.postId.toString(),
    // // );
    // // // numberOfPage = response.posts?.lastPage ?? 0;
    // // // if (pageNumber < numberOfPage + 1) {
    // // //   pageNumber = pageNumber + 1;
    // // postList.clear();
    // // postList.addAll(response1.comments?.data ?? []);
    // // }
    // // numberOfPage = response.posts?.lastPage ?? 0;
    // // if (pageNumber < numberOfPage + 1) {
    // //   pageNumber = pageNumber + 1;
    //
    //   // postList.addAll(response.data.postComments ?? []);
    // // }
    // emit(PaginationLoadedState());

    // emit(DataLoaded(postList));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }
  // _onReplyComment(ReplyComment event, Emitter<CommentState> emit) async {
  //   // if (event.pos == 1) {
  //   //   postList.clear();
  //   //   pageNumber = 1;
  //
  //   // }
  //   // try {
  //   final now = DateTime.now();
  //   final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now); // Custom format
  //   // postList.add(PostComments(
  //   //   id: -1,
  //   //   comment:event.comment,
  //   //   createdAt: formattedDateTime,
  //   //   userHasLiked: false,
  //   //   reactionCount:0,
  //   //   replyCount:0,
  //   //   commenter: Commenter(
  //   //     id: AppData.logInUserId,
  //   //     firstName: AppData.name,
  //   //     lastName: '',
  //   //   ),
  //   // ));
  //   var response = await postService.makeComment(
  //     'Bearer ${AppData.userToken}',
  //     event.postId.toString(),
  //     event.comment ?? "",
  //   );
  //
  //   print(response.data);
  //   showToast('Comment post successfully');
  //   // add(LoadPageEvent(postId:event.postId,page: pageNumber));
  //   // PostCommentModel response1 = await postService.getPostComments(
  //   //   'Bearer ${AppData.userToken}',
  //   //   event.postId.toString(),
  //   // );
  //   // // numberOfPage = response.posts?.lastPage ?? 0;
  //   // // if (pageNumber < numberOfPage + 1) {
  //   // //   pageNumber = pageNumber + 1;
  //   // postList.clear();
  //   // postList.addAll(response1.comments?.data ?? []);
  //   // }
  //   // numberOfPage = response.posts?.lastPage ?? 0;
  //   // if (pageNumber < numberOfPage + 1) {
  //   //   pageNumber = pageNumber + 1;
  //
  //     // postList.addAll(response.data.postComments ?? []);
  //   // }
  //   emit(PaginationLoadedState());
  //
  //   // emit(DataLoaded(postList));
  //   // } catch (e) {
  //   //   print(e);
  //   //
  //   //   emit(PaginationLoadedState());
  //   //
  //   //   // emit(DataError('An error occurred $e'));
  //   // }
  // }

  _onDeleteComment(DeleteCommentEvent event, Emitter<CommentState> emit) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    print(event.commentId);
    try {
      var response = await apiManager.deleteComments(
        'Bearer ${AppData.userToken}',
        event.commentId.toString(),
      );

      postList.removeWhere(
        (element) => element.id.toString() == event.commentId,
      );
      showToast('Delete comment successfully');
      emit(PaginationLoadedState());
      // emit(DataLoaded(postList));
    } catch (e) {
      print(e);

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  _onDeleteReplyComment(
    DeleteReplyCommentEvent event,
    Emitter<CommentState> emit,
  ) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    try {
      Dio dio = Dio();
      Response response1 = await dio.post(
        '${AppData.remoteUrl2}/comments-delete?comment_id=${event.commentId}', // Add query parameters
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ),
      );
      int index = replyCommentList.indexWhere(
        (CommentsModel element) => element.id.toString() == event.commentId,
      );
      replyCommentList.removeAt(index);
      showToast('Delete comment successfully');
      emit(PaginationLoadedState());
    } catch (e) {
      print(e);

      emit(DataError('An error occurred $e'));
    }
  }

  _onUpdateReplyComment(
    UpdateReplyCommentEvent event,
    Emitter<CommentState> emit,
  ) async {
    // if (event.pos == 1) {
    //   postList.clear();
    //   pageNumber = 1;

    // }
    try {
      Dio dio = Dio();

      Response response1 = await dio.get(
        '${AppData.remoteUrl2}/comments-update?comment_id=${event.commentId}&content=${event.content}', // Add query parameters
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppData.userToken}', // Set headers
          },
        ),
      );
      int index = replyCommentList.indexWhere(
        (CommentsModel element) => element.id.toString() == event.commentId,
      );
      replyCommentList[index].comment = event.content;

      emit(PaginationLoadedState());
    } catch (e) {
      print(e);

      emit(DataError('An error occurred $e'));
    }
  }
}
