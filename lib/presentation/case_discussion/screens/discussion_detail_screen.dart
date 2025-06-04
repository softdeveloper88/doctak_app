import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import '../bloc/discussion_detail_bloc.dart';
import '../models/case_discussion_models.dart';
import '../widgets/comment_card.dart';
import '../widgets/comment_input.dart';
import '../widgets/discussion_header.dart';
import '../widgets/case_discussion_shimmer.dart';
import '../../../localization/app_localization.dart';
import '../../home_screen/utils/SVColors.dart';
import '../../home_screen/utils/SVCommon.dart';

class DiscussionDetailScreen extends StatefulWidget {
  final int caseId;

  const DiscussionDetailScreen({
    Key? key,
    required this.caseId,
  }) : super(key: key);

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<DiscussionDetailBloc>().add(LoadDiscussionDetail(widget.caseId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<DiscussionDetailBloc>().add(LoadMoreComments());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _addComment() {
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      context.read<DiscussionDetailBloc>().add(AddComment(
        caseId: widget.caseId,
        comment: comment,
      ));
      _commentController.clear();
      _commentFocusNode.unfocus();
      _showFeedback('Comment added successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        toolbarHeight: 70,
        surfaceTintColor: svGetScaffoldColor(),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue[600],
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: BlocBuilder<DiscussionDetailBloc, DiscussionDetailState>(
          builder: (context, state) {
            final commentCount = state is DiscussionDetailLoaded ? state.comments.length : 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_information_rounded,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Case Discussion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.blue[800],
                  ),
                ),
                if (commentCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          commentCount.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          // Share button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_rounded,
                  color: Colors.blue[600],
                  size: 14,
                ),
              ),
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: svGetScaffoldColor(),
        child: BlocBuilder<DiscussionDetailBloc, DiscussionDetailState>(
          builder: (context, state) {
            if (state is DiscussionDetailLoading) {
              return const CaseDiscussionShimmer();
            }

            if (state is DiscussionDetailError) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error Loading Discussion',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DiscussionDetailBloc>()
                            .add(LoadDiscussionDetail(widget.caseId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Retry',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is DiscussionDetailLoaded) {
              print('🎯 DiscussionDetailLoaded state:');
              print('📋 Discussion: ${state.discussion.title}');
              print('💬 Comments count: ${state.comments.length}');
              print('🔄 Has more comments: ${state.hasMoreComments}');
              if (state.comments.isNotEmpty) {
                print('💬 First comment: ${state.comments.first.comment}');
                print('👤 First comment author: ${state.comments.first.author.name}');
              }
              
              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        print('🔄 User triggered refresh for case: ${widget.caseId}');
                        context.read<DiscussionDetailBloc>()
                            .add(LoadDiscussionDetail(widget.caseId));
                      },
                      color: Colors.blue[600],
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Discussion header
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              child: DiscussionHeader(
                                discussion: state.discussion,
                                onLike: () => _likeCase(state.discussion.id),
                              ),
                            ),
                          ),
                          
                          // Comments header
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.1),
                                    Colors.green.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.green[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Comments',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${state.comments.length}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Comments list
                          state.comments.isNotEmpty
                              ? SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final comment = state.comments[index];
                                      print('🏗️ Building comment[$index]: "${comment.comment}" by ${comment.author.name}');
                                      return Container(
                                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                        child: CommentCard(
                                          comment: comment,
                                          onLike: () => _likeComment(comment.id),
                                          onDelete: () => _deleteComment(comment.id),
                                        ),
                                      );
                                    },
                                    childCount: state.comments.length,
                                  ),
                                )
                              : SliverToBoxAdapter(
                                  child: Container(
                                    margin: const EdgeInsets.all(32),
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Comments Yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Be the first to share your medical insights on this case.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            color: Colors.grey[500],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          
                          // Related Cases Section
                          if (state.discussion.relatedCases != null && state.discussion.relatedCases!.isNotEmpty) ...[
                            // Related cases header
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.1),
                                      Colors.blue.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      color: Colors.blue[600],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Related Cases',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${state.discussion.relatedCases!.length}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Related cases list
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final relatedCase = state.discussion.relatedCases![index];
                                  return Container(
                                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: InkWell(
                                      onTap: () {
                                        // Navigate to the related case
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DiscussionDetailScreen(
                                              caseId: relatedCase.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.1),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.05),
                                              offset: const Offset(0, 2),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Title
                                            Text(
                                              relatedCase.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                                color: Colors.blue[900],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Description
                                            Text(
                                              relatedCase.description,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                                color: Colors.black87,
                                                height: 1.5,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            
                                            // Tags if available
                                            if (relatedCase.parsedTags != null && relatedCase.parsedTags!.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: relatedCase.parsedTags!.take(3).map((tag) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.blue.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontFamily: 'Poppins',
                                                        color: Colors.blue[700],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                            
                                            const SizedBox(height: 12),
                                            
                                            // Stats row
                                            Row(
                                              children: [
                                                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  relatedCase.likes.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  relatedCase.views.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blue[600]),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: state.discussion.relatedCases!.length,
                              ),
                            ),
                          ],
                          
                          // Bottom padding for comment input
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 80),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: CommentInput(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      onSubmit: _addComment,
                      isLoading: state.isAddingComment,
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _likeComment(int commentId) {
    context.read<DiscussionDetailBloc>().add(LikeComment(commentId));
    _showFeedback('Comment liked!');
  }

  void _likeCase(int caseId) {
    context.read<DiscussionDetailBloc>().add(LikeCase(caseId));
    _showFeedback('Case liked!');
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteComment(int commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DiscussionDetailBloc>().add(DeleteComment(commentId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _getItemCount(DiscussionDetailLoaded state) {
    int count = 1; // Discussion header
    print('📊 Calculating item count:');
    print('   - Discussion header: 1');
    
    // Add comments section
    count += 1; // Comments header (always show)
    print('   - Comments header: +1 (total: $count)');
    
    if (state.comments.isNotEmpty) {
      count += state.comments.length; // Comments
      print('   - Comments: +${state.comments.length} (total: $count)');
    } else {
      count += 1; // Empty state message
      print('   - Empty state: +1 (total: $count)');
    }
    
    if (state.hasMoreComments) {
      count += 1; // Loading indicator
      print('   - Loading indicator: +1 (total: $count)');
    }
    
    // Add related cases section if available
    if (state.discussion.relatedCases != null && state.discussion.relatedCases!.isNotEmpty) {
      count += 1; // Related cases header
      count += state.discussion.relatedCases!.length; // Related case items
      print('   - Related cases header: +1');
      print('   - Related cases: +${state.discussion.relatedCases!.length}');
      print('   - Final total: $count');
    }
    
    print('📊 Total item count: $count');
    return count;
  }

  Widget _buildListItem(BuildContext context, int index, DiscussionDetailLoaded state) {
    print('🏗️ Building item at index: $index');
    int currentIndex = 0;
    
    // Discussion header
    if (index == currentIndex) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: DiscussionHeader(
          discussion: state.discussion,
          onLike: () => _likeCase(state.discussion.id),
        ),
      );
    }
    currentIndex++;

    // Comments section header (always show)
    if (index == currentIndex) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.green[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Colors.green[800],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${state.comments.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.green[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    currentIndex++;

    // Comments or empty state
    print('💬 Checking comments section: index=$index, currentIndex=$currentIndex, comments.length=${state.comments.length}');
    if (state.comments.isNotEmpty) {
      print('✅ Comments are not empty, checking if index ($index) < currentIndex + comments.length (${currentIndex + state.comments.length})');
      // Show comments
      if (index < currentIndex + state.comments.length) {
        final commentIndex = index - currentIndex;
        print('🎯 Building comment at commentIndex: $commentIndex');
        final comment = state.comments[commentIndex];
        print('💬 Comment data: "${comment.comment}" by ${comment.author.name}');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                offset: const Offset(0, 1),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CommentCard(
            comment: comment,
            onLike: () => _likeComment(comment.id),
            onDelete: () => _deleteComment(comment.id),
          ),
        );
      }
      currentIndex += state.comments.length;
    } else {
      print('❌ Comments are empty, showing empty state');
      // Show empty state
      if (index == currentIndex) {
        print('🏗️ Building empty state at index: $index');
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Comments Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share your medical insights on this case.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      currentIndex++;
    }

    // Loading more comments indicator
    if (state.hasMoreComments && index == currentIndex) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more comments...',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      );
    }
    if (state.hasMoreComments) currentIndex++;

    // Related cases section
    if (state.discussion.relatedCases != null && state.discussion.relatedCases!.isNotEmpty) {
      if (index == currentIndex) {
        // Related cases header
        return _buildRelatedCasesHeader();
      }
      currentIndex++;

      // Related case items
      if (index < currentIndex + state.discussion.relatedCases!.length) {
        final relatedCaseIndex = index - currentIndex;
        final relatedCase = state.discussion.relatedCases![relatedCaseIndex];
        return _buildRelatedCaseItem(relatedCase);
      }
    }

    print('⚠️ WARNING: Returning SizedBox.shrink() for index $index - no widget built!');
    print('   - Final currentIndex: $currentIndex');
    print('   - Comments count: ${state.comments.length}');
    print('   - Related cases count: ${state.discussion.relatedCases?.length ?? 0}');
    print('   - Total expected items: ${_getItemCount(state)}');
    return const SizedBox.shrink();
  }

  Widget _buildRelatedCasesHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            color: Colors.blue[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Related Cases',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Colors.blue[800],
            ),
          ),
          const Spacer(),
          Text(
            '${discussionState?.discussion.relatedCases?.length ?? 0} cases',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedCaseItem(RelatedCase relatedCase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to related case detail
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DiscussionDetailScreen(caseId: relatedCase.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relatedCase.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                relatedCase.description,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags if available
              if (relatedCase.parsedTags != null && relatedCase.parsedTags!.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: relatedCase.parsedTags!.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Stats
              Row(
                children: [
                  Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    relatedCase.likes.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    relatedCase.views.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.blue[600]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DiscussionDetailLoaded? get discussionState {
    final state = context.read<DiscussionDetailBloc>().state;
    return state is DiscussionDetailLoaded ? state : null;
  }
}