import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/post_comman_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../home/components/SVCommentReplyComponent.dart';
import 'full_screen_image_widget.dart';

// import 'post_utils.dart'; // Import your PostUtils or helper methods
import 'post_media_widget.dart'; // Import your PostMediaWidget
// import 'jobs_details_screen.dart'; // Import your JobsDetailsScreen

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
    Key? key,
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
  }) : super(key: key);

  @override
  _PostItemWidgetState createState() => _PostItemWidgetState();
}

class _PostItemWidgetState extends State<PostItemWidget> {
  int _expandedIndex = -1;

  Widget _buildPlaceholderWithoutFile(context) {
    String fullText = widget.title ?? '';
    List<String> words = fullText.split(' ');
    bool isExpanded = _expandedIndex == widget.postId;
    String textToShow = isExpanded || words.length <= 25
        ? fullText
        : '${words.take(20).join(' ')}...';
    Color bgColor = PostUtils.HexColor(widget.backgroundColor ?? '#FFFFFF');

    Color textColor = PostUtils.contrastingTextColor(bgColor);
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onLongPress: () {
            Clipboard.setData(
                ClipboardData(text: parseHtmlString(widget.title??'')));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Text copied to clipboard")),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (widget.image?.isNotEmpty == true ||
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
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                            ),
                            textToShow, onTapUrl: (link) async {
                          print('link $link');
                          if (link.contains('doctak/jobs-detail')) {
                            String jobID = Uri.parse(link).pathSegments.last;
                            JobsDetailsScreen(
                              jobId: jobID,
                            ).launch(context);
                          } else {
                            PostUtils.launchURL(context, link);
                          }
                          return true;
                        }),
                      )
                    else
                      Linkify(
                        onOpen: (link) {
                          if (link.url.contains('doctak/jobs-detail')) {
                            String jobID =
                                Uri.parse(link.url).pathSegments.last;
                            JobsDetailsScreen(
                              jobId: jobID,
                            ).launch(context);
                          } else {
                            PostUtils.launchURL(context, link.url);
                          }
                        },
                        text: textToShow,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.0,
                          color: (widget.image?.isNotEmpty == true ||
                                  widget.media?.isNotEmpty == true)
                              ? svGetBodyColor()
                              : svGetBodyColor(),
                          fontWeight: FontWeight.bold,
                        ),
                        linkStyle: const TextStyle(
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      )
                  else if (isHtml(textToShow))
                    Container(
                      constraints: BoxConstraints(
                          minHeight: textToShow.length < 25 ? 200 : 0),
                      child: Center(
                        child: HtmlWidget(
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                          ),
                          enableCaching: true,
                          '<div style="text-align: center;">$textToShow</div>',
                          onTapUrl: (link) async {
                            print(link);
                            if (link.contains('doctak/jobs-detail')) {
                              String jobID = Uri.parse(link).pathSegments.last;
                              JobsDetailsScreen(
                                jobId: jobID,
                              ).launch(context);
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
                          minHeight: textToShow.length < 25 ? 200 : 0),
                      child: Center(
                        child: Linkify(
                          onOpen: (link) {
                            if (link.url.contains('doctak/jobs-detail')) {
                              String jobID =
                                  Uri.parse(link.url).pathSegments.last;
                              JobsDetailsScreen(
                                jobId: jobID,
                              ).launch(context);
                            } else {
                              PostUtils.launchURL(context, link.url);
                            }
                          },
                          text: textToShow,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.0,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          linkStyle: const TextStyle(
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  if (words.length > 25)
                    TextButton(
                      // onPressed: () => setState(() {
                      //   if (isExpanded) {
                      //     _expandedIndex = -1; // Collapse if already expanded
                      //   } else {
                      //     _expandedIndex = index; // Expand the clicked item
                      //   }
                      onPressed: () {
                        setState(() {
                          _expandedIndex = isExpanded ? -1 : widget.postId;
                        });
                      },
                      child: Text(
                        isExpanded ? 'Show Less' : 'Show More',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: svGetBodyColor(),
                          shadows: const [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildMediaContent(BuildContext context) {
    return PostMediaWidget(
      mediaList: widget.media ?? [],
      imageUrlBase: AppData.imageUrl,
      onImageTap: (url) {
        showFullScreenImage(
          context,
          1,
          url,
          widget.postData,
          [],
        );
      },
      onVideoTap: (url) {
        // Handle video tap
      },
      onExpandImageUrls: (mediaUrls) {
        showFullScreenImage(
          context,
          2,
          '',
          widget.postData,
          mediaUrls,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeaderWidget(
            profilePicUrl: widget.profilePicUrl,
            userName: widget.userName,
            createdAt: widget.createdAt,
            onProfileTap: ()=>widget.onProfileTap(),
            onDeleteTap:()=>widget.onDeleteTap(),
            isCurrentUser:widget.isCurrentUser, // Adjust based on your logic
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Expanded(
          //       child: InkWell(
          //         onTap: widget.onProfileTap,
          //         child: Row(
          //           children: [
          //             CircleAvatar(
          //               backgroundImage: NetworkImage(widget.profilePicUrl),
          //               radius: 25,
          //             ),
          //             const SizedBox(width: 12),
          //             Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 Row(
          //                   children: [
          //                     Text(
          //                       widget.userName,
          //                       style: const TextStyle(
          //                         fontWeight: FontWeight.bold,
          //                         fontFamily: 'Poppins',
          //                       ),
          //                     ),
          //                     const SizedBox(width: 8),
          //                     Image.asset(
          //                       'images/socialv/icons/ic_TickSquare.png',
          //                       height: 14,
          //                       width: 14,
          //                       fit: BoxFit.cover,
          //                     ),
          //                   ],
          //                 ),
          //                 Row(
          //                   children: [
          //                     Text(
          //                       widget.createdAt,
          //                       style: const TextStyle(
          //                         fontSize: 12,
          //                         color: Colors.grey,
          //                         fontFamily: 'Poppins',
          //                       ),
          //                     ),
          //                     const SizedBox(width: 8),
          //                     const Icon(Icons.access_time, size: 16),
          //                   ],
          //                 ),
          //               ],
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //     if (widget.isCurrentUser)
          //       PopupMenuButton<String>(
          //         itemBuilder: (context) => [
          //           const PopupMenuItem(value: 'Delete', child: Text('Delete')),
          //         ],
          //         onSelected: (value) {
          //           if (value == 'Delete') {
          //             widget.onDeleteTap();
          //           }
          //         },
          //       ),
          //   ],
          // ),
          // const SizedBox(height: 16),
          // Placeholder Content
          _buildPlaceholderWithoutFile(context),
          // Media Content
          _buildMediaContent(context),
          //           // Likes and Comments Row
          // Padding(
          //   padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       GestureDetector(
          //         onTap: widget.onViewLikesTap,
          //         child: Text(
          //           '${widget.likes?.length ?? 0} Likes',
          //           style: TextStyle(
          //             fontFamily: 'Poppins',
          //             color: Theme.of(context).textTheme.bodyMedium!.color,
          //           ),
          //         ),
          //       ),
          //       InkWell(
          //         onTap: widget.onViewCommentsTap,
          //         child: Text(
          //           '${widget.comments?.length ?? 0} Comments',
          //           style: TextStyle(
          //             fontFamily: 'Poppins',
          //             color: Theme.of(context).textTheme.bodyMedium!.color,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // Divider and Action Buttons
          InteractionRowWidget(isLiked:widget.isLiked,onLikeTap:widget.onLikeTap,onToggleComment:widget.onToggleComment, onShareTap: widget.onShareTap,onViewLikesTap: widget.onViewLikesTap,onViewCommentsTap: widget.onViewCommentsTap,likes: widget.likes?.length??0,comments: widget.comments?.length??0,),
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
          //               fontFamily: 'Poppins',
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
          //               fontFamily: 'Poppins',
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
          //               fontFamily: 'Poppins',
          //               color: Theme.of(context).textTheme.bodyMedium!.color,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ).paddingSymmetric(horizontal: 16, vertical: 10),
          // Comments Section
          if (widget.isShowComment)
            SVCommentReplyComponent(
              CommentBloc(),
              widget.postId,
              (value) {
                if (value.isNotEmpty) {
                  widget.onAddComment(value);
                }
              },
            ),
        ],
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
    Key? key,
    required this.isLiked,
    required this.onLikeTap,
    required this.onToggleComment,
    required this.onShareTap,
    required this.onViewLikesTap,
    required this.onViewCommentsTap,
    required this.likes,
    required this.comments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onViewLikesTap,
                child: Text(
                  '${likes ?? 0} Likes',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
              InkWell(
                onTap: onViewCommentsTap,
                child: Text(
                  '${comments ?? 0} Comments',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.grey, thickness: 0.2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onLikeTap,
              child: Column(
                children: [
                  isLiked
                      ? Image.asset(
                    'images/socialv/icons/ic_HeartFilled.png',
                    height: 20,
                    width: 22,
                    fit: BoxFit.fill,
                  )
                      : Image.asset(
                    'images/socialv/icons/ic_Heart.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.cover,
                    color: context.iconColor,
                  ),
                  Text(
                    'Like',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              splashColor: Colors.grey,
              highlightColor: Colors.grey,
              onTap: onToggleComment,
              child: Column(
                children: [
                  Image.asset(
                    'images/socialv/icons/ic_Chat.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.cover,
                    color: context.iconColor,
                  ),
                  Text(
                    'Comment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onShareTap,
              child: Column(
                children: [
                  Icon(
                    Icons.share,
                    size: 22,
                    color: context.iconColor,
                  ),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).paddingSymmetric(horizontal: 16, vertical: 10),
      ],
    );
  }
}
class ProfileHeaderWidget extends StatelessWidget {
  final String profilePicUrl;
  final String userName;
  final String createdAt;
  final VoidCallback onProfileTap;
  final VoidCallback onDeleteTap;
  final bool isCurrentUser;

  const ProfileHeaderWidget({
    Key? key,
    required this.profilePicUrl,
    required this.userName,
    required this.createdAt,
    required this.onProfileTap,
    required this.onDeleteTap,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InkWell(
                onTap: onProfileTap,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(profilePicUrl),
                      radius: 25,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'images/socialv/icons/ic_TickSquare.png',
                              height: 14,
                              width: 14,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              createdAt,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentUser)
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'Delete') {
                    onDeleteTap();
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

