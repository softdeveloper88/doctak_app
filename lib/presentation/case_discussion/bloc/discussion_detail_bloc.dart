import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/case_discussion_repository.dart';
import '../models/case_discussion_models.dart';

// Events
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

  const AddComment({required this.caseId, required this.comment, this.clinicalTags});

  @override
  List<Object?> get props => [caseId, comment, clinicalTags];
}

class LikeComment extends DiscussionDetailEvent {
  final int commentId;

  const LikeComment(this.commentId);

  @override
  List<Object> get props => [commentId];
}

class DeleteComment extends DiscussionDetailEvent {
  final int commentId;

  const DeleteComment(this.commentId);

  @override
  List<Object> get props => [commentId];
}

class LikeCase extends DiscussionDetailEvent {
  final int caseId;

  const LikeCase(this.caseId);

  @override
  List<Object> get props => [caseId];
}

// States
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

  const DiscussionDetailLoaded({required this.discussion, required this.comments, required this.hasMoreComments, this.isLoadingComments = false, this.isAddingComment = false});

  @override
  List<Object> get props => [discussion, comments, hasMoreComments, isLoadingComments, isAddingComment];

  DiscussionDetailLoaded copyWith({CaseDiscussion? discussion, List<CaseComment>? comments, bool? hasMoreComments, bool? isLoadingComments, bool? isAddingComment}) {
    return DiscussionDetailLoaded(
      discussion: discussion ?? this.discussion,
      comments: comments ?? this.comments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isAddingComment: isAddingComment ?? this.isAddingComment,
    );
  }
}

class DiscussionDetailError extends DiscussionDetailState {
  final String message;

  const DiscussionDetailError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class DiscussionDetailBloc extends Bloc<DiscussionDetailEvent, DiscussionDetailState> {
  final CaseDiscussionRepository repository;

  int _currentPage = 1;
  int? _currentCaseId;

  DiscussionDetailBloc({required this.repository}) : super(DiscussionDetailInitial()) {
    on<LoadDiscussionDetail>(_onLoadDiscussionDetail);
    on<LoadComments>(_onLoadComments);
    on<LoadMoreComments>(_onLoadMoreComments);
    on<AddComment>(_onAddComment);
    on<LikeComment>(_onLikeComment);
    on<DeleteComment>(_onDeleteComment);
    on<LikeCase>(_onLikeCase);
  }

  Future<void> _onLoadDiscussionDetail(LoadDiscussionDetail event, Emitter<DiscussionDetailState> emit) async {
    emit(DiscussionDetailLoading());
    _currentCaseId = event.caseId;

    try {
      print('🔄 Loading discussion and comments for case: ${event.caseId}');

      // Load both discussion and comments in one go since the new API provides both
      final discussion = await repository.getCaseDiscussion(event.caseId);
      final commentsResponse = await repository.getCaseComments(caseId: event.caseId);

      print('✅ Discussion loaded: ${discussion.title}');
      print('💬 Comments loaded: ${commentsResponse.items.length}');

      emit(DiscussionDetailLoaded(discussion: discussion, comments: commentsResponse.items, hasMoreComments: commentsResponse.pagination.hasNextPage));
    } catch (e) {
      print('❌ Error loading discussion detail: $e');
      emit(DiscussionDetailError(e.toString()));
    }
  }

  Future<void> _onLoadComments(LoadComments event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      if (event.refresh) {
        _currentPage = 1;
      }

      emit(currentState.copyWith(isLoadingComments: true));

      try {
        final result = await repository.getCaseComments(caseId: event.caseId, page: _currentPage);

        final comments = event.refresh ? result.items : [...currentState.comments, ...result.items];
        _currentPage++;

        emit(currentState.copyWith(comments: comments, hasMoreComments: result.pagination.hasNextPage, isLoadingComments: false));
      } catch (e) {
        emit(currentState.copyWith(isLoadingComments: false));
      }
    }
  }

