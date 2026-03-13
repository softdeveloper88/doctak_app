// ============================================================================
// Discussion Detail BLoC - v6 API
// Handles case detail, comments (paginated), replies, like/bookmark/follow
// actions, and AI summary generation.
// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/case_discussion_repository.dart';
import '../models/case_discussion_models.dart';

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

class ToggleLikeComment extends DiscussionDetailEvent {
  final int commentId;
  const ToggleLikeComment(this.commentId);
  @override
  List<Object> get props => [commentId];
}

class ToggleLikeCase extends DiscussionDetailEvent {
  final int caseId;
  const ToggleLikeCase(this.caseId);
  @override
  List<Object> get props => [caseId];
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
    on<ToggleLikeComment>(_onToggleLikeComment);
    on<ToggleLikeCase>(_onToggleLikeCase);
    on<ToggleBookmarkCase>(_onToggleBookmarkCase);
    on<ToggleFollowCase>(_onToggleFollowCase);
    on<GenerateAISummary>(_onGenerateAISummary);
    on<AddReply>(_onAddReply);
    on<LoadReplies>(_onLoadReplies);
    on<LoadCaseUpdates>(_onLoadCaseUpdates);
    on<AddCaseUpdate>(_onAddCaseUpdate);
    on<EditCaseUpdate>(_onEditCaseUpdate);
    on<DeleteCaseUpdate>(_onDeleteCaseUpdate);
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

  Future<void> _onToggleLikeComment(
      ToggleLikeComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      final idx =
          currentState.comments.indexWhere((c) => c.id == event.commentId);
      if (idx == -1) return;

      final comment = currentState.comments[idx];
      final wasLiked = comment.isLiked;

      // Optimistic
      final updated = comment.copyWith(
        isLiked: !wasLiked,
        likes: wasLiked ? comment.likes - 1 : comment.likes + 1,
      );
      final updatedComments = List<CaseComment>.from(currentState.comments);
      updatedComments[idx] = updated;
      emit(currentState.copyWith(comments: updatedComments));

      try {
        await repository.performCommentAction(
          commentId: event.commentId,
          action: wasLiked ? 'unlike' : 'like',
        );
      } catch (_) {
        // Revert
        final reverted = List<CaseComment>.from(currentState.comments);
        emit(currentState.copyWith(comments: reverted));
      }
    }
  }

  Future<void> _onToggleLikeCase(
      ToggleLikeCase event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      final d = currentState.discussion;
      final wasLiked = d.isLiked;

      // Optimistic
      emit(currentState.copyWith(
        discussion: d.copyWith(
          isLiked: !wasLiked,
          likes: wasLiked ? d.likes - 1 : d.likes + 1,
        ),
      ));

      try {
        await repository.performCaseAction(
          caseId: event.caseId,
          action: wasLiked ? 'unlike' : 'like',
        );
      } catch (_) {
        emit(currentState.copyWith(discussion: d));
      }
    }
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
    if (currentState is DiscussionDetailLoaded) {
      try {
        final newReply = await repository.addReply(
          commentId: event.commentId,
          reply: event.reply,
        );

        final updatedComments = currentState.comments.map((c) {
          if (c.id == event.commentId) {
            return c.copyWith(
              repliesCount: c.repliesCount + 1,
              replies: [...c.replies, newReply],
            );
          }
          return c;
        }).toList();

        emit(currentState.copyWith(comments: updatedComments));
      } catch (_) {}
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
}
