import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_sheet_widgets.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/memory_optimized_comment_item.dart';
import 'package:doctak_app/widgets/shimmer_widget/enhanced_comment_shimmer.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Toggle or expand the reply thread for a comment.
typedef CommentReplySelectedCallback = void Function(
  int commentId, {
  bool expandOnly,
});

/// Virtualized list for displaying comments with memory optimizations
class VirtualizedCommentList extends StatefulWidget {
  final CommentBloc commentBloc;
  final ScrollController? scrollController;
  final int? selectedCommentId;
  final int? focusReplyForCommentId;
  final CommentReplySelectedCallback onReplySelected;
  final VoidCallback? onReplyFocusHandled;
  final bool isBottomSheet;

  const VirtualizedCommentList({
    super.key,
    required this.commentBloc,
    this.scrollController,
    this.selectedCommentId,
    this.focusReplyForCommentId,
    required this.onReplySelected,
    this.onReplyFocusHandled,
    this.isBottomSheet = false,
  });

  @override
  State<VirtualizedCommentList> createState() => _VirtualizedCommentListState();
}

class _VirtualizedCommentListState extends State<VirtualizedCommentList> {
  // Track which comment items are currently visible for optimization
  final Set<int> _visibleCommentIndices = {};

  @override
  void dispose() {
    _visibleCommentIndices.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.commentBloc;

    return _buildVirtualizedCommentList();
  }

  // Virtualized list implementation
  Widget _buildVirtualizedCommentList() {
    final bloc = widget.commentBloc;
    final theme = OneUITheme.of(context);

    // Show empty state if no comments
    if (bloc.postList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 48, color: theme.textTertiary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                translation(context).msg_no_comments_yet,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.textSecondary, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 6),
              Text(
                translation(context).msg_be_first_to_comment,
                style: TextStyle(fontSize: CommentSheetTokens.bodySize, color: theme.textTertiary, fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        top: 4,
        bottom: widget.isBottomSheet ? 8 : MediaQuery.of(context).padding.bottom + 70,
      ),
      itemCount: bloc.postList.length,
      // Using cacheExtent to preload items beyond the visible area
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        // Check if we need to load more data
        if (bloc.pageNumber <= bloc.numberOfPage) {
          if (index == bloc.postList.length - bloc.nextPageTrigger) {
            bloc.add(CheckIfNeedMoreDataEvent(index: index));
          }
        }

        // Show shimmer loader at the bottom if loading more
        if (bloc.numberOfPage != bloc.pageNumber - 1 && index >= bloc.postList.length - 1) {
          return const SizedBox(height: 200, child: EnhancedCommentShimmer());
        }
        // Regular comment item
        else {
          return _buildLazyLoadCommentItem(index);
        }
      },
    );
  }

  // Lazy loading comment item implementation
  Widget _buildLazyLoadCommentItem(int index) {
    return VisibilityDetector(
      key: Key('comment_visibility_${widget.commentBloc.postList[index].id}'),
      onVisibilityChanged: (visibilityInfo) {
        final isVisible = visibilityInfo.visibleFraction > 0.1;
        _handleVisibilityChanged(index, isVisible);
      },
      child: MemoryOptimizedCommentItem(
        comment: widget.commentBloc.postList[index],
        commentBloc: widget.commentBloc,
        postId: widget.commentBloc.contentId,
        selectedCommentId: widget.selectedCommentId,
        focusReplyForCommentId: widget.focusReplyForCommentId,
        onReplySelected: widget.onReplySelected,
        onReplyFocusHandled: widget.onReplyFocusHandled,
      ),
    );
  }

  // Track which comments are visible for optimization
  void _handleVisibilityChanged(int index, bool isVisible) {
    if (isVisible) {
      _visibleCommentIndices.add(index);
    } else {
      _visibleCommentIndices.remove(index);
    }

    // Can be used for analytics or optimization in the future
  }
}
