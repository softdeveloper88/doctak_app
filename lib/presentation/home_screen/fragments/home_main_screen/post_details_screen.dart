import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/post_item_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentReplyComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/sv_comment_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/home_bloc.dart';
import 'post_widget/find_likes.dart';

class PostDetailsScreen extends StatefulWidget {
  final int? postId;
  final int? commentId;

  const PostDetailsScreen({this.postId, this.commentId, super.key});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  HomeBloc homeBloc = HomeBloc();

  @override
  void initState() {
    super.initState();
    if (widget.commentId != null) {
      homeBloc.add(
        DetailsPostEvent(commentId: widget.commentId ?? 0, postId: 0),
      );
    } else {
      homeBloc.add(DetailsPostEvent(postId: widget.postId ?? 0, commentId: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      resizeToAvoidBottomInset: true,
      appBar: DoctakAppBar(
        title: 'Post Detail',
        titleIcon: Icons.article_outlined,
      ),
      body: BlocConsumer<HomeBloc, HomeState>(
        bloc: homeBloc,
        listener: (BuildContext context, HomeState state) {
          if (state is PostDataError) {
            // Handle error if needed
          }
        },
        builder: (context, state) {
          if (state is PostPaginationLoadingState) {
            return const PostShimmerLoader(itemCount: 1);
          } else if (state is PostPaginationLoadedState) {
            final post = homeBloc.postData?.post;
            if (post == null) {
              return RetryWidget(
                errorMessage: "Post not found",
                onRetry: () {
                  homeBloc.add(DetailsPostEvent(postId: widget.postId));
                },
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Reuse PostItemWidget to avoid code duplication
                  PostItemWidget(
                    profilePicUrl:
                        "${AppData.imageUrl}${post.user?.profilePic ?? ''}",
                    userName: post.user?.name ?? '',
                    createdAt: post.createdAt ?? '',
                    title: post.title,
                    backgroundColor: post.backgroundColor,
                    image: post.image,
                    media: post.media,
                    postId: post.id ?? 0,
                    isLiked: findIsLiked(post.likes),
                    isCurrentUser: post.userId == AppData.logInUserId,
                    isShowComment: false,
                    likes: post.likes,
                    comments: post.comments,
                    postData: homeBloc.postData,
                    onProfileTap: () {
                      SVProfileFragment(userId: post.user?.id).launch(context);
                    },
                    onDeleteTap: () {
                      _showDeleteDialog(context, post.id ?? 0);
                    },
                    onLikeTap: () {
                      homeBloc.add(PostLikeEvent(postId: post.id ?? 0));
                    },
                    onCommentTap: () {
                      SVCommentScreen(
                        homeBloc: homeBloc,
                        id: post.id ?? 0,
                      ).launch(context);
                    },
                    onShareTap: () {
                      DeepLinkService.sharePost(
                        postId: post.id ?? 0,
                        title: post.title,
                      );
                    },
                    onToggleComment: () {
                      SVCommentScreen(
                        homeBloc: homeBloc,
                        id: post.id ?? 0,
                      ).launch(context);
                    },
                    onViewLikesTap: () {
                      LikesListScreen(
                        id: post.id?.toString() ?? '0',
                      ).launch(context);
                    },
                    onViewCommentsTap: () {
                      SVCommentScreen(
                        homeBloc: homeBloc,
                        id: post.id ?? 0,
                      ).launch(context);
                    },
                    onAddComment: (value) {
                      if (value.isNotEmpty) {
                        var commentBloc = CommentBloc();
                        commentBloc.add(
                          PostCommentEvent(
                            postId: post.id ?? 0,
                            comment: value,
                          ),
                        );
                        post.comments?.add(Comments());
                        setState(() {});
                      }
                    },
                  ),

                  // Specific Comment Section (when navigating from a comment notification)
                  if (widget.commentId != null &&
                      homeBloc.postData?.specificComment != null)
                    _buildSpecificCommentSection(context, theme),

                  // Comment Reply Component
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SVCommentReplyComponent(
                      CommentBloc(),
                      post.id ?? 0,
                      (value) {
                        if (value.isNotEmpty) {
                          var commentBloc = CommentBloc();
                          commentBloc.add(
                            PostCommentEvent(
                              postId: post.id ?? 0,
                              comment: value,
                            ),
                          );
                          post.comments?.add(Comments());
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return RetryWidget(
              errorMessage: "Something went wrong please try again",
              onRetry: () {
                homeBloc.add(DetailsPostEvent(postId: widget.postId));
              },
            );
          }
        },
      ),
    );
  }

  /// Builds the specific comment section when navigating from a notification
  Widget _buildSpecificCommentSection(BuildContext context, OneUITheme theme) {
    final specificComment = homeBloc.postData?.specificComment;
    if (specificComment == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.surfaceVariant,
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Header
          GestureDetector(
            onTap: () {
              SVProfileFragment(userId: specificComment.userId).launch(context);
            },
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      '${AppData.imageUrl}${specificComment.commenterProfilePic ?? ''}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              specificComment.commenterName ?? 'No Name',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.verified, size: 14, color: theme.primary),
                        ],
                      ),
                      Text(
                        timeAgo.format(
                          DateTime.parse(specificComment.createdAt ?? ""),
                        ),
                        style: TextStyle(
                          color: theme.textTertiary,
                          fontFamily: 'Poppins',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Comment Text
          Text(
            specificComment.comment ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: theme.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // More Comments Button
          Center(
            child: TextButton.icon(
              onPressed: () {
                SVCommentScreen(
                  id: homeBloc.postData?.post?.id?.toInt() ?? 0,
                  homeBloc: HomeBloc(),
                ).launch(context);
              },
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 16,
                color: theme.primary,
              ),
              label: Text(
                "View All Comments",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the delete confirmation dialog
  void _showDeleteDialog(BuildContext context, int postId) {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                "Delete Post",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this post? This action cannot be undone.",
            style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: theme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                homeBloc.add(DeletePostEvent(postId: postId));
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Post deleted successfully'),
                    backgroundColor: theme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );

                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: theme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