  Future<void> _onLoadMoreComments(LoadMoreComments event, Emitter<DiscussionDetailState> emit) async {
    if (_currentCaseId != null) {
      add(LoadComments(_currentCaseId!));
    }
  }

  Future<void> _onAddComment(AddComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      // OPTIMISTIC UPDATE: Add comment to UI immediately
      final optimisticComment = CaseComment(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        caseId: event.caseId,
        userId: 'current_user', // Should be current user ID
        comment: event.comment,
        clinicalTags: event.clinicalTags,
        likes: 0,
        dislikes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        author: CaseAuthor(
          id: 'current_user',
          name: 'You', // This should be current user name
          specialty: '',
          profilePic: null,
        ),
        repliesCount: 0,
        isLiked: false,
        isDisliked: false,
      );

      // Update stats optimistically
      final updatedStats = CaseStats(
        commentsCount: currentState.discussion.stats.commentsCount + 1,
        followersCount: currentState.discussion.stats.followersCount,
        updatesCount: currentState.discussion.stats.updatesCount,
        likes: currentState.discussion.stats.likes,
        views: currentState.discussion.stats.views,
      );

      final updatedDiscussion = CaseDiscussion(
        id: currentState.discussion.id,
        title: currentState.discussion.title,
        description: currentState.discussion.description,
        status: currentState.discussion.status,
        specialty: currentState.discussion.specialty,
        createdAt: currentState.discussion.createdAt,
        updatedAt: currentState.discussion.updatedAt,
        author: currentState.discussion.author,
        stats: updatedStats,
        patientInfo: currentState.discussion.patientInfo,
        symptoms: currentState.discussion.symptoms,
        diagnosis: currentState.discussion.diagnosis,
        treatmentPlan: currentState.discussion.treatmentPlan,
        attachments: currentState.discussion.attachments,
        aiSummary: currentState.discussion.aiSummary,
        metadata: currentState.discussion.metadata,
        isFollowing: currentState.discussion.isFollowing,
        relatedCases: currentState.discussion.relatedCases,
      );

      final optimisticComments = [optimisticComment, ...currentState.comments];

      // Emit optimistic state immediately
      emit(currentState.copyWith(discussion: updatedDiscussion, comments: optimisticComments, isAddingComment: true));

      try {
        // Make API call in background
        final newComment = await repository.addComment(caseId: event.caseId, comment: event.comment, clinicalTags: event.clinicalTags);

        // Replace optimistic comment with real one from server
        final updatedComments = [newComment, ...currentState.comments];

        emit(currentState.copyWith(discussion: updatedDiscussion, comments: updatedComments, isAddingComment: false));

        print('✅ Comment added and synced with server');
      } catch (e) {
        print('❌ Error adding comment, reverting: $e');
        // REVERT: Remove optimistic comment and revert stats
        emit(currentState.copyWith(comments: currentState.comments, isAddingComment: false));
      }
    }
  }

  Future<void> _onLikeComment(LikeComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      // OPTIMISTIC UPDATE: Update UI immediately
      final optimisticComments = currentState.comments.map((comment) {
        if (comment.id == event.commentId) {
          final isCurrentlyLiked = comment.isLiked ?? false;
          return CaseComment(
            id: comment.id,
            caseId: comment.caseId,
            userId: comment.userId,
            comment: comment.comment,
            clinicalTags: comment.clinicalTags,
            likes: isCurrentlyLiked ? comment.likes - 1 : comment.likes + 1,
            dislikes: comment.dislikes,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            author: comment.author,
            repliesCount: comment.repliesCount,
            isLiked: !isCurrentlyLiked,
            isDisliked: comment.isDisliked,
          );
        }
        return comment;
      }).toList();

      // Emit optimistic state immediately
      emit(currentState.copyWith(comments: optimisticComments));

      try {
        // Determine action based on current like state
        final comment = currentState.comments.firstWhere((c) => c.id == event.commentId);
        final isCurrentlyLiked = comment.isLiked ?? false;
        final action = isCurrentlyLiked ? 'unlike' : 'like';

        // Make API call in background
        await repository.likeComment(commentId: event.commentId, action: action);
        print('✅ Comment $action synced with server');
      } catch (e) {
        print('❌ Error liking comment, reverting: $e');
        // REVERT: If API fails, revert the optimistic update
        emit(currentState.copyWith(comments: currentState.comments));
      }
    }
  }

  Future<void> _onDeleteComment(DeleteComment event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      try {
        await repository.deleteComment(event.commentId);

        final updatedComments = currentState.comments.where((comment) => comment.id != event.commentId).toList();

        // Update discussion stats
        final updatedStats = CaseStats(
          commentsCount: currentState.discussion.stats.commentsCount - 1,
          followersCount: currentState.discussion.stats.followersCount,
          updatesCount: currentState.discussion.stats.updatesCount,
          likes: currentState.discussion.stats.likes,
          views: currentState.discussion.stats.views,
        );

        final updatedDiscussion = CaseDiscussion(
          id: currentState.discussion.id,
          title: currentState.discussion.title,
          description: currentState.discussion.description,
          status: currentState.discussion.status,
          specialty: currentState.discussion.specialty,
          createdAt: currentState.discussion.createdAt,
          updatedAt: currentState.discussion.updatedAt,
          author: currentState.discussion.author,
          stats: updatedStats,
          patientInfo: currentState.discussion.patientInfo,
          symptoms: currentState.discussion.symptoms,
          diagnosis: currentState.discussion.diagnosis,
          treatmentPlan: currentState.discussion.treatmentPlan,
          attachments: currentState.discussion.attachments,
          aiSummary: currentState.discussion.aiSummary,
        );

        emit(currentState.copyWith(discussion: updatedDiscussion, comments: updatedComments));
      } catch (e) {
        print('Error deleting comment: $e');
      }
    }
  }

  Future<void> _onLikeCase(LikeCase event, Emitter<DiscussionDetailState> emit) async {
    final currentState = state;
    if (currentState is DiscussionDetailLoaded) {
      // OPTIMISTIC UPDATE: Update case likes immediately
      final updatedStats = CaseStats(
        commentsCount: currentState.discussion.stats.commentsCount,
        followersCount: currentState.discussion.stats.followersCount,
        updatesCount: currentState.discussion.stats.updatesCount,
        likes: currentState.discussion.stats.likes + 1,
        views: currentState.discussion.stats.views,
      );

      final updatedDiscussion = CaseDiscussion(
        id: currentState.discussion.id,
        title: currentState.discussion.title,
        description: currentState.discussion.description,
        status: currentState.discussion.status,
        specialty: currentState.discussion.specialty,
        createdAt: currentState.discussion.createdAt,
        updatedAt: currentState.discussion.updatedAt,
        author: currentState.discussion.author,
        stats: updatedStats,
        patientInfo: currentState.discussion.patientInfo,
        symptoms: currentState.discussion.symptoms,
        diagnosis: currentState.discussion.diagnosis,
        treatmentPlan: currentState.discussion.treatmentPlan,
        attachments: currentState.discussion.attachments,
        aiSummary: currentState.discussion.aiSummary,
        metadata: currentState.discussion.metadata,
        isFollowing: currentState.discussion.isFollowing,
        relatedCases: currentState.discussion.relatedCases,
      );

      // Emit optimistic state immediately
      emit(currentState.copyWith(discussion: updatedDiscussion));

      try {
        // For now, assuming we're always liking (need to add like state to case model)
        // TODO: Add isLiked field to CaseDiscussion model for proper toggle
        await repository.performCaseAction(caseId: event.caseId, action: 'like');
        print('✅ Case like synced with server');
      } catch (e) {
        print('❌ Error liking case, reverting: $e');
        // REVERT: If API fails, revert the optimistic update
        emit(currentState.copyWith(discussion: currentState.discussion));
      }
    }
  }
}
