import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/l10n/app_localizations.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart';
import 'package:nb_utils/nb_utils.dart';

import 'full_screen_image_widget.dart';
import 'post_media_widget.dart';
import 'profile_header_widget.dart';

class PostItemWidget extends StatefulWidget {
  final String profilePicUrl;
  final String userName;
  final String createdAt;
  final String? title;
  final String? backgroundColor;
  final dynamic image;
  final List<Media>? media;
  List<Likes>? likes;
  List<Comments>? comments;
  final int postId;
  final bool isLiked;
  final bool isCurrentUser;
  final bool isShowComment;
  final VoidCallback onProfileTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onToggleComment;
  final VoidCallback onViewLikesTap;
  final VoidCallback onViewCommentsTap;
  final Function(String value) onAddComment;
  dynamic postData;

  PostItemWidget({
    super.key,
    required this.profilePicUrl,
    required this.userName,
    required this.createdAt,
    this.title,
    this.backgroundColor,
    this.image,
    this.media,
    required this.postId,
    required this.isLiked,
    required this.isCurrentUser,
    required this.isShowComment,
    required this.onProfileTap,
    required this.onDeleteTap,
    required this.likes,
    required this.comments,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onToggleComment,
    required this.onViewLikesTap,
    required this.onViewCommentsTap,
    required this.onAddComment,
    required this.postData,
  });

  @override
  _PostItemWidgetState createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> {
  int _expandedIndex = -1;

  // Helper function to parse HTML to plain text
  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? htmlString;
  }

  // Helper function to check if string is HTML
  bool isHtml(String text) {
    return text.contains('<') && text.contains('>');
  }

  Widget _buildPlaceholderWithoutFile(context) {
    String fullText = widget.title ?? '';
    List<String> words = fullText.split(' ');
    bool isExpanded = _expandedIndex == widget.postId;
    String textToShow = isExpanded || words.length <= 25
        ? fullText
        : '${words.take(20).join(' ')}...';
    Color bgColor = PostUtils.HexColor(widget.backgroundColor ?? '#FFFFFF');

    Color textColor = PostUtils.contrastingTextColor(bgColor);
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(
          ClipboardData(text: parseHtmlString(widget.title ?? '')),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translation(context).lbl_text_copied)),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              (widget.image?.isNotEmpty == true ||
                  widget.media?.isNotEmpty == true)
              ? Colors.transparent
              : bgColor,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.image?.isNotEmpty == true ||
                  widget.media?.isNotEmpty == true)
                if (isHtml(textToShow))
                  Center(
                    child: HtmlWidget(
                      textStyle: const TextStyle(),
                      textToShow,
                      onTapUrl: (link) async {
                        if (link.contains('doctak/jobs-detail')) {
                          String jobID = Uri.parse(link).pathSegments.last;
                          JobsDetailsScreen(jobId: jobID).launch(context);
                        } else {
                          PostUtils.launchURL(context, link);
                        }
                        return true;
                      },
                    ),
                  )
                else
                  Linkify(
                    onOpen: (link) {
                      if (link.url.contains('doctak/jobs-detail')) {
                        String jobID = Uri.parse(link.url).pathSegments.last;
                        JobsDetailsScreen(jobId: jobID).launch(context);
                      } else {
                        PostUtils.launchURL(context, link.url);
                      }
                    },
                    text: textToShow,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: OneUITheme.of(context).textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    linkStyle: const TextStyle(color: Colors.blue),
                    textAlign: TextAlign.center,
                  )
              else if (isHtml(textToShow))
                Container(
                  constraints: BoxConstraints(
                    minHeight: textToShow.length < 25 ? 200 : 0,
                  ),
                  child: Center(
                    child: HtmlWidget(
                      textStyle: const TextStyle(),
                      enableCaching: true,
                      '<div style="text-align: center;">$textToShow</div>',
                      onTapUrl: (link) async {
                        if (link.contains('doctak/jobs-detail')) {
                          String jobID = Uri.parse(link).pathSegments.last;
                          JobsDetailsScreen(jobId: jobID).launch(context);
                        } else {
                          PostUtils.launchURL(context, link);
                        }
                        return true;
                      },
                    ),
                  ),
                )
              else
                Container(
                  constraints: BoxConstraints(
                    minHeight: textToShow.length < 25 ? 200 : 0,
                  ),
                  child: Center(
                    child: Linkify(
                      onOpen: (link) {
                        if (link.url.contains('doctak/jobs-detail')) {
                          String jobID = Uri.parse(link.url).pathSegments.last;
                          JobsDetailsScreen(jobId: jobID).launch(context);
                        } else {
                          PostUtils.launchURL(context, link.url);
                        }
                      },
                      text: textToShow,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      linkStyle: const TextStyle(color: Colors.blue),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              if (words.length > 25)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedIndex = isExpanded ? -1 : widget.postId;
                    });
                  },
                  child: Text(
                    isExpanded
                        ? translation(context).lbl_show_less
                        : translation(context).lbl_show_more,
                    style: TextStyle(
                      color: OneUITheme.of(context).primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    return PostMediaWidget(
      mediaList: widget.media ?? [],
      imageUrlBase: AppData.imageUrl,
      onImageTap: (url) {
        // Construct the full list of media URLs to enable the slider
        List<Map<String, String>> mediaUrls = [];
        if (widget.media != null) {
          for (var media in widget.media!) {
            // Skip invalid media paths
            final mediaPath = media.mediaPath;
            if (mediaPath == null || mediaPath.isEmpty || mediaPath == 'null') {
              continue;
            }
            // Ensure correct URL construction
            String fullUrl = mediaPath.startsWith('http')
                ? mediaPath
                : AppData.imageUrl + mediaPath;
            mediaUrls.add({"url": fullUrl, "type": media.mediaType ?? "image"});
          }
        }

        // Pass the full media list instead of an empty list
        showFullScreenImage(context, 1, url, widget.postData, mediaUrls);
      },
      onVideoTap: (url) {
        // Handle video tap
      },
      onExpandImageUrls: (mediaUrls) {
        showFullScreenImage(context, 2, '', widget.postData, mediaUrls);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.only(top: 12),
        margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
        decoration: theme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeaderWidget(
              profilePicUrl: widget.profilePicUrl,
              userName: widget.userName,
              createdAt: widget.createdAt,
              onProfileTap: () => widget.onProfileTap(),
              onDeleteTap: () => widget.onDeleteTap(),
              isCurrentUser: widget.isCurrentUser, // Adjust based on your logic
            ),
            _buildPlaceholderWithoutFile(context),
            // Media Content
            _buildMediaContent(context),
            InteractionRowWidget(
              isLiked: widget.isLiked,
              onLikeTap: widget.onLikeTap,
              onToggleComment: widget.onToggleComment,
              onShareTap: widget.onShareTap,
              onViewLikesTap: widget.onViewLikesTap,
              onViewCommentsTap: widget.onViewCommentsTap,
              likes: widget.likes?.length ?? 0,
              comments: widget.comments?.length ?? 0,
            ),
            // const Divider(color: Colors.grey, thickness: 0.2),
            //
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     InkWell(
            //       splashColor: Colors.transparent,
            //       highlightColor: Colors.transparent,
            //       onTap: widget.onLikeTap,
            //       child: Column(
            //         children: [
            //           widget.isLiked
            //               ? Image.asset(
            //                   'images/socialv/icons/ic_HeartFilled.png',
            //                   height: 20,
            //                   width: 22,
            //                   fit: BoxFit.fill,
            //                 )
            //               : Image.asset(
            //                   'images/socialv/icons/ic_Heart.png',
            //                   height: 22,
            //                   width: 22,
            //                   fit: BoxFit.cover,
            //                   color: context.iconColor,
            //                 ),
            //           Text(
            //             'Like',
            //             style: TextStyle(
            //
            //               color: Theme.of(context).textTheme.bodyMedium!.color,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //     InkWell(
            //       splashColor: Colors.grey,
            //       highlightColor: Colors.grey,
            //       onTap: widget.onToggleComment,
            //       child: Column(
            //         children: [
            //           Image.asset(
            //             'images/socialv/icons/ic_Chat.png',
            //             height: 22,
            //             width: 22,
            //             fit: BoxFit.cover,
            //             color: context.iconColor,
            //           ),
            //           Text(
            //             'Comment',
            //             style: TextStyle(
            //
            //               color: Theme.of(context).textTheme.bodyMedium!.color,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //     InkWell(
            //       splashColor: Colors.transparent,
            //       highlightColor: Colors.transparent,
            //       onTap: widget.onShareTap,
            //       child: Column(
            //         children: [
            //           const Icon(
            //             Icons.share_sharp,
            //             size: 22,
            //             color: Colors.grey,
            //           ),
            //           Text(
            //             'Share',
            //             style: TextStyle(
            //
            //               color: Theme.of(context).textTheme.bodyMedium!.color,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ).paddingSymmetric(horizontal: 16, vertical: 10),
            // Comments Section - Now handled by bottom sheet
          ],
        ),
      ),
    );
  }
}

