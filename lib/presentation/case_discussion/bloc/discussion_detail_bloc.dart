// ============================================================================
// Discussion Detail BLoC - v6 API
// Handles case detail, comments (paginated), replies, like/bookmark/follow
// actions, and AI summary generation.
// ============================================================================

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import '../repository/case_discussion_repository.dart';
import '../models/case_discussion_models.dart';
import '../models/case_vote_snapshot.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class DiscussionDetailEvent extends Equatable {
  const DiscussionDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadDiscussionDetail extends DiscussionDetailEvent {
  final int caseId;
  const LoadDiscussionDetail(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class LoadComments extends DiscussionDetailEvent {
  final int caseId;
  final bool refresh;
  const LoadComments(this.caseId, {this.refresh = false});
  @override
  List<Object> get props => [caseId, refresh];
}

class LoadMoreComments extends DiscussionDetailEvent {}

class AddComment extends DiscussionDetailEvent {
  final int caseId;
  final String comment;
  final String? clinicalTags;
  const AddComment({
    required this.caseId,
    required this.comment,
    this.clinicalTags,
  });
  @override
  List<Object?> get props => [caseId, comment, clinicalTags];
}

class DeleteComment extends DiscussionDetailEvent {
  final int commentId;
  const DeleteComment(this.commentId);
  @override
  List<Object> get props => [commentId];
}

class UpdateComment extends DiscussionDetailEvent {
  final int commentId;
  final String comment;
  const UpdateComment({required this.commentId, required this.comment});
  @override
  List<Object> get props => [commentId, comment];
}

class UpdateReply extends DiscussionDetailEvent {
  final int commentId;
  final int replyId;
  final String reply;
  const UpdateReply({
    required this.commentId,
    required this.replyId,
    required this.reply,
  });
  @override
  List<Object> get props => [commentId, replyId, reply];
}

class DeleteReply extends DiscussionDetailEvent {
  final int commentId;
  final int replyId;
  const DeleteReply(this.commentId, this.replyId);
  @override
  List<Object> get props => [commentId, replyId];
}

class ToggleLikeComment extends DiscussionDetailEvent {
  final int commentId;
  const ToggleLikeComment(this.commentId);
  @override
  List<Object> get props => [commentId];
}

class VoteComment extends DiscussionDetailEvent {
  final int commentId;
  final String direction;
  const VoteComment(this.commentId, this.direction);
  @override
  List<Object> get props => [commentId, direction];
}

class VoteReply extends DiscussionDetailEvent {
  final int commentId;
  final int replyId;
  final String direction;
  const VoteReply(this.commentId, this.replyId, this.direction);
  @override
  List<Object> get props => [commentId, replyId, direction];
}

class ToggleLikeCase extends DiscussionDetailEvent {
  final int caseId;
  const ToggleLikeCase(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class VoteCase extends DiscussionDetailEvent {
  final int caseId;
  final String direction;
  const VoteCase(this.caseId, this.direction);
  @override
  List<Object> get props => [caseId, direction];
}

class ToggleBookmarkCase extends DiscussionDetailEvent {
  final int caseId;
  const ToggleBookmarkCase(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class ToggleFollowCase extends DiscussionDetailEvent {
  final int caseId;
  const ToggleFollowCase(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class GenerateAISummary extends DiscussionDetailEvent {
  final int caseId;
  const GenerateAISummary(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class AddReply extends DiscussionDetailEvent {
  final int commentId;
  final String reply;
  const AddReply({required this.commentId, required this.reply});
  @override
  List<Object> get props => [commentId, reply];
}

class DeleteCase extends DiscussionDetailEvent {
  final int caseId;
  const DeleteCase(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class LoadReplies extends DiscussionDetailEvent {
  final int commentId;
  const LoadReplies(this.commentId);
  @override
  List<Object> get props => [commentId];
}

class LoadCaseUpdates extends DiscussionDetailEvent {
  final int caseId;
  const LoadCaseUpdates(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class AddCaseUpdate extends DiscussionDetailEvent {
  final int caseId;
  final String updateTitle;
  final String updateContent;
  final List<String> imagePaths;
  const AddCaseUpdate({
    required this.caseId,
    required this.updateTitle,
    required this.updateContent,
    this.imagePaths = const [],
  });
  @override
  List<Object> get props => [caseId, updateTitle, updateContent, imagePaths];
}

class EditCaseUpdate extends DiscussionDetailEvent {
  final int updateId;
  final String? updateTitle;
  final String? updateContent;
  final List<String> newImagePaths;
  final List<String> removedImagePaths;
  const EditCaseUpdate({
    required this.updateId,
    this.updateTitle,
    this.updateContent,
    this.newImagePaths = const [],
    this.removedImagePaths = const [],
  });
  @override
  List<Object?> get props => [updateId, updateTitle, updateContent, newImagePaths, removedImagePaths];
}

class DeleteCaseUpdate extends DiscussionDetailEvent {
  final int updateId;
  const DeleteCaseUpdate(this.updateId);
  @override
  List<Object> get props => [updateId];
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

abstract class DiscussionDetailState extends Equatable {
  const DiscussionDetailState();
  @override
  List<Object?> get props => [];
}

class DiscussionDetailInitial extends DiscussionDetailState {}

class DiscussionDetailLoading extends DiscussionDetailState {}

class DiscussionDetailLoaded extends DiscussionDetailState {
  final CaseDiscussion discussion;
  final List<CaseComment> comments;
  final bool hasMoreComments;
  final bool isLoadingComments;
  final bool isAddingComment;
  final bool isGeneratingAI;
  final bool isAddingUpdate;
  final bool aiNeedsUpgrade;
  final String? aiErrorMessage;

  const DiscussionDetailLoaded({
    required this.discussion,
    required this.comments,
    this.hasMoreComments = false,
    this.isLoadingComments = false,
    this.isAddingComment = false,
    this.isGeneratingAI = false,
    this.isAddingUpdate = false,
    this.aiNeedsUpgrade = false,
    this.aiErrorMessage,
  });

  @override
  List<Object?> get props => [
        discussion,
        comments,
        hasMoreComments,
        isLoadingComments,
        isAddingComment,
        isGeneratingAI,
        isAddingUpdate,
        aiNeedsUpgrade,
        aiErrorMessage,
      ];

  DiscussionDetailLoaded copyWith({
    CaseDiscussion? discussion,
    List<CaseComment>? comments,
    bool? hasMoreComments,
    bool? isLoadingComments,
    bool? isAddingComment,
    bool? isGeneratingAI,
    bool? isAddingUpdate,
    bool? aiNeedsUpgrade,
    Object? aiErrorMessage = _sentinel,
  }) {
    return DiscussionDetailLoaded(
      discussion: discussion ?? this.discussion,
      comments: comments ?? this.comments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isAddingComment: isAddingComment ?? this.isAddingComment,
      isGeneratingAI: isGeneratingAI ?? this.isGeneratingAI,
      isAddingUpdate: isAddingUpdate ?? this.isAddingUpdate,
      aiNeedsUpgrade: aiNeedsUpgrade ?? this.aiNeedsUpgrade,
      aiErrorMessage: identical(aiErrorMessage, _sentinel)
          ? this.aiErrorMessage
          : aiErrorMessage as String?,
    );
  }
}

const _sentinel = Object();

class DiscussionDetailError extends DiscussionDetailState {
  final String message;
  const DiscussionDetailError(this.message);
  @override
  List<Object> get props => [message];
}

class DiscussionDetailDeleted extends DiscussionDetailState {}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────────────────────

class DiscussionDetailBloc
    extends Bloc<DiscussionDetailEvent, DiscussionDetailState> {
  final CaseDiscussionRepository repository;

  int _commentPage = 1;
  int? _currentCaseId;

  DiscussionDetailBloc({required this.repository})
      : super(DiscussionDetailInitial()) {
    on<LoadDiscussionDetail>(_onLoadDetail);
    on<LoadComments>(_onLoadComments);
    on<LoadMoreComments>(_onLoadMoreComments);
    on<AddComment>(_onAddComment);
    on<DeleteComment>(_onDeleteComment);
    on<UpdateComment>(_onUpdateComment);
    on<UpdateReply>(_onUpdateReply);
    on<DeleteReply>(_onDeleteReply);
    on<ToggleLikeComment>(_onToggleLikeComment);
    // Votes must not interleave: concurrent handlers would each apply their own
    // server snapshot and the slowest response would win with stale counts.
    on<VoteComment>(_onVoteComment, transformer: sequential());
    on<VoteReply>(_onVoteReply, transformer: sequential());
    on<ToggleLikeCase>(_onToggleLikeCase);
    on<VoteCase>(_onVoteCase, transformer: sequential());
    on<ToggleBookmarkCase>(_onToggleBookmarkCase);
    on<ToggleFollowCase>(_onToggleFollowCase);
    on<GenerateAISummary>(_onGenerateAISummary);
    on<AddReply>(_onAddReply);
    on<LoadReplies>(_onLoadReplies);
    on<LoadCaseUpdates>(_onLoadCaseUpdates);
    on<AddCaseUpdate>(_onAddCaseUpdate);
    on<EditCaseUpdate>(_onEditCaseUpdate);
    on<DeleteCaseUpdate>(_onDeleteCaseUpdate);
    on<DeleteCase>(_onDeleteCase);
  }

  Future<void> _onLoadDetail(
      LoadDiscussionDetail event, Emitter<DiscussionDetailState> emit) async {
    emit(DiscussionDetailLoading());
    _currentCaseId = event.caseId;
    _commentPage = 1;

    try {
      // Load discussion first
      final discussion = await repository.getCaseDiscussion(event.caseId);

      // Then load comments separately to avoid 429 rate limiting
      PaginatedResponse<CaseComment> commentsResponse;
      try {
        commentsResponse = await repository.getCaseComments(
          caseId: event.caseId, page: 1);
      } catch (_) {
        commentsResponse = PaginatedResponse<CaseComment>(
          items: [],
          pagination: PaginationMeta(
            currentPage: 1, lastPage: 1, perPage: 15, total: 0),
        );
      }

      _commentPage = 2;

      emit(DiscussionDetailLoaded(
        discussion: discussion,
        comments: commentsResponse.items,
        hasMoreComments: commentsResponse.pagination.hasNextPage,
      ));
    } catch (e) {
      emit(DiscussionDetailError(e.toString()));
    }
  }

  Future<void> _onLoadComments(
      LoadComments event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      // Don't load if already loading
      if (currentState.isLoadingComments) return;
      if (event.refresh) _commentPage = 1;
      emit(currentState.copyWith(isLoadingComments: true));

      try {
        final result = await repository.getCaseComments(
          caseId: event.caseId,
          page: _commentPage,
        );

        final comments = event.refresh
            ? result.items
            : [...currentState.comments, ...result.items];

        // Only increment page if we actually got results
        if (result.items.isNotEmpty) {
          _commentPage++;
        }

        emit(currentState.copyWith(
          comments: comments,
          hasMoreComments: result.pagination.hasNextPage,
          isLoadingComments: false,
        ));
      } catch (e) {
        // Stop pagination on error
        emit(currentState.copyWith(
          isLoadingComments: false,
          hasMoreComments: false,
        ));
      }
    }
  }

  Future<void> _onLoadMoreComments(
      LoadMoreComments event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded &&
        currentState.hasMoreComments &&
        !currentState.isLoadingComments &&
        _currentCaseId != null) {
      add(LoadComments(_currentCaseId!));
    }
  }

  Future<void> _onAddComment(
      AddComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      emit(currentState.copyWith(isAddingComment: true));

      try {
        final newComment = await repository.addComment(
          caseId: event.caseId,
          comment: event.comment,
          clinicalTags: event.clinicalTags,
        );

        final updatedComments = [newComment, ...currentState.comments];
        final updatedDiscussion = currentState.discussion.copyWith(
          commentsCount: currentState.discussion.commentsCount + 1,
        );

        emit(currentState.copyWith(
          discussion: updatedDiscussion,
          comments: updatedComments,
          isAddingComment: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isAddingComment: false));
      }
    }
  }

  Future<void> _onDeleteComment(
      DeleteComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      try {
        await repository.deleteComment(event.commentId);

        final updatedComments = currentState.comments
            .where((c) => c.id != event.commentId)
            .toList();
        final updatedDiscussion = currentState.discussion.copyWith(
          commentsCount: currentState.discussion.commentsCount - 1,
        );

        emit(currentState.copyWith(
          discussion: updatedDiscussion,
          comments: updatedComments,
        ));
      } catch (_) {}
    }
  }

  Future<void> _onUpdateComment(
      UpdateComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;

    final text = event.comment.trim();
    if (text.isEmpty) return;

    try {
      await repository.updateComment(event.commentId, text);

      final updatedComments = currentState.comments.map((comment) {
        if (comment.id != event.commentId) return comment;
        return comment.copyWith(comment: text);
      }).toList();

      emit(currentState.copyWith(comments: updatedComments));
    } catch (_) {}
  }

  Future<void> _onUpdateReply(
      UpdateReply event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;

    final text = event.reply.trim();
    if (text.isEmpty) return;

    try {
      await repository.updateReply(event.replyId, text);

      final updatedComments = currentState.comments.map((comment) {
        if (comment.id != event.commentId) return comment;
        final updatedReplies = comment.replies.map((reply) {
          if (reply.id != event.replyId) return reply;
          return reply.copyWith(reply: text);
        }).toList();
        return comment.copyWith(replies: updatedReplies);
      }).toList();

      emit(currentState.copyWith(comments: updatedComments));
    } catch (_) {}
  }

  Future<void> _onDeleteReply(
      DeleteReply event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;

    try {
      await repository.deleteReply(event.replyId);

      final updatedComments = currentState.comments.map((comment) {
        if (comment.id != event.commentId) return comment;
        final updatedReplies =
            comment.replies.where((reply) => reply.id != event.replyId).toList();
        return comment.copyWith(
          replies: updatedReplies,
          repliesCount: updatedReplies.length > 0
              ? updatedReplies.length
              : (comment.repliesCount > 0 ? comment.repliesCount - 1 : 0),
        );
      }).toList();

      emit(currentState.copyWith(comments: updatedComments));
    } catch (_) {}
  }

  Future<void> _onToggleLikeComment(
      ToggleLikeComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;
    final idx = currentState.comments.indexWhere((c) => c.id == event.commentId);
    if (idx == -1) return;
    add(VoteComment(event.commentId, 'up'));
  }

  Future<void> _onVoteComment(
      VoteComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;
    final idx = currentState.comments.indexWhere((c) => c.id == event.commentId);
    if (idx == -1) return;

    final comment = currentState.comments[idx];
    final tally = CaseVoteTally.toggle(
      likes: comment.likes,
      dislikes: comment.dislikes,
      isLiked: comment.isLiked,
      isDisliked: comment.isDisliked,
      direction: event.direction,
    );

    final updatedComments = List<CaseComment>.from(currentState.comments);
    updatedComments[idx] = comment.copyWith(
      likes: tally.likes,
      dislikes: tally.dislikes,
      isLiked: tally.isLiked,
      isDisliked: tally.isDisliked,
    );
    emit(currentState.copyWith(comments: updatedComments));

    try {
      final response = await repository.voteComment(
        commentId: event.commentId,
        direction: event.direction,
      );
      final snapshot = CaseVoteSnapshot.fromApiResponse(response);
      if (snapshot == null) return;
      _applyCommentVote(
        emit,
        commentId: event.commentId,
        likes: snapshot.likes,
        dislikes: snapshot.dislikes,
        isLiked: snapshot.isLiked,
        isDisliked: snapshot.isDisliked,
      );
    } catch (_) {
      _applyCommentVote(
        emit,
        commentId: event.commentId,
        likes: comment.likes,
        dislikes: comment.dislikes,
        isLiked: comment.isLiked,
        isDisliked: comment.isDisliked,
      );
    }
  }

  /// Re-resolves the comment by id against the *latest* state before writing.
  /// Indexes captured before the request go stale — `AddComment` prepends to
  /// the list, so a pre-await index would land the vote on the wrong comment.
  void _applyCommentVote(
    Emitter<DiscussionDetailState> emit, {
    required int commentId,
    required int likes,
    required int dislikes,
    required bool isLiked,
    required bool isDisliked,
  }) {
    final latest = state;
    if (latest is! DiscussionDetailLoaded) return;
    final idx = latest.comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final comments = List<CaseComment>.from(latest.comments);
    comments[idx] = comments[idx].copyWith(
      likes: likes,
      dislikes: dislikes,
      isLiked: isLiked,
      isDisliked: isDisliked,
    );
    emit(latest.copyWith(comments: comments));
  }

  Future<void> _onVoteReply(
      VoteReply event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;

    final commentIdx =
        currentState.comments.indexWhere((c) => c.id == event.commentId);
    if (commentIdx == -1) return;

    final comment = currentState.comments[commentIdx];
    final replyIdx = comment.replies.indexWhere((r) => r.id == event.replyId);
    if (replyIdx == -1) return;

    final reply = comment.replies[replyIdx];
    final tally = CaseVoteTally.toggle(
      likes: reply.likes,
      dislikes: reply.dislikes,
      isLiked: reply.isLiked,
      isDisliked: reply.isDisliked,
      direction: event.direction,
    );

    _applyReplyVote(
      emit,
      commentId: event.commentId,
      replyId: event.replyId,
      likes: tally.likes,
      dislikes: tally.dislikes,
      isLiked: tally.isLiked,
      isDisliked: tally.isDisliked,
    );

    try {
      final response = await repository.voteComment(
        commentId: event.replyId,
        direction: event.direction,
        targetType: 'reply',
      );
      final snapshot = CaseVoteSnapshot.fromApiResponse(response);
      if (snapshot == null) return;
      _applyReplyVote(
        emit,
        commentId: event.commentId,
        replyId: event.replyId,
        likes: snapshot.likes,
        dislikes: snapshot.dislikes,
        isLiked: snapshot.isLiked,
        isDisliked: snapshot.isDisliked,
      );
    } catch (_) {
      _applyReplyVote(
        emit,
        commentId: event.commentId,
        replyId: event.replyId,
        likes: reply.likes,
        dislikes: reply.dislikes,
        isLiked: reply.isLiked,
        isDisliked: reply.isDisliked,
      );
    }
  }

  /// Same re-resolve-by-id rule as [_applyCommentVote], for a nested reply.
  void _applyReplyVote(
    Emitter<DiscussionDetailState> emit, {
    required int commentId,
    required int replyId,
    required int likes,
    required int dislikes,
    required bool isLiked,
    required bool isDisliked,
  }) {
    final latest = state;
    if (latest is! DiscussionDetailLoaded) return;
    final commentIdx = latest.comments.indexWhere((c) => c.id == commentId);
    if (commentIdx == -1) return;

    final target = latest.comments[commentIdx];
    final replyIdx = target.replies.indexWhere((r) => r.id == replyId);
    if (replyIdx == -1) return;

    final replies = List<CaseReply>.from(target.replies);
    replies[replyIdx] = replies[replyIdx].copyWith(
      likes: likes,
      dislikes: dislikes,
      isLiked: isLiked,
      isDisliked: isDisliked,
    );

    final comments = List<CaseComment>.from(latest.comments);
    comments[commentIdx] = target.copyWith(replies: replies);
    emit(latest.copyWith(comments: comments));
  }

  Future<void> _onToggleLikeCase(
      ToggleLikeCase event, Emitter<DiscussionDetailState> emit) async {
    add(VoteCase(event.caseId, 'up'));
  }

  Future<void> _onVoteCase(
      VoteCase event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;
    final d = currentState.discussion;
    final tally = CaseVoteTally.toggle(
      likes: d.likes,
      dislikes: d.dislikes,
      isLiked: d.isLiked,
      isDisliked: d.isDisliked,
      direction: event.direction,
    );

    _applyCaseVote(
      emit,
      caseId: event.caseId,
      likes: tally.likes,
      dislikes: tally.dislikes,
      isLiked: tally.isLiked,
      isDisliked: tally.isDisliked,
    );

    try {
      final response = await repository.voteCase(
          caseId: event.caseId, direction: event.direction);
      final snapshot = CaseVoteSnapshot.fromApiResponse(response);
      if (snapshot == null) return;
      _applyCaseVote(
        emit,
        caseId: event.caseId,
        likes: snapshot.likes,
        dislikes: snapshot.dislikes,
        isLiked: snapshot.isLiked,
        isDisliked: snapshot.isDisliked,
      );
    } catch (_) {
      _applyCaseVote(
        emit,
        caseId: event.caseId,
        likes: d.likes,
        dislikes: d.dislikes,
        isLiked: d.isLiked,
        isDisliked: d.isDisliked,
      );
    }
  }

  /// Writes vote counts onto the *latest* discussion so comments/updates loaded
  /// while the request was in flight are not rolled back with it.
  void _applyCaseVote(
    Emitter<DiscussionDetailState> emit, {
    required int caseId,
    required int likes,
    required int dislikes,
    required bool isLiked,
    required bool isDisliked,
  }) {
    final latest = state;
    if (latest is! DiscussionDetailLoaded) return;
    if (latest.discussion.id != caseId) return;

    emit(latest.copyWith(
      discussion: latest.discussion.copyWith(
        likes: likes,
        dislikes: dislikes,
        isLiked: isLiked,
        isDisliked: isDisliked,
      ),
    ));
  }

  Future<void> _onToggleBookmarkCase(
      ToggleBookmarkCase event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      final d = currentState.discussion;
      final was = d.isBookmarked;

      emit(currentState.copyWith(
        discussion: d.copyWith(isBookmarked: !was),
      ));

      try {
        await repository.performCaseAction(
          caseId: event.caseId,
          action: was ? 'unbookmark' : 'bookmark',
        );
      } catch (_) {
        emit(currentState.copyWith(discussion: d));
      }
    }
  }

  Future<void> _onToggleFollowCase(
      ToggleFollowCase event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      final d = currentState.discussion;
      final was = d.isFollowing;

      emit(currentState.copyWith(
        discussion: d.copyWith(
          isFollowing: !was,
          followersCount:
              was ? d.followersCount - 1 : d.followersCount + 1,
        ),
      ));

      try {
        if (was) {
          await repository.unfollowCase(event.caseId);
        } else {
          await repository.followCase(event.caseId);
        }
      } catch (_) {
        emit(currentState.copyWith(discussion: d));
      }
    }
  }

  Future<void> _onGenerateAISummary(
      GenerateAISummary event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      emit(currentState.copyWith(
        isGeneratingAI: true,
        aiNeedsUpgrade: false,
        aiErrorMessage: null,
      ));

      try {
        final result = await repository.generateAISummary(event.caseId);
        // Update remaining count in the discussion model
        final updatedDiscussion = currentState.discussion.copyWith(
          aiSummary: result.summary,
          aiSummaryRemaining: result.remaining,
        );
        emit(currentState.copyWith(
          discussion: updatedDiscussion,
          isGeneratingAI: false,
          aiNeedsUpgrade: false,
          aiErrorMessage: null,
        ));
      } on AISummaryUpgradeException catch (e) {
        emit(currentState.copyWith(
          isGeneratingAI: false,
          aiNeedsUpgrade: true,
          aiErrorMessage: e.message,
        ));
      } catch (e) {
        emit(currentState.copyWith(
          isGeneratingAI: false,
          aiErrorMessage: 'Failed to generate AI summary. Please try again.',
        ));
      }
    }
  }

  Future<void> _onAddReply(
      AddReply event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is! DiscussionDetailLoaded) return;

    final text = event.reply.trim();
    if (text.isEmpty) return;

    final commentIdx =
        currentState.comments.indexWhere((c) => c.id == event.commentId);
    if (commentIdx == -1) return;

    final comment = currentState.comments[commentIdx];
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final optimisticReply = CaseReply(
      id: tempId,
      commentId: event.commentId,
      userId: AppData.logInUserId ?? 0,
      reply: text,
      createdAt: DateTime.now(),
      author: CaseAuthor(
        id: AppData.logInUserId ?? 0,
        name: AppData.name.isNotEmpty ? AppData.name : 'You',
        specialty: '',
        profilePic: AppData.profilePicUrl.isNotEmpty ? AppData.profilePicUrl : null,
        isVerified: false,
      ),
      isOwner: true,
    );

    final optimisticComments = List<CaseComment>.from(currentState.comments);
    optimisticComments[commentIdx] = comment.copyWith(
      repliesCount: comment.repliesCount + 1,
      replies: [...comment.replies, optimisticReply],
    );
    emit(currentState.copyWith(comments: optimisticComments));

    try {
      final newReply = await repository.addReply(
        commentId: event.commentId,
        reply: text,
      );

      final latestState = state;
      if (latestState is! DiscussionDetailLoaded) return;

      final idx =
          latestState.comments.indexWhere((c) => c.id == event.commentId);
      if (idx == -1) return;

      final latestComment = latestState.comments[idx];
      final mergedReplies = latestComment.replies
          .where((r) => r.id != tempId)
          .toList();
      if (!mergedReplies.any((r) => r.id == newReply.id)) {
        mergedReplies.add(newReply);
      }

      final syncedComments = List<CaseComment>.from(latestState.comments);
      syncedComments[idx] = latestComment.copyWith(
        replies: mergedReplies,
        repliesCount: mergedReplies.length > latestComment.repliesCount
            ? mergedReplies.length
            : latestComment.repliesCount,
      );

      emit(latestState.copyWith(comments: syncedComments));
    } catch (_) {
      final latestState = state;
      if (latestState is! DiscussionDetailLoaded) return;

      final idx =
          latestState.comments.indexWhere((c) => c.id == event.commentId);
      if (idx == -1) return;

      final failedComment = latestState.comments[idx];
      final revertedReplies = failedComment.replies
          .where((r) => r.id != tempId)
          .toList();
      final revertedComments = List<CaseComment>.from(latestState.comments);
      revertedComments[idx] = failedComment.copyWith(
        replies: revertedReplies,
        repliesCount: failedComment.repliesCount > 0
            ? failedComment.repliesCount - 1
            : 0,
      );

      emit(latestState.copyWith(comments: revertedComments));
    }
  }

  Future<void> _onLoadReplies(
      LoadReplies event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      try {
        final replies = await repository.getReplies(event.commentId);

        final updatedComments = currentState.comments.map((c) {
          if (c.id == event.commentId) {
            return c.copyWith(replies: replies);
          }
          return c;
        }).toList();

        emit(currentState.copyWith(comments: updatedComments));
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIMELINE / UPDATES HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadCaseUpdates(
      LoadCaseUpdates event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      try {
        final updates = await repository.getCaseUpdates(event.caseId);
        final updatedDiscussion =
            currentState.discussion.copyWith(updates: updates);
        emit(currentState.copyWith(discussion: updatedDiscussion));
      } catch (_) {}
    }
  }

  Future<void> _onAddCaseUpdate(
      AddCaseUpdate event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      emit(currentState.copyWith(isAddingUpdate: true));

      try {
        final newUpdate = await repository.createCaseUpdate(
          caseId: event.caseId,
          updateType: event.updateTitle,
          content: event.updateContent,
          imagePaths: event.imagePaths,
        );

        final updatedUpdates = [
          newUpdate,
          ...currentState.discussion.updates
        ];
        final updatedDiscussion =
            currentState.discussion.copyWith(updates: updatedUpdates);

        emit(currentState.copyWith(
          discussion: updatedDiscussion,
          isAddingUpdate: false,
        ));
      } catch (_) {
        emit(currentState.copyWith(isAddingUpdate: false));
      }
    }
  }

  Future<void> _onEditCaseUpdate(
      EditCaseUpdate event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      try {
        final edited = await repository.editCaseUpdate(
          updateId: event.updateId,
          updateTitle: event.updateTitle,
          updateContent: event.updateContent,
          newImagePaths: event.newImagePaths,
          removedImagePaths: event.removedImagePaths,
        );

        final updatedUpdates = currentState.discussion.updates.map((u) {
          if (u.id == event.updateId) return edited;
          return u;
        }).toList();

        final updatedDiscussion =
            currentState.discussion.copyWith(updates: updatedUpdates);
        emit(currentState.copyWith(discussion: updatedDiscussion));
      } catch (_) {}
    }
  }

  Future<void> _onDeleteCaseUpdate(
      DeleteCaseUpdate event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      try {
        await repository.deleteCaseUpdate(event.updateId);

        final updatedUpdates = currentState.discussion.updates
            .where((u) => u.id != event.updateId)
            .toList();

        final updatedDiscussion =
            currentState.discussion.copyWith(updates: updatedUpdates);
        emit(currentState.copyWith(discussion: updatedDiscussion));
      } catch (_) {}
    }
  }

  Future<void> _onDeleteCase(
      DeleteCase event, Emitter<DiscussionDetailState> emit) async {
    try {
      await repository.deleteCase(event.caseId);
      emit(DiscussionDetailDeleted());
    } catch (_) {}
  }
}
