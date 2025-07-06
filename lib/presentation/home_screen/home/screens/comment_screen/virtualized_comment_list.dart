import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/memory_optimized_comment_item.dart';
import 'package:doctak_app/widgets/shimmer_widget/enhanced_comment_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Virtualized list for displaying comments with memory optimizations
class VirtualizedCommentList extends StatefulWidget {
  final CommentBloc commentBloc;
  final ScrollController? scrollController;
  final int postId;
  final int? selectedCommentId;
  final Function(int) onReplySelected;

  const VirtualizedCommentList({
    super.key,
    required this.commentBloc,
    this.scrollController,
    required this.postId,
    this.selectedCommentId,
    required this.onReplySelected,
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

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 70), // Reduced padding
      itemCount: bloc.postList.length,
      // Using cacheExtent to preload items beyond the visible area
      cacheExtent: 1000,
      itemBuilder: (context, index) {
        // Check if we need to load more data
        if (bloc.pageNumber <= bloc.numberOfPage) {
          if (index == bloc.postList.length - bloc.nextPageTrigger) {
            bloc.add(
              CheckIfNeedMoreDataEvent(postId: widget.postId, index: index),
            );
          }
        }

        // Show shimmer loader at the bottom if loading more
        if (bloc.numberOfPage != bloc.pageNumber - 1 &&
            index >= bloc.postList.length - 1) {
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
        postId: widget.postId.toString(),
        selectedCommentId: widget.selectedCommentId,
        onReplySelected: widget.onReplySelected,
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
