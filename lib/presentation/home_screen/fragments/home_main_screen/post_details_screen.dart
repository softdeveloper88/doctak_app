import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/adapters/post_feed_adapter.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_cards.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/sv_comment_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/home_bloc.dart';

class PostDetailsScreen extends StatefulWidget {
  final int? postId;
  final int? commentId;

  const PostDetailsScreen({this.postId, this.commentId, super.key});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final HomeBloc homeBloc = HomeBloc();

  @override
  void initState() {
    super.initState();
    if (widget.commentId != null) {
      homeBloc.add(DetailsPostEvent(commentId: widget.commentId ?? 0, postId: 0));
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
      appBar: DoctakAppBar(title: 'Post Detail', titleIcon: Icons.article_outlined),
      body: BlocConsumer<HomeBloc, HomeState>(
        bloc: homeBloc,
        listener: (BuildContext context, HomeState state) {},
        builder: (context, state) {
          if (state is PostPaginationLoadingState) {
            return const PostShimmerLoader(itemCount: 1);
          }
          if (state is PostPaginationLoadedState) {
            final post = homeBloc.postData?.post;
            if (post == null) {
              return RetryWidget(
                errorMessage: 'Post not found',
                onRetry: () {
                  homeBloc.add(DetailsPostEvent(postId: widget.postId));
                },
              );
            }

            final postId = post.id ?? 0;

            return SingleChildScrollView(
              child: Column(
                children: [
                  FeedPostCard(
                    PostFeedAdapter.fromPost(post),
                    options: FeedPostCardOptions(
                      onProfileTap: () =>
                          ProfileNavigation.openFromPost(context, post),
                      homeBloc: homeBloc,
                      postIdForComments: postId,
                      onFeedChanged: () {
                        if (mounted) Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                  if (widget.commentId != null &&
                      homeBloc.postData?.specificComment != null)
                    _buildSpecificCommentSection(context, theme),
                ],
              ),
            );
          }

          return RetryWidget(
            errorMessage: 'Something went wrong please try again',
            onRetry: () {
              homeBloc.add(DetailsPostEvent(postId: widget.postId));
            },
          );
        },
      ),
    );
  }

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
          GestureDetector(
            onTap: () {
              ProfileNavigation.openUser(
                context,
                specificComment.userId,
              );
            },
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      AppData.fullImageUrl(specificComment.commenterProfilePic),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        timeAgo.format(DateTime.parse(specificComment.createdAt ?? '')),
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
          Text(
            specificComment.comment ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: theme.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                SVCommentScreen(
                  id: homeBloc.postData?.post?.id?.toInt() ?? 0,
                  homeBloc: HomeBloc(),
                ).launch(context);
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: theme.primary),
              label: Text(
                'View All Comments',
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
}
