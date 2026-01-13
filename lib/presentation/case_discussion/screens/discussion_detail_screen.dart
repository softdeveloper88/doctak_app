import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/discussion_detail_bloc.dart';
import '../models/case_discussion_models.dart';
import '../widgets/comment_card.dart';
import '../widgets/comment_input.dart';
import '../widgets/discussion_header.dart';
import '../widgets/case_discussion_shimmer.dart';
import '../../../localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';

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
    final theme = OneUITheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: BlocBuilder<DiscussionDetailBloc, DiscussionDetailState>(
          builder: (context, state) {
            final commentCount = state is DiscussionDetailLoaded ? state.comments.length : 0;
            return DoctakAppBar(
              title: translation(context).lbl_case_discussion,
              titleIcon: Icons.medical_information_rounded,
              actions: [
                if (commentCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble,
                          size: 12,
                          color: theme.buttonPrimaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          commentCount.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: theme.buttonPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        color: theme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        color: theme.primary,
                        size: 14,
                      ),
                    ),
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(translation(context).msg_share_functionality_coming_soon)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Container(
        color: theme.cardBackground,
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
                        color: theme.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: theme.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      translation(context).msg_error_loading_discussion,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: theme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: theme.textSecondary,
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
                        backgroundColor: theme.primary,
                        foregroundColor: theme.buttonPrimaryText,
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
                            translation(context).lbl_retry,
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
                      color: theme.primary,
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
                                color: theme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.success.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: theme.success,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    translation(context).lbl_comments,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      color: theme.success,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.success.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${state.comments.length}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        color: theme.success,
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
                                      color: theme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.border,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 48,
                                          color: theme.textTertiary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          translation(context).msg_no_comments_yet,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                            color: theme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          translation(context).msg_be_first_to_comment,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            color: theme.textTertiary,
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
                                  color: theme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      color: theme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      translation(context).lbl_related_cases,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                        color: theme.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${state.discussion.relatedCases!.length}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          color: theme.primary,
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
                                          color: theme.cardBackground,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.primary.withOpacity(0.1),
                                          ),
                                          boxShadow: theme.cardShadow,
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
                                                color: theme.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Description
                                            Text(
                                              relatedCase.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                                color: theme.textSecondary,
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
                                                      color: theme.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: theme.primary.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontFamily: 'Poppins',
                                                        color: theme.primary,
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
                                                Icon(Icons.thumb_up_outlined, size: 16, color: theme.textTertiary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  relatedCase.likes.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                    color: theme.textTertiary,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Icon(Icons.visibility_outlined, size: 16, color: theme.textTertiary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  relatedCase.views.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                    color: theme.textTertiary,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.primary),
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
                      color: theme.cardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: theme.divider,
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
        title: Text(translation(context).lbl_delete_comment),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(translation(context).lbl_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DiscussionDetailBloc>().add(DeleteComment(commentId));
            },
            child: Text(translation(context).lbl_delete),
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
    final theme = OneUITheme.of(context);
    
    // Discussion header
    if (index == currentIndex) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: theme.cardShadow,
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
          color: theme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.success.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: theme.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              translation(context).lbl_comments,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: theme.success,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${state.comments.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.success,
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
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: theme.cardShadow,
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
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: theme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                translation(context).msg_no_comments_yet,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                translation(context).msg_be_first_to_comment,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.textTertiary,
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
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              translation(context).msg_loading_more_comments,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: theme.primary,
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
        return _buildRelatedCasesHeader(theme);
      }
      currentIndex++;

      // Related case items
      if (index < currentIndex + state.discussion.relatedCases!.length) {
        final relatedCaseIndex = index - currentIndex;
        final relatedCase = state.discussion.relatedCases![relatedCaseIndex];
        return _buildRelatedCaseItem(relatedCase, theme);
      }
    }

    print('⚠️ WARNING: Returning SizedBox.shrink() for index $index - no widget built!');
    print('   - Final currentIndex: $currentIndex');
    print('   - Comments count: ${state.comments.length}');
    print('   - Related cases count: ${state.discussion.relatedCases?.length ?? 0}');
    print('   - Total expected items: ${_getItemCount(state)}');
    return const SizedBox.shrink();
  }

  Widget _buildRelatedCasesHeader(OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            color: theme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            translation(context).lbl_related_cases,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: theme.primary,
            ),
          ),
          const Spacer(),
          Text(
            '${discussionState?.discussion.relatedCases?.length ?? 0} cases',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: theme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedCaseItem(RelatedCase relatedCase, OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.cardShadow,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
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
                  color: theme.textSecondary,
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
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          color: theme.primary,
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
                  Icon(Icons.thumb_up_outlined, size: 16, color: theme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    relatedCase.likes.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: theme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 16, color: theme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    relatedCase.views.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: theme.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.primary),
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