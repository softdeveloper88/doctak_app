import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_comment_model/reply_comment_model.dart';
import 'package:doctak_app/data/models/post_comment_model/reply_comment_response.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_content_type.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_mappers.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'comment_event.dart';

part 'comment_state.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  CommentBloc({
    CommentContentType contentType = CommentContentType.post,
    String contentId = '',
  })  : contentType = contentType,
        contentId = contentId,
        super(DataInitial()) {
    on<LoadPageEvent>(_onGetPosts);
    on<PostCommentEvent>(_onPostComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<FetchReplyComment>(_onGetReplyComment);
    on<LikeReplyComment>(_onCommentReplyLike);
    on<ReplyComment>(_onPostCommentReply);
    on<UpdateReplyCommentEvent>(_onUpdateReplyComment);
    on<UpdateMainCommentEvent>(_onUpdateMainComment);
    on<DeleteReplyCommentEvent>(_onDeleteReplyComment);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
  }

  final CommentContentType contentType;
  final String contentId;
  final ApiServiceManager apiManager = ApiServiceManager();
  final SharedApiService _sharedApi = SharedApiService();
  final CaseDiscussionRepository _caseRepo = CaseDiscussionRepository(
    baseUrl: AppData.base2,
    getAuthToken: () => AppData.userToken ?? '',
  );
  int pageNumber = 1;
  int numberOfPage = 1;
  List<PostComments> postList = [];
  List<CommentsModel> replyCommentList = [];
  final int nextPageTrigger = 1;
  String? _loadedRepliesCommentId;

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${AppData.userToken}',
      };

  /// Always load/post against the real post id — never feed cache or id `0`.
  String _resolvePostId({int? eventPostId}) {
    if (eventPostId != null && eventPostId > 0) {
      return eventPostId.toString();
    }
    return contentId;
  }

  Future<void> _onGetPosts(LoadPageEvent event, Emitter<CommentState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      switch (contentType) {
        case CommentContentType.post:
          await _loadPostComments(event, emit);
        case CommentContentType.blog:
          await _loadBlogComments(event, emit);
        case CommentContentType.caseDiscussion:
          await _loadCaseComments(event, emit);
      }
    } catch (e) {
      print(e);
      emit(PaginationLoadedState());
    }
  }

  Future<void> _loadPostComments(LoadPageEvent event, Emitter<CommentState> emit) async {
    try {
      final postId = _resolvePostId(eventPostId: event.postId);
      if (postId.isEmpty) {
        emit(DataError('No Data Found'));
        return;
      }
      final page = event.page ?? 1;
      final res = await _sharedApi.getPostComments(postId: postId, page: page);
      if (!res.success || res.data == null) {
        emit(DataError(res.message ?? 'No Data Found'));
        return;
      }
      final response = res.data!;
      numberOfPage = response.comments?.lastPage ?? 1;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
      }
      postList.addAll(response.comments?.data ?? []);
      emit(PaginationLoadedState());
    } catch (e) {
      print('load post comments error: $e');
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _loadBlogComments(LoadPageEvent event, Emitter<CommentState> emit) async {
    try {
      final res = await _sharedApi.getBlogComments(
        blogId: contentId,
        page: event.page ?? 1,
      );
      if (!res.success || res.data == null) {
        emit(DataError(res.message ?? 'No Data Found'));
        return;
      }
      final comments = res.data!['comments'];
      if (comments is Map) {
        numberOfPage = int.tryParse('${comments['last_page']}') ?? 1;
        if (pageNumber < numberOfPage + 1) {
          pageNumber = pageNumber + 1;
        }
        final data = comments['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              postList.add(postCommentFromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
      emit(PaginationLoadedState());
    } catch (e) {
      print('error: $e');
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _loadCaseComments(LoadPageEvent event, Emitter<CommentState> emit) async {
    try {
      final caseId = int.tryParse(contentId) ?? 0;
      final result = await _caseRepo.getCaseComments(
        caseId: caseId,
        page: event.page ?? 1,
      );
      numberOfPage = result.pagination.lastPage;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
      }
      postList.addAll(result.items.map(caseCommentToPostComments));
      emit(PaginationLoadedState());
    } catch (e) {
      print('error: $e');
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _onGetReplyComment(FetchReplyComment event, Emitter<CommentState> emit) async {
    final commentId = event.commentId ?? '';
    if (commentId.isEmpty) return;

    // Avoid refetch loop when the reply panel re-mounts for the same comment.
    if (!event.forceRefresh &&
        _loadedRepliesCommentId == commentId &&
        replyCommentList.isNotEmpty) {
      emit(ReplyLoadedState());
      return;
    }

    emit(ReplyLoadingState());
    _loadedRepliesCommentId = commentId;
    replyCommentList.clear();
    try {
      switch (contentType) {
        case CommentContentType.post:
          await _fetchPostReplies(event, emit);
        case CommentContentType.blog:
          await _fetchBlogReplies(event, emit);
        case CommentContentType.caseDiscussion:
          await _fetchCaseReplies(event, emit);
      }
    } catch (e) {
      print(e);
      emit(ReplyErrorState('No Data Found'));
    }
  }

  Future<void> _fetchPostReplies(FetchReplyComment event, Emitter<CommentState> emit) async {
    try {
      final dio = Dio();
      final response1 = await dio.post(
        '${AppData.remoteUrl2}/fetch-comment-replies',
        options: Options(headers: _authHeaders),
        data: FormData.fromMap({
          'post_id': event.postId ?? contentId,
          'comment_id': event.commentId,
        }),
      );
      final response = ReplyCommentModel.fromJson(response1.data);
      replyCommentList.clear();
      replyCommentList.addAll(response.comments ?? []);
      emit(ReplyLoadedState());
    } catch (e) {
      if (e is DioException) {
        print('fetch-comment-replies error status: ${e.response?.statusCode}');
        print('fetch-comment-replies error body: ${e.response?.data}');
      }
      print('error: $e');
      emit(ReplyErrorState('No Data Found'));
    }
  }

  Future<void> _fetchBlogReplies(FetchReplyComment event, Emitter<CommentState> emit) async {
    try {
      final res = await _sharedApi.getBlogCommentReplies(
        blogId: contentId,
        commentId: event.commentId ?? '',
      );
      if (!res.success || res.data == null) {
        emit(ReplyErrorState(res.message ?? 'No Data Found'));
        return;
      }
      replyCommentList.clear();
      final comments = res.data!['comments'];
      if (comments is List) {
        for (final item in comments) {
          if (item is Map) {
            replyCommentList.add(blogReplyToCommentsModel(Map<String, dynamic>.from(item)));
          }
        }
      }
      emit(ReplyLoadedState());
    } catch (e) {
      print('error: $e');
      emit(ReplyErrorState('No Data Found'));
    }
  }

  Future<void> _fetchCaseReplies(FetchReplyComment event, Emitter<CommentState> emit) async {
    try {
      final commentId = int.tryParse(event.commentId ?? '') ?? 0;
      final replies = await _caseRepo.getReplies(commentId);
      replyCommentList.clear();
      replyCommentList.addAll(replies.map(caseReplyToCommentsModel));
      emit(ReplyLoadedState());
    } catch (e) {
      print('error: $e');
      emit(ReplyErrorState('No Data Found'));
    }
  }

  Future<void> _onPostComment(PostCommentEvent event, Emitter<CommentState> emit) async {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final optimistic = PostComments(
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
        profilePic: AppData.profile_pic.isNotEmpty ? AppData.profilePicUrl : null,
      ),
    );
    postList.add(optimistic);
    emit(PaginationLoadedState());

    try {
      switch (contentType) {
        case CommentContentType.post:
          await _postPostComment(event, optimistic, emit);
        case CommentContentType.blog:
          await _postBlogComment(event, optimistic, emit);
        case CommentContentType.caseDiscussion:
          await _postCaseComment(event, optimistic, emit);
      }
    } catch (e) {
      print('post comment error: $e');
      postList.remove(optimistic);
      emit(PaginationLoadedState());
      showToast('Failed to post comment. Please try again.');
    }
  }

  Future<void> _postPostComment(
    PostCommentEvent event,
    PostComments optimistic,
    Emitter<CommentState> emit,
  ) async {
    final postId = _resolvePostId(eventPostId: event.postId);
    if (postId.isEmpty) {
      postList.remove(optimistic);
      emit(PaginationLoadedState());
      showToast('Could not post comment: invalid post');
      return;
    }
    final response = await apiManager.makeComment(
      'Bearer ${AppData.userToken}',
      postId,
      event.comment ?? '',
    );
    if (!_applyNewCommentId(response.data, optimistic, emit)) {
      // Keep the optimistic row; do not reload from server here — an immediate
      // GET can return stale data and wipe the comment the user just posted.
      emit(PaginationLoadedState());
    }
    showToast('Comment post successfully');
  }

  Future<void> _postBlogComment(
    PostCommentEvent event,
    PostComments optimistic,
    Emitter<CommentState> emit,
  ) async {
    final res = await _sharedApi.addBlogComment(
      blogId: contentId,
      body: event.comment ?? '',
    );
    if (res.success && res.data != null) {
      final newComment = res.data!['new_comment'];
      if (newComment is Map && newComment['id'] != null) {
        optimistic.id = int.tryParse('${newComment['id']}');
        emit(PaginationLoadedState());
      }
    }
    showToast('Comment post successfully');
  }

  Future<void> _postCaseComment(
    PostCommentEvent event,
    PostComments optimistic,
    Emitter<CommentState> emit,
  ) async {
    final caseId = int.tryParse(contentId) ?? 0;
    final created = await _caseRepo.addComment(
      caseId: caseId,
      comment: event.comment ?? '',
    );
    optimistic.id = created.id;
    emit(PaginationLoadedState());
    showToast('Comment post successfully');
  }

  bool _applyNewCommentId(
    dynamic rawData,
    PostComments optimistic,
    Emitter<CommentState> emit,
  ) {
    if (rawData == null) return false;
    Map<String, dynamic>? parsed;
    if (rawData is Map) {
      parsed = Map<String, dynamic>.from(rawData);
    }
    if (parsed == null) return false;
    if (parsed['success'] == false) return false;

    final dynamic newComment = parsed['new_comment'];
    final dynamic serverId = newComment is Map ? newComment['id'] : null;
    if (serverId != null) {
      final int? realId = int.tryParse(serverId.toString());
      if (realId != null && realId > 0) {
        optimistic.id = realId;
        emit(PaginationLoadedState());
        return true;
      }
    }
    return false;
  }

  Future<void> _onCommentReplyLike(LikeReplyComment event, Emitter<CommentState> emit) async {
    final commentId = event.commentId?.trim();
    if (commentId == null || commentId.isEmpty) return;

    final replyIdx =
        replyCommentList.indexWhere((r) => r.id.toString() == commentId);
    final mainIdx = postList.indexWhere((c) => c.id.toString() == commentId);
    if (replyIdx < 0 && mainIdx < 0) return;

    final wasLiked = replyIdx >= 0
        ? (replyCommentList[replyIdx].userHasLiked ?? false)
        : (postList[mainIdx].userHasLiked ?? false);

    void applyLocal({required bool liked, int? likeCount}) {
      if (replyIdx >= 0) {
        final reply = replyCommentList[replyIdx];
        reply.userHasLiked = liked;
        if (likeCount != null) {
          reply.likeCount = likeCount;
        } else {
          final current = reply.likeCount ?? 0;
          reply.likeCount = liked ? current + 1 : (current > 0 ? current - 1 : 0);
        }
      } else {
        final comment = postList[mainIdx];
        comment.userHasLiked = liked;
        if (likeCount != null) {
          comment.reactionCount = likeCount;
        } else {
          final current = comment.reactionCount ?? 0;
          comment.reactionCount =
              liked ? current + 1 : (current > 0 ? current - 1 : 0);
        }
      }
    }

    applyLocal(liked: !wasLiked);
    emit(replyIdx >= 0 ? ReplyLoadedState() : PaginationLoadedState());

    try {
      Map<String, dynamic>? payload;
      final isReplyTarget = replyIdx >= 0;

      if (contentType == CommentContentType.caseDiscussion) {
        final caseRes = await _caseRepo.performCommentAction(
          commentId: int.tryParse(commentId) ?? 0,
          action: wasLiked ? 'unlike' : 'like',
          targetType: isReplyTarget ? 'reply' : 'comment',
        );
        final data = caseRes['data'];
        if (data is Map) {
          payload = Map<String, dynamic>.from(data);
          payload['liked'] = caseRes['liked'] == true ? true : !(wasLiked);
          if (!payload.containsKey('like_count')) {
            payload['like_count'] = payload['likes'];
          }
        } else if (caseRes['liked'] != null || caseRes['like_count'] != null) {
          payload = {
            'liked': caseRes['liked'] == true,
            'like_count': caseRes['like_count'],
          };
        }
      } else {
        // Feed replies use the same `comments` + `comment_reactions` tables —
        // do not send target_type=reply (that path is for case discussion only).
        var res = await _sharedApi.toggleCommentLike(commentId: commentId);
        if (!res.success) {
          res = await _sharedApi.likeCommentLegacy(commentId: commentId);
        }
        if (!res.success || res.data == null) {
          throw Exception(res.message ?? 'Failed to update like');
        }
        payload = res.data;
      }

      if (payload != null) {
        final liked = payload['liked'] == true;
        final count = int.tryParse(
              '${payload['like_count'] ?? payload['reaction_count'] ?? ''}',
            ) ??
            (replyIdx >= 0
                ? replyCommentList[replyIdx].likeCount
                : postList[mainIdx].reactionCount) ??
            0;
        applyLocal(liked: liked, likeCount: count);
      }

      emit(replyIdx >= 0 ? ReplyLoadedState() : PaginationLoadedState());
    } catch (e) {
      applyLocal(liked: wasLiked);
      emit(replyIdx >= 0 ? ReplyLoadedState() : PaginationLoadedState());
      if (e is DioException) {
        final errData = e.response?.data;
        final msg = (errData is Map)
            ? (errData['message'] ?? 'Could not update like')
            : 'Could not update like';
        showToast('$msg');
      } else {
        showToast('Could not update like');
      }
    }
  }

  Future<void> _onPostCommentReply(ReplyComment event, Emitter<CommentState> emit) async {
    final commentIdNum = int.tryParse(event.commentId ?? '') ?? 0;
    if (commentIdNum <= 0 || (event.commentText?.trim() ?? '').isEmpty) {
      showToast('Cannot post reply: invalid comment or empty text');
      return;
    }

    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final optimistic = CommentsModel(
      id: -1,
      commenterId: AppData.logInUserId,
      commentableId: event.postId ?? contentId,
      comment: event.commentText,
      createdAt: formattedDateTime,
      commenter: ReplyCommenter(
        name: AppData.name,
        profilePic: AppData.profile_pic.isNotEmpty ? AppData.profilePicUrl : null,
      ),
    );
    replyCommentList.add(optimistic);
    emit(PaginationLoadedState());

    try {
      switch (contentType) {
        case CommentContentType.post:
          await _postPostReply(event, optimistic, emit);
        case CommentContentType.blog:
          await _postBlogReply(event, optimistic, emit);
        case CommentContentType.caseDiscussion:
          await _postCaseReply(event, optimistic, emit);
      }
    } catch (e) {
      if (e is DioException) {
        final errData = e.response?.data;
        final msg = (errData is Map) ? (errData['message'] ?? 'Could not post reply') : 'Could not post reply';
        showToast('Reply failed: $msg');
      } else {
        print('error: $e');
        showToast('Failed to post reply');
      }
      emit(PaginationLoadedState());
    }
  }

  Future<void> _postPostReply(
    ReplyComment event,
    CommentsModel optimistic,
    Emitter<CommentState> emit,
  ) async {
    final dio = Dio();
    final response1 = await dio.post(
      '${AppData.remoteUrl2}/reply-comment',
      options: Options(headers: _authHeaders),
      data: FormData.fromMap({
        'post_id': event.postId ?? contentId,
        'comment_id': event.commentId,
        'comment_text': event.commentText,
      }),
    );
    final response = ReplyCommentResponse.fromJson(response1.data);
    if (response.comment?.id != null && (response.comment!.id ?? 0) > 0) {
      optimistic.id = response.comment!.id;
      emit(PaginationLoadedState());
    }
    showToast('Comment post successfully');
  }

  Future<void> _postBlogReply(
    ReplyComment event,
    CommentsModel optimistic,
    Emitter<CommentState> emit,
  ) async {
    final res = await _sharedApi.addBlogCommentReply(
      blogId: contentId,
      commentId: event.commentId ?? '',
      body: event.commentText ?? '',
    );
    if (res.success && res.data != null) {
      final reply = res.data!['reply'];
      if (reply is Map && reply['id'] != null) {
        optimistic.id = int.tryParse('${reply['id']}');
        emit(PaginationLoadedState());
      }
    }
    showToast('Comment post successfully');
  }

  Future<void> _postCaseReply(
    ReplyComment event,
    CommentsModel optimistic,
    Emitter<CommentState> emit,
  ) async {
    final created = await _caseRepo.addReply(
      commentId: int.tryParse(event.commentId ?? '') ?? 0,
      reply: event.commentText ?? '',
    );
    optimistic.id = created.id;
    emit(PaginationLoadedState());
    showToast('Comment post successfully');
  }

  Future<void> _onDeleteComment(DeleteCommentEvent event, Emitter<CommentState> emit) async {
    try {
      if (contentType == CommentContentType.caseDiscussion) {
        await _caseRepo.deleteComment(int.tryParse(event.commentId ?? '') ?? 0);
      } else {
        await apiManager.deleteComments('Bearer ${AppData.userToken}', event.commentId.toString());
      }
      postList.removeWhere((element) => element.id.toString() == event.commentId);
      showToast('Delete comment successfully');
      emit(PaginationLoadedState());
    } catch (e) {
      print(e);
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onDeleteReplyComment(DeleteReplyCommentEvent event, Emitter<CommentState> emit) async {
    try {
      if (contentType == CommentContentType.caseDiscussion) {
        await _caseRepo.deleteReply(int.tryParse(event.commentId ?? '') ?? 0);
      } else {
        final dio = Dio();
        await dio.post(
          '${AppData.remoteUrl2}/comments-delete?comment_id=${event.commentId}',
          options: Options(headers: _authHeaders),
        );
      }
      replyCommentList.removeWhere((element) => element.id.toString() == event.commentId);
      showToast('Delete comment successfully');
      emit(PaginationLoadedState());
    } catch (e) {
      print(e);
      emit(DataError('An error occurred $e'));
    }
  }

  Future<void> _onUpdateMainComment(UpdateMainCommentEvent event, Emitter<CommentState> emit) async {
    try {
      if (contentType == CommentContentType.caseDiscussion) {
        await _caseRepo.updateComment(
          int.tryParse(event.commentId ?? '') ?? 0,
          event.content ?? '',
        );
      } else {
        final dio = Dio();
        await dio.get(
          '${AppData.remoteUrl2}/comments-update?comment_id=${event.commentId}&content=${Uri.encodeComponent(event.content ?? '')}',
          options: Options(headers: _authHeaders),
        );
      }
      final index = postList.indexWhere((element) => element.id.toString() == event.commentId);
      if (index >= 0) {
        postList[index].comment = event.content;
      }
      emit(PaginationLoadedState());
      showToast('Comment updated successfully');
    } catch (e) {
      print(e);
      emit(DataError('An error occurred $e'));
    }
  }

  Future<void> _onUpdateReplyComment(UpdateReplyCommentEvent event, Emitter<CommentState> emit) async {
    if (contentType == CommentContentType.caseDiscussion) {
      showToast('Editing replies is not supported for case comments yet.');
      return;
    }
    try {
      final dio = Dio();
      await dio.get(
        '${AppData.remoteUrl2}/comments-update?comment_id=${event.commentId}&content=${Uri.encodeComponent(event.content ?? '')}',
        options: Options(headers: _authHeaders),
      );
      final index = replyCommentList.indexWhere((element) => element.id.toString() == event.commentId);
      if (index >= 0) {
        replyCommentList[index].comment = event.content;
      }
      emit(PaginationLoadedState());
    } catch (e) {
      print(e);
      emit(DataError('An error occurred $e'));
    }
  }
}
