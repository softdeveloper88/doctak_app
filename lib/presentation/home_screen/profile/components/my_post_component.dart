import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/full_screen_image_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/post_media_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/text_icon_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentReplyComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/SVCommentScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart'
    as comment_bloc;
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/post_model/post_data_model.dart';
import '../../fragments/home_main_screen/post_widget/find_likes.dart';

class MyPostComponent extends StatefulWidget {
  MyPostComponent(this.profileBloc, {super.key});

  ProfileBloc profileBloc;

  @override
  State<MyPostComponent> createState() => _MyPostComponentState();
}

class _MyPostComponentState extends State<MyPostComponent> {
  HomeBloc homeBloc = HomeBloc();
  int isShowComment = -1;

  showAlertDialog(ProfileBloc profileBloc, BuildContext context, int id) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text(
        "Cancel",
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () {
        setState(() {
          Navigator.of(context).pop('dismiss');
        });
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Yes", style: TextStyle(color: Colors.black)),
      onPressed: () async {
        homeBloc.add(DeletePostEvent(postId: id));
        profileBloc.postList.removeWhere((post) => post.id == id);
        setState(() {
          Navigator.of(context).pop();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Post Delete Successfully',
            ),
          ),
        );
        // } else {
        //   setState(() {
        //     _isLoading = false;
        //     Navigator.of(context).pop();
        //   });
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(
        //         response['message'],
        //       ),
        //     ),
        //   );
        // }
      },
    );

    // set up the AlertDialog
    return AlertDialog(
      title: const Text("Warning"),
      content: const Text("Would you like to Delete?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      bloc: widget.profileBloc,
      // listenWhen: (previous, current) => current is DrugsState,
      // buildWhen: (previous, current) => current is! DrugsState,
      listener: (BuildContext context, ProfileState state) {
        if (state is DataError) {
          // showDialog(
          //   context: context,
          //   builder: (context) => AlertDialog(
          //     content: Text(state.errorMessage),
          //   ),
          // );
        }
      },
      builder: (context, state) {
        if (state is PaginationLoadedState) {
          return widget.profileBloc.postList.isEmpty
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("No Post Found"),
                  ),
                )
              : Container(
                  color: svGetBgColor(),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: widget.profileBloc.postList.length,
                    itemBuilder: (context, index) {
                      if (widget.profileBloc.pageNumber <=
                          widget.profileBloc.numberOfPage) {
                        if (index ==
                            widget.profileBloc.postList.length -
                                widget.profileBloc.nextPageTrigger) {
                          widget.profileBloc
                              .add(CheckIfNeedMoreDataEvent(index: index));
                        }
                      }

                      return widget.profileBloc.numberOfPage !=
                                  widget.profileBloc.pageNumber - 1 &&
                              index >= widget.profileBloc.postList.length - 1
                          ? Center(
                              child: CircularProgressIndicator(
                                color: svGetBodyColor(),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.only(top: 10),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                  borderRadius: radius(SVAppCommonRadius),
                                  color: context.cardColor),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl:
                                                  "${AppData.imageUrl}${widget.profileBloc.postList[index].user?.profilePic!.validate()}",
                                              height: 50,
                                              width: 50,
                                              fit: BoxFit.cover,
                                            ).cornerRadiusWithClipRRect(20),
                                            12.width,
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                TextIconWidget(
                                                    text: widget
                                                            .profileBloc
                                                            .postList[index]
                                                            .user
                                                            ?.name ??
                                                        '',
                                                    suffix: Image.asset(
                                                        'images/socialv/icons/ic_TickSquare.png',
                                                        height: 14,
                                                        width: 14,
                                                        fit: BoxFit.cover),
                                                    textStyle: boldTextStyle()),
                                                Row(
                                                  children: [
                                                    Text(
                                                        timeAgo.format(DateTime
                                                            .parse(widget
                                                                .profileBloc
                                                                .postList[index]
                                                                .createdAt!)),
                                                        style: secondaryTextStyle(
                                                            color:
                                                                svGetBodyColor(),
                                                            size: 12)),
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 8.0),
                                                      child: Icon(
                                                        Icons.access_time,
                                                        size: 20,
                                                        color: Colors.grey,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                            // 4.width,
                                          ],
                                        ).paddingSymmetric(horizontal: 16),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (widget.profileBloc.postList[index]
                                                  .userId ==
                                              AppData.logInUserId)
                                            PopupMenuButton(
                                              itemBuilder: (context) {
                                                return [
                                                  PopupMenuItem(
                                                    child: Builder(
                                                        builder: (context) {
                                                      return Column(
                                                        children: ["Delete"]
                                                            .map((String item) {
                                                          return PopupMenuItem(
                                                            value: item,
                                                            child: Text(item),
                                                          );
                                                        }).toList(),
                                                      );
                                                    }),
                                                  ),
                                                ];
                                              },
                                              onSelected: (value) {
                                                if (value == 'Delete') {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return showAlertDialog(
                                                          widget.profileBloc,
                                                          context,
                                                          widget
                                                                  .profileBloc
                                                                  .postList[
                                                                      index]
                                                                  .id ??
                                                              0);
                                                    },
                                                  );
                                                }
                                              },
                                            )
                                          // IconButton(onPressed: () {},
                                          //     icon: const Icon(Icons.more_horiz)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  16.height,
                                  widget.profileBloc.postList[index].title
                                          .validate()
                                          .isNotEmpty
                                      ? _buildPlaceholderWithoutFile(
                                          context,
                                          widget.profileBloc.postList[index]
                                                  .title ??
                                              '',
                                          widget.profileBloc.postList[index]
                                                  .backgroundColor ??
                                              '#ffff',
                                          widget.profileBloc.postList[index]
                                              .image,
                                          widget.profileBloc.postList[index]
                                              .media,
                                          index)
                                      // ? svRobotoText(
                                      // text: homeBloc.postList[index].title.validate(),
                                      // textAlign: TextAlign.start).paddingSymmetric(
                                      // horizontal: 16)
                                      : const Offstage(),
                                  widget.profileBloc.postList[index].title
                                          .validate()
                                          .isNotEmpty
                                      ? 16.height
                                      : const Offstage(),
                                  _buildMediaContent(context, index)
                                      .cornerRadiusWithClipRRect(0)
                                      .center(),
                                  // Image.asset('',
                                  //   // homeBloc.postList[index].image?.validate(),
                                  //   height: 300,
                                  //   width: context.width() - 32,
                                  //   fit: BoxFit.cover,
                                  // ).cornerRadiusWithClipRRect(SVAppCommonRadius).center(),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8.0, top: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            LikesListScreen(
                                                    id: widget.profileBloc
                                                            .postList[index].id
                                                            .toString() ??
                                                        '0')
                                                .launch(context);
                                          },
                                          child: Text(
                                              '${widget.profileBloc.postList[index].likes?.length ?? 0.validate()} Likes',
                                              style: secondaryTextStyle(
                                                  color: svGetBodyColor())),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            SVCommentScreen(
                                              id: widget.profileBloc
                                                      .postList[index].id ??
                                                  0,
                                              homeBloc: homeBloc,
                                            ).launch(context);
                                          },
                                          child: Text(
                                              '${widget.profileBloc.postList[index].comments?.length ?? 0.validate()} comments',
                                              style: secondaryTextStyle(
                                                  color: svGetBodyColor())),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 0.2,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          print('object');
                                          setState(() {});
                                          if (findIsLiked(widget.profileBloc
                                              .postList[index].likes)) {
                                            print('object unlike');
                                            widget.profileBloc.postList[index]
                                                .likes!
                                                .removeWhere((e) =>
                                                    e.userId ==
                                                    AppData.logInUserId);
                                          } else {
                                            widget.profileBloc.postList[index]
                                                .likes!
                                                .add(Likes(
                                                    id: index,
                                                    userId: AppData.logInUserId,
                                                    postId: widget.profileBloc
                                                        .postList[index].id
                                                        .toString(),
                                                    createdAt: '',
                                                    updatedAt: ''));
                                          }
                                          homeBloc.add(PostLikeEvent(
                                              postId: widget.profileBloc
                                                      .postList[index].id ??
                                                  0));
                                        },
                                        child: Column(
                                          children: [
                                            findIsLiked(widget.profileBloc
                                                    .postList[index].likes)
                                                ? Image.asset(
                                                    'images/socialv/icons/ic_HeartFilled.png',
                                                    height: 20,
                                                    width: 22,
                                                    fit: BoxFit.fill)
                                                : Image.asset(
                                                    'images/socialv/icons/ic_Heart.png',
                                                    height: 22,
                                                    width: 22,
                                                    fit: BoxFit.cover,
                                                    color: context.iconColor,
                                                  ),
                                            Text('Like',
                                                style: secondaryTextStyle(
                                                    color: svGetBodyColor())),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          setState(() {
                                            if (isShowComment == -1) {
                                              isShowComment = index;
                                            } else {
                                              isShowComment = -1;
                                            }
                                          });

                                          // SVCommentScreen(
                                          //         id: widget.profileBloc
                                          //                 .postList[index].id ??
                                          //             0,homeBloc: homeBloc,)
                                          //     .launch(context);
                                        },
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              'images/socialv/icons/ic_Chat.png',
                                              height: 22,
                                              width: 22,
                                              fit: BoxFit.cover,
                                              color: context.iconColor,
                                            ),
                                            Text('Comment',
                                                style: secondaryTextStyle(
                                                    color: svGetBodyColor())),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          String mediaLink;
                                          if (widget.profileBloc.postList[index]
                                              .media!.isNotEmpty) {
                                            mediaLink = widget
                                                    .profileBloc
                                                    .postList[index]
                                                    .media
                                                    ?.first
                                                    .mediaPath ??
                                                "";
                                          } else {
                                            mediaLink = '';
                                          }
                                          Share.share(
                                              '${removeHtmlTags(widget.profileBloc.postList[index].title ?? '')}\n https://doctak.net/post/${widget.profileBloc.postList[index].id} \n'
                                              '${AppData.imageUrl}$mediaLink');
                                        },
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.share_sharp,
                                              size: 22,
                                              // 'images/socialv/icons/ic_share.png',
                                              // height: 22,
                                              // width: 22,
                                              // fit: BoxFit.cover,
                                              color: context.iconColor,
                                            ),
                                            Text('Share',
                                                style: secondaryTextStyle(
                                                    color: svGetBodyColor())),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ).paddingSymmetric(
                                      horizontal: 16, vertical: 10),
                                  if (isShowComment == index)
                                    SVCommentReplyComponent(
                                        comment_bloc.CommentBloc(),
                                        widget.profileBloc.postList[index].id ??
                                            0, (value) {
                                      if (value.isNotEmpty) {
                                        var comments =
                                            comment_bloc.CommentBloc();
                                        comments.add(
                                            comment_bloc.PostCommentEvent(
                                                postId: widget.profileBloc
                                                        .postList[index].id ??
                                                    0,
                                                comment: value));

                                        widget.profileBloc.postList[index]
                                            .comments!
                                            .add(Comments());
                                        setState(() {
                                          isShowComment = -1;
                                        });
                                      }
                                    }),
                                  Container(
                                    height: 16,
                                    color: svGetBgColor(),
                                  )

                                  // const Divider(indent: 16, endIndent: 16, height: 20),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.center,
                                  //   children: [
                                  //     SizedBox(
                                  //       width: 56,
                                  //       child: Stack(
                                  //         alignment: Alignment.centerLeft,
                                  //         children: [
                                  //           Positioned(
                                  //             right: 0,
                                  //             child: Container(
                                  //               decoration: BoxDecoration(
                                  //                   border: Border.all(
                                  //                       color: Colors.white, width: 2),
                                  //                   borderRadius: radius(100)),
                                  //               child: Image.asset(
                                  //                   'images/socialv/faces/face_1.png',
                                  //                   height: 24,
                                  //                   width: 24,
                                  //                   fit: BoxFit.cover)
                                  //                   .cornerRadiusWithClipRRect(100),
                                  //             ),
                                  //           ),
                                  //           Positioned(
                                  //             left: 14,
                                  //             child: Container(
                                  //               decoration: BoxDecoration(
                                  //                   border: Border.all(
                                  //                       color: Colors.white, width: 2),
                                  //                   borderRadius: radius(100)),
                                  //               child: Image.asset(
                                  //                   'images/socialv/faces/face_2.png',
                                  //                   height: 24,
                                  //                   width: 24,
                                  //                   fit: BoxFit.cover)
                                  //                   .cornerRadiusWithClipRRect(100),
                                  //             ),
                                  //           ),
                                  //           Positioned(
                                  //             child: Container(
                                  //               decoration: BoxDecoration(
                                  //                   border: Border.all(
                                  //                       color: Colors.white, width: 2),
                                  //                   borderRadius: radius(100)),
                                  //               child: Image.asset(
                                  //                   'images/socialv/faces/face_3.png',
                                  //                   height: 24,
                                  //                   width: 24,
                                  //                   fit: BoxFit.cover)
                                  //                   .cornerRadiusWithClipRRect(100),
                                  //             ),
                                  //           ),
                                  //         ],
                                  //       ),
                                  //     ),
                                  //     10.width,
                                  // //     RichText(
                                  // //       text: TextSpan(
                                  // //         text: 'Liked By ',
                                  // //         style: secondaryTextStyle(
                                  // //             color: svGetBodyColor(), size: 12),
                                  // //         children: <TextSpan>[
                                  // //           TextSpan(text: 'Ms.Mountain ',
                                  // //               style: boldTextStyle(size: 12)),
                                  // //           TextSpan(text: 'And ',
                                  // //               style: secondaryTextStyle(
                                  // //                   color: svGetBodyColor(), size: 12)),
                                  // //           TextSpan(text: '${widget.profileBloc.postList[index].likes?.length??0} Others ',
                                  // //               style: boldTextStyle(size: 12)),
                                  // //         ],
                                  // //       ),
                                  // //     )
                                  //   ],
                                  // )
                                ],
                              ),
                            );
                    },
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                  ),
                );
        } else if (state is DataError) {
          return Expanded(
            child: Center(
              child: Text(state.errorMessage),
            ),
          );
        } else {
          return const Expanded(
              child: Center(child: Text('Something went wrong')));
        }
      },
    );
  }

  Future<void> _launchURL(context, String urlString) async {
    Uri url = Uri.parse(urlString);

    // Show a confirmation dialog before launching the URL
    bool shouldLaunch = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Open Link'),
              content: Text('Would you like to open this link? \n$urlString'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Return false to shouldLaunch
                  },
                ),
                TextButton(
                  child: const Text('Open'),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(true); // Return true to shouldLaunch
                  },
                ),
              ],
            );
          },
        ) ??
        false; // shouldLaunch will be false if the dialog is dismissed

    if (shouldLaunch) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leaving the app canceled.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Color contrastingTextColor(Color bgColor) {
    // Calculate the luminance of the background color
    double luminance = bgColor.computeLuminance();
    // Return black or white text color based on luminance
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildPlaceholderWithoutFile(
      context, title, backgroundColor, image, media, index) {
    String fullText = title ?? '';
    List<String> words = fullText.split(' ');
    bool isExpanded = _expandedIndex == index;
    String textToShow = isExpanded || words.length <= 25
        ? fullText
        : '${words.take(20).join(' ')}...';

    Color bgColor = PostUtils.HexColor(backgroundColor);

    Color textColor = PostUtils.contrastingTextColor(bgColor);
    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: (image?.isNotEmpty == true || media?.isNotEmpty == true)
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
                if (image?.isNotEmpty == true || media?.isNotEmpty == true)
                  if (_isHtml(textToShow))
                    Center(
                      child: HtmlWidget(textToShow, onTapUrl: (link) async {
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
                          String jobID = Uri.parse(link.url).pathSegments.last;
                          JobsDetailsScreen(
                            jobId: jobID,
                          ).launch(context);
                        } else {
                          PostUtils.launchURL(context, link.url);
                        }
                      },
                      text: textToShow,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: (image?.isNotEmpty == true ||
                                media?.isNotEmpty == true)
                            ? svGetBodyColor()
                            : svGetBodyColor(),
                        fontWeight: FontWeight.bold,
                      ),
                      linkStyle: const TextStyle(
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    )
                else if (_isHtml(textToShow))
                  Container(
                    constraints: BoxConstraints(
                        minHeight: textToShow.length < 25 ? 200 : 0),
                    child: Center(
                      child: HtmlWidget(
                        textStyle :TextStyle(fontFamily: 'Poppins',),
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
                    onPressed: () => setState(() {
                      if (isExpanded) {
                        _expandedIndex = -1; // Collapse if already expanded
                      } else {
                        _expandedIndex = index; // Expand the clicked item
                      }
                    }),
                    child: Text(
                      isExpanded ? 'Show Less' : 'Show More',
                      style: TextStyle(
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
        );
      },
    );
  }

  String removeHtmlTags(String htmlString) {
    final RegExp htmlTagRegExp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(htmlTagRegExp, '');
  }

  bool _isHtml(String text) {
    // Simple regex to check if the string contains HTML tags
    final htmlTagPattern = RegExp(r'<[^>]*>');
    return htmlTagPattern.hasMatch(text);
  }

  Widget _buildMediaContent(context, index) {
    return PostMediaWidget(
        mediaList: widget.profileBloc.postList[index].media ?? [],
        imageUrlBase: AppData.imageUrl,
        onImageTap: (url) {
          showFullScreenImage(
            context,
            1,
            url,
            widget.profileBloc.postList[index],
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
            widget.profileBloc.postList[index],
            mediaUrls,
          );
        });
  }

  int _expandedIndex = -1;
}
