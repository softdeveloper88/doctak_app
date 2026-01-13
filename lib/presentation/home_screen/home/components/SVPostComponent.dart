import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                color: Colors.black.withOpacity(0.15),
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
      builder: (context, state) {
        if (state is PostPaginationLoadingState) {
          return const PostShimmerLoader(itemCount: 5);
          // return const Center(child: CircularProgressIndicator(color: svGetBodyColor(),));
        } else if (state is PostPaginationLoadedState) {
          return widget.homeBloc.postList.isEmpty
              ? Center(child: Text(translation(context).msg_no_posts))
              : ListView.builder(
                  key: const PageStorageKey<String>('posts_list'),
                  shrinkWrap: widget.isNestedScroll,
                  scrollDirection: Axis.vertical,
                  physics: widget.isNestedScroll
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  cacheExtent: 1000,
                  itemCount:
                      widget.homeBloc.postList.length +
                      (widget.homeBloc.numberOfPage !=
                              widget.homeBloc.pageNumber - 1
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    // Trigger data fetching when reaching nextPageTrigger
                    if (index ==
                            widget.homeBloc.postList.length -
                                widget.homeBloc.nextPageTrigger &&
                        widget.homeBloc.pageNumber <=
                            widget.homeBloc.numberOfPage) {
                      widget.homeBloc.add(
                        PostCheckIfNeedMoreDataEvent(index: index),
                      );
                    }

                    // Show shimmer loader for pagination
                    if (index >= widget.homeBloc.postList.length) {
                      return const PostShimmerLoader(itemCount: 3);
                    }

                    // Insert ad widgets after every 5 posts
                    if ((index % 8 == 0 && index != 0) &&
                        AppData.isShowGoogleNativeAds) {
                      return NativeAdWidget();
                    }

                    // Fetch post data
                    final post = widget.homeBloc.postList[index];

                    // Build post item widget
                    return RepaintBoundary(
                      child: PostItemWidget(
                        postData: post,
                        profilePicUrl:
                            '${AppData.imageUrl}${post.user?.profilePic}',
                        userName: post.user?.name ?? '',
                        createdAt: timeAgo.format(
                          DateTime.parse(post.createdAt!),
                        ),
                        title: post.title,
                        backgroundColor: post.backgroundColor,
                        image: post.image,
                        media: post.media,
                        likes: post.likes,
                        comments: post.comments,
                        postId: post.id ?? 0,
                        isLiked: findIsLiked(post.likes),
                        isCurrentUser: post.userId == AppData.logInUserId,
                        isShowComment: isShowComment == index,
                        onProfileTap: () {
                          SVProfileFragment(
                            userId: post.user?.id,
                          ).launch(context);
                        },
                        onDeleteTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return CustomAlertDialog(
                                title: translation(
                                  context,
                                ).msg_confirm_delete_post,
                                callback: () {
                                  widget.homeBloc.add(
                                    DeletePostEvent(postId: post.id),
                                  );
                                  // Dialog is already closed by CustomAlertDialog
                                },
                              );
                            },
                          );
                        },
                        onLikeTap: () {
                          widget.homeBloc.add(PostLikeEvent(postId: post.id));
                        },
                        onViewLikesTap: () {
                          LikesListScreen(
                            id: post.id.toString(),
                          ).launch(context);
                        },
                        onViewCommentsTap: () {
                          SVCommentScreen(
                            homeBloc: widget.homeBloc,
                            id: post.id ?? 0,
                          ).launch(context);
                        },
                        onShareTap: () {
                          // Share functionality can be added here
                        },
                        onAddComment: (value) {
                          CommentBloc().add(
                            PostCommentEvent(
                              postId: post.id ?? 0,
                              comment: value,
                            ),
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
                      ),
                    );
                  },
                );
        } else if (state is PostDataError) {
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                widget.homeBloc.add(PostLoadPageEvent(page: 1));
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