class InteractionRowWidget extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onToggleComment;
  final VoidCallback onShareTap;
  final VoidCallback onViewLikesTap;
  final VoidCallback onViewCommentsTap;
  final int likes;
  final int comments;

  const InteractionRowWidget({
    super.key,
    required this.isLiked,
    required this.onLikeTap,
    required this.onToggleComment,
    required this.onShareTap,
    required this.onViewLikesTap,
    required this.onViewCommentsTap,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Column(
      children: [
        // Likes and Comments Count Row
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onViewLikesTap,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.heart_fill,
                      size: 14,
                      color: likes > 0 ? theme.likeColor : theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.lbl_likes_count(likes),
                      style: theme.bodySecondary,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onViewCommentsTap,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.chat_bubble_fill,
                      size: 14,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.lbl_comments_count(comments),
                      style: theme.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // One UI 8.5 Divider
        theme.buildDivider(indent: 12, endIndent: 12),
        // Action Buttons Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Like Button
              Expanded(
                child: theme.buildActionButton(
                  icon: isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  label: translation(context).lbl_like,
                  onTap: onLikeTap,
                  isActive: isLiked,
                  activeColor: theme.likeColor,
                ),
              ),
              // Vertical Divider
              theme.buildVerticalDivider(),
              // Comment Button
              Expanded(
                child: theme.buildActionButton(
                  icon: CupertinoIcons.chat_bubble,
                  label: translation(context).lbl_comment,
                  onTap: onToggleComment,
                ),
              ),
              // Vertical Divider
              theme.buildVerticalDivider(),
              // Send/Share Button
              Expanded(
                child: theme.buildActionButton(
                  icon: CupertinoIcons.paperplane,
                  label: translation(context).lbl_send,
                  onTap: onShareTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
