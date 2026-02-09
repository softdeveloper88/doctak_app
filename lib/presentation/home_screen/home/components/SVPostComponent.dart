import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/offline_retry_banner.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../fragments/home_main_screen/post_widget/find_likes.dart';
import '../../fragments/home_main_screen/post_widget/post_item_widget.dart';
import '../screens/comment_screen/SVCommentScreen.dart';
import '../screens/comment_screen/bloc/comment_bloc.dart';

class SVPostComponent extends StatefulWidget {
  const SVPostComponent(this.homeBloc, {this.isNestedScroll = true, super.key});

  final HomeBloc homeBloc;

  /// If true, uses shrinkWrap and NeverScrollableScrollPhysics for nested scroll contexts.
  /// If false, uses ClampingScrollPhysics for standalone scrolling.
  final bool isNestedScroll;

  @override
  State<SVPostComponent> createState() => _SVPostComponentState();
}

class _SVPostComponentState extends State<SVPostComponent>
    with WidgetsBindingObserver {
  int? isShowComment = -1;

  // Cache for time ago strings to avoid recalculation during scroll
  final Map<int, String> _timeAgoCache = {};

  // ScrollController for pagination detection
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (!widget.isNestedScroll) {
      _scrollController = ScrollController();
      _scrollController!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    super.dispose();
  }

  /// Handle scroll to trigger pagination when near bottom
  void _onScroll() {
    if (_scrollController == null) return;

    final maxScroll = _scrollController!.position.maxScrollExtent;
    final currentScroll = _scrollController!.offset;
    final threshold = 200.0; // pixels from bottom to trigger

    if (maxScroll - currentScroll <= threshold) {
      // Near bottom - check if we should load more
      if (widget.homeBloc.pageNumber <= widget.homeBloc.numberOfPage) {
        widget.homeBloc.add(
          PostCheckIfNeedMoreDataEvent(
            index:
                widget.homeBloc.postList.length -
                widget.homeBloc.nextPageTrigger,
          ),
        );
      }
    }
  }

  /// Shows the comment screen in a beautiful bottom sheet
  void _showCommentBottomSheet(BuildContext context, int postId) {
    final theme = OneUITheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Comment Screen
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SVCommentScreen(id: postId, homeBloc: widget.homeBloc),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: widget.homeBloc,
      // Only rebuild when necessary - not during pagination loading
      buildWhen: (previous, current) {
        // Always rebuild for these major state changes
        if (current is PostPaginationLoadingState ||
            current is PostsEmptyState ||
            current is PostDataError ||
            current is PostOfflineWithCacheState) {
          return true;
        }

        // For PostPaginationLoadedState, only rebuild if posts actually changed
        if (current is PostPaginationLoadedState) {
          // Don't rebuild just for pagination loading indicator
          if (previous is PostPaginationLoadedState &&
              current.isPaginationLoading != previous.isPaginationLoading) {
            // Only rebuild if switching to/from pagination loading
            return true;
          }
          // Rebuild if coming from a different state type
          if (previous is! PostPaginationLoadedState) {
            return true;
          }
          // Check if data actually changed (different post count)
          return true; // Always rebuild for loaded state to show new posts
        }

        return true;
      },
      builder: (context, state) {
        final theme = OneUITheme.of(context);
        if (state is PostPaginationLoadingState) {
          return const PostShimmerLoader(itemCount: 5);
        } else if (state is PostsEmptyState) {
          // Genuine empty state - no posts available
          return Container(
            color: theme.scaffoldBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primary.withValues(alpha: 0.15), theme.secondary.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.article_outlined, size: 48, color: theme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(translation(context).msg_no_posts, style: theme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Try adjusting your search criteria', style: theme.bodySecondary),
                ],
              ),
            ),
          );
        } else if (state is PostPaginationLoadedState ||
            state is PostOfflineWithCacheState) {
          // Show shimmer if still loading (empty list during first load - shouldn't happen now)
          if (widget.homeBloc.postList.isEmpty) {
            return const PostShimmerLoader(itemCount: 5);
          }

          // Build the posts list with optional offline banner
          return _buildPostsList(context, state);
        } else if (state is PostDataError) {
          return RetryWidget(
            errorMessage: state.errorMessage.isNotEmpty
                ? state.errorMessage
                : translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                widget.homeBloc.add(ManualRetryEvent());
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          );
        } else {
          return Center(child: Text(translation(context).lbl_search_post));
        }
      },
    );
  }

  /// Build the posts list with optional offline banner at the top
  Widget _buildPostsList(BuildContext context, HomeState state) {
    final isOffline = state is PostOfflineWithCacheState;
    final errorMessage = isOffline ? state.errorMessage : '';

    // Calculate if we need extra item for loading indicator
    final hasMorePages =
        widget.homeBloc.numberOfPage != widget.homeBloc.pageNumber - 1;
    final showExtraItem = isOffline || hasMorePages;

    // Build the ListView
    final listView = ListView.builder(
      key: const PageStorageKey<String>('posts_list'),
      controller: widget.isNestedScroll ? null : _scrollController,
      shrinkWrap: widget.isNestedScroll,
      scrollDirection: Axis.vertical,
      physics: widget.isNestedScroll
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      addAutomaticKeepAlives: false, // Disable for better memory management
      addRepaintBoundaries: true,
      cacheExtent: 800, // Reduced for better memory usage
      itemCount: widget.homeBloc.postList.length + (showExtraItem ? 1 : 0),
      itemBuilder: (context, index) {
        // First item: show offline banner if offline
        if (isOffline && index == 0) {
          return OfflineRetryBanner(
            message: errorMessage,
            onRetry: () {
              widget.homeBloc.add(ManualRetryEvent());
            },
            showAnimation: false,
          );
        }

        // Adjust index for offline banner
        final adjustedIndex = isOffline ? index - 1 : index;

        // Show loading indicator for pagination (lightweight, doesn't block UI)
        if (!isOffline && adjustedIndex >= widget.homeBloc.postList.length) {
          // Use a lightweight loading indicator instead of heavy shimmer
          return const PostShimmerLoader(itemCount: 1);
        }

        // Safety check for index
        if (adjustedIndex < 0 ||
            adjustedIndex >= widget.homeBloc.postList.length) {
          return const SizedBox.shrink();
        }

        // Insert ad widgets after every 8 posts
        if ((adjustedIndex % 8 == 0 && adjustedIndex != 0) &&
            AppData.isShowGoogleNativeAds) {
          return NativeAdWidget();
        }

        // Fetch post data
        final post = widget.homeBloc.postList[adjustedIndex];

        // Build post item widget with RepaintBoundary for isolation
        return RepaintBoundary(
          child: _buildPostItem(context, post, adjustedIndex),
        );
      },
    );

    return listView;
  }

  /// Build individual post item - extracted for cleaner code and potential memoization
  Widget _buildPostItem(BuildContext context, Post post, int index) {
    // Cache time ago calculation
    final postId = post.id ?? 0;
    final createdAtString = post.createdAt;
    String timeAgoStr;

    if (createdAtString != null) {
      // Use cached value if available and not too old
      if (_timeAgoCache.containsKey(postId)) {
        timeAgoStr = _timeAgoCache[postId]!;
      } else {
        timeAgoStr = timeAgo.format(DateTime.parse(createdAtString));
        _timeAgoCache[postId] = timeAgoStr;

        // Limit cache size
        if (_timeAgoCache.length > 100) {
          _timeAgoCache.remove(_timeAgoCache.keys.first);
        }
      }
    } else {
      timeAgoStr = '';
    }

    return PostItemWidget(
      postData: post,
      profilePicUrl: '${AppData.imageUrl}${post.user?.profilePic}',
      userName: post.user?.name ?? '',
      createdAt: timeAgoStr,
      title: post.title,
      backgroundColor: post.backgroundColor,
      image: post.image,
      media: post.media,
      likes: post.likes,
      comments: post.comments,
      postId: postId,
      isLiked: findIsLiked(post.likes),
      isCurrentUser: post.userId == AppData.logInUserId,
      isShowComment: isShowComment == index,
      onProfileTap: () {
        SVProfileFragment(userId: post.user?.id).launch(context);
      },
      onDeleteTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return CustomAlertDialog(
              title: translation(context).msg_confirm_delete_post,
              callback: () {
                widget.homeBloc.add(DeletePostEvent(postId: post.id));
              },
            );
          },
        );
      },
      onLikeTap: () {
        widget.homeBloc.add(PostLikeEvent(postId: post.id));
      },
      onViewLikesTap: () {
        LikesListScreen(id: post.id.toString()).launch(context);
      },
      onViewCommentsTap: () {
        SVCommentScreen(
          homeBloc: widget.homeBloc,
          id: post.id ?? 0,
        ).launch(context);
      },
      onShareTap: () {
        DeepLinkService.sharePost(postId: post.id ?? 0, title: post.title);
      },
      onAddComment: (value) {
        CommentBloc().add(
          PostCommentEvent(postId: post.id ?? 0, comment: value),
        );
        setState(() {
          post.comments?.add(Comments());
          isShowComment = -1;
        });
      },
      onToggleComment: () {
        _showCommentBottomSheet(context, post.id ?? 0);
      },
      onCommentTap: () {
        _showCommentBottomSheet(context, post.id ?? 0);
      },
    );
  }

  /**
    // Widget _buildPlaceholderWithoutFile(
    //     context, title, backgroundColor, image, media, int index) {
    //   String fullText = title ?? '';
    //   List<String> words = fullText.split(' ');
    //   bool isExpanded = _expandedIndex == index;
    //   String textToShow = isExpanded || words.length <= 25
    //       ? fullText
    //       : '${words.take(20).join(' ')}...';
    //
    //   Color bgColor = PostUtils.HexColor(backgroundColor);
    //
    //   Color textColor = PostUtils.contrastingTextColor(bgColor);
    //   return LayoutBuilder(
    //     builder: (context, constraints) {
    //       return GestureDetector(
    //         onLongPress: () {
    //           Clipboard.setData(ClipboardData(text: parseHtmlString(title)));
    //           ScaffoldMessenger.of(context).showSnackBar(
    //             const SnackBar(content: Text("Text copied to clipboard")),
    //           );
    //         },
    //         child: DecoratedBox(
    //           decoration: BoxDecoration(
    //             color: (image?.isNotEmpty == true || media?.isNotEmpty == true)
    //                 ? Colors.transparent
    //                 : bgColor,
    //             borderRadius: BorderRadius.circular(5.0),
    //           ),
    //           child: Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: Column(
    //               mainAxisAlignment: MainAxisAlignment.center,
    //               crossAxisAlignment: CrossAxisAlignment.stretch,
    //               children: [
    //                 if (image?.isNotEmpty == true || media?.isNotEmpty == true)
    //                   if (isHtml(textToShow))
    //                     Center(
    //                       child: HtmlWidget(textStyle: const TextStyle(fontFamily: 'Poppins',), textToShow, onTapUrl: (link) async {
    //                         print('link $link');
    //                         if (link.contains('doctak/jobs-detail')) {
    //                           String jobID = Uri.parse(link).pathSegments.last;
    //                           JobsDetailsScreen(
    //                             jobId: jobID,
    //                           ).launch(context);
    //                         } else {
    //                           PostUtils.launchURL(context, link);
    //                         }
    //                         return true;
    //                       }),
    //                     )
    //                   else
    //                     Linkify(
    //
    //                       onOpen: (link) {
    //                         if (link.url.contains('doctak/jobs-detail')) {
    //                           String jobID =
    //                               Uri.parse(link.url).pathSegments.last;
    //                           JobsDetailsScreen(
    //                             jobId: jobID,
    //                           ).launch(context);
    //                         } else {
    //                           PostUtils.launchURL(context, link.url);
    //                         }
    //                       },
    //                       text: textToShow,
    //                       style: TextStyle(
    //                         fontFamily: 'Poppins',
    //                         fontSize: 14.0,
    //                         color: (image?.isNotEmpty == true ||
    //                                 media?.isNotEmpty == true)
    //                             ? svGetBodyColor()
    //                             : svGetBodyColor(),
    //                         fontWeight: FontWeight.bold,
    //                       ),
    //                       linkStyle: const TextStyle(
    //                         color: Colors.blue,
    //                       ),
    //                       textAlign: TextAlign.center,
    //                     )
    //                 else if (isHtml(textToShow))
    //                   Container(
    //                     constraints: BoxConstraints(
    //                         minHeight: textToShow.length < 25 ? 200 : 0),
    //                     child: Center(
    //                       child: HtmlWidget(
    //                         textStyle: const TextStyle(fontFamily: 'Poppins',),
    //                         enableCaching: true,
    //                         '<div style="text-align: center;">$textToShow</div>',
    //                         onTapUrl: (link) async {
    //                           print(link);
    //                           if (link.contains('doctak/jobs-detail')) {
    //                             String jobID = Uri.parse(link).pathSegments.last;
    //                             JobsDetailsScreen(
    //                               jobId: jobID,
    //                             ).launch(context);
    //                           } else {
    //                             PostUtils.launchURL(context, link);
    //                           }
    //                           return true;
    //                         },
    //                       ),
    //                     ),
    //                   )
    //                 else
    //                   Container(
    //                     constraints: BoxConstraints(
    //                         minHeight: textToShow.length < 25 ? 200 : 0),
    //                     child: Center(
    //                       child: Linkify(
    //                         onOpen: (link) {
    //                           if (link.url.contains('doctak/jobs-detail')) {
    //                             String jobID =
    //                                 Uri.parse(link.url).pathSegments.last;
    //                             JobsDetailsScreen(
    //                               jobId: jobID,
    //                             ).launch(context);
    //                           } else {
    //                             PostUtils.launchURL(context, link.url);
    //                           }
    //                         },
    //                         text: textToShow,
    //                         style: TextStyle(
    //                           fontFamily: 'Poppins',
    //                           fontSize: 14.0,
    //                           color: textColor,
    //                           fontWeight: FontWeight.bold,
    //                         ),
    //                         linkStyle: const TextStyle(
    //                           color: Colors.blue,
    //                         ),
    //                         textAlign: TextAlign.left,
    //                       ),
    //                     ),
    //                   ),
    //                 if (words.length > 25)
    //                   TextButton(
    //                     onPressed: () => setState(() {
    //                       if (isExpanded) {
    //                         _expandedIndex = -1; // Collapse if already expanded
    //                       } else {
    //                         _expandedIndex = index; // Expand the clicked item
    //                       }
    //                     }),
    //                     child: Text(
    //                       isExpanded ? 'Show Less' : 'Show More',
    //                       style: TextStyle(
    //                         fontFamily: 'Poppins',
    //                         color: svGetBodyColor(),
    //                         shadows: const [
    //                           Shadow(
    //                             offset: Offset(1.0, 1.0),
    //                             blurRadius: 3.0,
    //                             color: Color.fromARGB(255, 0, 0, 0),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                   ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       );
    //     },
    //   );
    // }
    //
    //
    //
    // Widget _buildMediaContent(context, index) {
    //   return PostMediaWidget(
    //       mediaList: widget.homeBloc.postList[index].media ?? [],
    //       imageUrlBase: AppData.imageUrl,
    //       onImageTap: (url) {
    //         showFullScreenImage(
    //           context,
    //           1,
    //           url,
    //           widget.homeBloc.postList[index],
    //           [],
    //         );
    //       },
    //       onVideoTap: (url) {
    //         // Handle video tap
    //       },
    //       onExpandImageUrls: (mediaUrls) {
    //         showFullScreenImage(
    //           context,
    //           2,
    //           '',
    //           widget.homeBloc.postList[index],
    //           mediaUrls,
    //         );
    //       });
    // }
    //
    // int _expandedIndex = -1;
 **/
}
