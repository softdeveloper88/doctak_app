import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/full_screen_image_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/share_post_bottom_dialog.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentReplyComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../fragments/home_main_screen/post_widget/find_likes.dart';
import '../../fragments/home_main_screen/post_widget/post_media_widget.dart';
import '../../fragments/home_main_screen/post_widget/text_icon_widget.dart';
import '../screens/comment_screen/SVCommentScreen.dart';
import '../screens/comment_screen/bloc/comment_bloc.dart';

class SVPostComponent extends StatefulWidget {
  SVPostComponent(this.homeBloc, {super.key});

  HomeBloc homeBloc;

  @override
  State<SVPostComponent> createState() => _SVPostComponentState();
}

int? isShowComment = -1;

class _SVPostComponentState extends State<SVPostComponent> {
  // createDynamicLink(postTitle, postUrl, imageUrl) async {
  //   final dynamicLinkParams = DynamicLinkParameters(
  //     link: Uri.parse(postUrl),
  //     uriPrefix: "https://doctak.page.link",
  //     androidParameters: const AndroidParameters(
  //       packageName: "com.kt.doctak",
  //       minimumVersion: 41,
  //     ),
  //     iosParameters: const IOSParameters(
  //       bundleId: "com.kt.doctak",
  //       appStoreId: "6448684340",
  //       minimumVersion: "2.0.9",
  //     ),
  //     googleAnalyticsParameters: const GoogleAnalyticsParameters(
  //       source: "twitter",
  //       medium: "social",
  //       campaign: "example-promo",
  //     ),
  //     socialMetaTagParameters: SocialMetaTagParameters(
  //       title: postTitle,
  //       imageUrl: Uri.parse(imageUrl),
  //     ),
  //   );
  //   final dynamicLink =
  //       await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
  //   Share.share(dynamicLink.shortUrl.toString());
  // }
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      bloc: widget.homeBloc,
      listener: (BuildContext context, HomeState state) {
        if (state is PostDataError) {
          // showDialog(
          //   context: context,
          //   builder: (context) => AlertDialog(
          //     content: Text(state.errorMessage),
          //   ),
          // );
        }
      },
      builder: (context, state) {
        if (state is PostPaginationLoadingState) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3, // Display 3 shimmering tiles when loading
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                // Base color of the shimmer
                highlightColor: Colors.grey[100]!,
                // Highlight color of the shimmer
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                        ),
                        title: Container(
                          width: double.infinity,
                          height: 10.0,
                          color: Colors.white,
                        ),
                        subtitle: Container(
                          width: double.infinity,
                          height: 10.0,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          // Shimmer effect color
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          // return const Center(child: CircularProgressIndicator(color: svGetBodyColor(),));
        } else if (state is PostPaginationLoadedState) {
          return widget.homeBloc.postList.isEmpty
              ? const Center(child: Text("No result Found"))
              : ListView.builder(
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.homeBloc.postList.length,
                  itemBuilder: (context, index) {
                    if (widget.homeBloc.pageNumber <=
                        widget.homeBloc.numberOfPage) {
                      if (index ==
                          widget.homeBloc.postList.length -
                              widget.homeBloc.nextPageTrigger) {
                        widget.homeBloc
                            .add(PostCheckIfNeedMoreDataEvent(index: index));
                      }
                    }

                    return widget.homeBloc.numberOfPage !=
                                widget.homeBloc.pageNumber - 1 &&
                            index >= widget.homeBloc.postList.length - 1
                        ? Center(
                            child: CircularProgressIndicator(
                              color: svGetBodyColor(),
                            ),
                          )
                        : Column(
                            children: [
                              if (index % 5 == 0 && index != 0)
                                NativeAdWidget(),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                margin: const EdgeInsets.symmetric(vertical: 8),
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
                                          child: InkWell(
                                            onTap: () {
                                              SVProfileFragment(
                                                      userId: widget
                                                          .homeBloc
                                                          .postList[index]
                                                          .user
                                                          ?.id)
                                                  .launch(context);
                                            },
                                            child: Row(
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl:
                                                      "${AppData.imageUrl}${widget.homeBloc.postList[index].user?.profilePic!.validate()}",
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
                                                                .homeBloc
                                                                .postList[index]
                                                                .user
                                                                ?.name ??
                                                            '',
                                                        suffix: Image.asset(
                                                            'images/socialv/icons/ic_TickSquare.png',
                                                            height: 14,
                                                            width: 14,
                                                            fit: BoxFit.cover),
                                                        textStyle:
                                                            boldTextStyle()),
                                                    Row(
                                                      children: [
                                                        Text(
                                                            timeAgo.format(DateTime
                                                                .parse(widget
                                                                    .homeBloc
                                                                    .postList[
                                                                        index]
                                                                    .createdAt!)),
                                                            style: secondaryTextStyle(
                                                                color:
                                                                    svGetBodyColor(),
                                                                size: 12)),
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.only(
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
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (widget.homeBloc.postList[index]
                                                    .userId ==
                                                AppData.logInUserId)
                                              PopupMenuButton(
                                                itemBuilder: (context) {
                                                  return [
                                                    PopupMenuItem(
                                                      child: Builder(
                                                          builder: (context) {
                                                        return Column(
                                                          children: [
                                                            "Delete"
                                                          ].map((String item) {
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
                                                      builder: (BuildContext
                                                          context) {
                                                        return showAlertDialog(
                                                            context,
                                                            widget
                                                                    .homeBloc
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
                                    widget.homeBloc.postList[index].title
                                            .validate()
                                            .isNotEmpty
                                        ? _buildPlaceholderWithoutFile(
                                            context,
                                            widget.homeBloc.postList[index]
                                                    .title ??
                                                '',
                                            widget.homeBloc.postList[index]
                                                    .backgroundColor ??
                                                '#ffff',
                                            widget
                                                .homeBloc.postList[index].image,
                                            widget
                                                .homeBloc.postList[index].media)
                                        // ? svRobotoText(
                                        // text: homeBloc.postList[index].title.validate(),
                                        // textAlign: TextAlign.start).paddingSymmetric(
                                        // horizontal: 16)
                                        : const Offstage(),
                                    widget.homeBloc.postList[index].title
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
                                                      id: widget
                                                              .homeBloc
                                                              .postList[index]
                                                              .id ??
                                                          0)
                                                  .launch(context);
                                            },
                                            child: Text(
                                                '${widget.homeBloc.postList[index].likes?.length ?? 0.validate()} Likes',
                                                style: secondaryTextStyle(
                                                    color: svGetBodyColor())),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              SVCommentScreen(
                                                      homeBloc: widget.homeBloc,
                                                      id: widget
                                                              .homeBloc
                                                              .postList[index]
                                                              .id ??
                                                          0)
                                                  .launch(context);
                                            },
                                            child: Text(
                                                '${widget.homeBloc.postList[index].comments?.length ?? 0.validate()} comments',
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
                                              widget.homeBloc.add(PostLikeEvent(
                                                  postId: widget.homeBloc
                                                          .postList[index].id ??
                                                      0));
                                            },
                                            child: Column(
                                              children: [
                                                findIsLiked(widget.homeBloc
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
                                                        color:
                                                            context.iconColor,
                                                      ),
                                                Text('Like',
                                                    style: secondaryTextStyle(
                                                        color:
                                                            svGetBodyColor())),
                                              ],
                                            )),
                                        InkWell(
                                          splashColor: Colors.grey,
                                          highlightColor: Colors.grey,
                                          onTap: () {
                                            setState(() {
                                              if (isShowComment == -1) {
                                                isShowComment = index;
                                              } else {
                                                isShowComment = -1;
                                              }
                                            });
                                            // SVCommentScreen(
                                            //         id: widget
                                            //                 .homeBloc
                                            //                 .postList[index]
                                            //                 .id ??
                                            //             0)
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
                                            // _showBottomSheet(context,widget
                                            //     .homeBloc
                                            //     .postList[index]);
                                            String mediaLink;
                                            if (widget.homeBloc.postList[index]
                                                .media!.isNotEmpty) {
                                              mediaLink = widget
                                                      .homeBloc
                                                      .postList[index]
                                                      .media
                                                      ?.first
                                                      .mediaPath ??
                                                  "";
                                            } else {
                                              mediaLink = '';
                                            }
                                            createDynamicLink(
                                                removeHtmlTags(widget
                                                        .homeBloc
                                                        .postList[index]
                                                        .title ??
                                                    ''),
                                                'https://doctak.net/post/${widget.homeBloc.postList[index].id}',
                                                mediaLink);
                                            // _handleIncomingLinks();
                                            //   Share.share('${removeHtmlTags(widget
                                            //     .homeBloc
                                            //     .postList[index].title??'')}\n https://doctak.net/post/${widget
                                            //       .homeBloc
                                            //       .postList[index].id} \n'
                                            //       '${AppData.imageUrl}$mediaLink');
                                            // // shareImageWithText('${AppData.imageUrl}$mediaLink',removeHtmlTags(widget
                                            //     .homeBloc
                                            //     .postList[index].title??''));
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
                                              Text('share',
                                                  style: secondaryTextStyle(
                                                      color: svGetBodyColor())),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ).paddingSymmetric(horizontal: 16),
                                    if (isShowComment == index)
                                      SVCommentReplyComponent(
                                          CommentBloc(),
                                          widget.homeBloc.postList[index].id ??
                                              0, (value) {
                                        if (value.isNotEmpty) {
                                          var comments = CommentBloc();
                                          comments.add(PostCommentEvent(
                                              postId: widget.homeBloc
                                                      .postList[index].id ??
                                                  0,
                                              comment: value));

                                          widget.homeBloc.postList[index]
                                              .comments!
                                              .add(Comments());
                                          setState(() {
                                            isShowComment = -1;
                                          });
                                        }
                                      })
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
                                    // //           TextSpan(text: '${widget.homeBloc.postList[index].likes?.length??0} Others ',
                                    // //               style: boldTextStyle(size: 12)),
                                    // //         ],
                                    // //       ),
                                    // //     )
                                    //   ],
                                    // )
                                  ],
                                ),
                              ),
                            ],
                          );
                  },
                  shrinkWrap: true,
                  // physics: const NeverScrollableScrollPhysics(),
                );
        } else if (state is PostDataError) {
          return Center(
            child: Text(state.errorMessage),
          );
        } else {
          return const Center(child: Text('Search Post'));
        }
      },
    );
  }

  String removeHtmlTags(String htmlString) {
    final RegExp htmlTagRegExp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(htmlTagRegExp, '');
  }

  showAlertDialog(BuildContext context, int id) {
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
        widget.homeBloc.add(DeletePostEvent(postId: id));
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

  Widget _buildPlaceholderWithoutFile(
      context, title, backgroundColor, image, media) {
    String fullText = title ?? '';
    List<String> words = fullText.split(' ');
    String textToShow = _isExpanded || words.length <= 25
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
                    HtmlWidget(textToShow, onTapUrl: (link) async {
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
                    })
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
                      textAlign: TextAlign.left,
                    )
                else if (_isHtml(textToShow))
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 200.0,
                      minWidth:
                          double.infinity, // Minimum height of the container
                    ),
                    child: Center(
                      child: HtmlWidget(
                        textStyle: GoogleFonts.poppins(),
                        enableCaching: true,
                        '<div style="text-align: center;">$textToShow</div>',
                        onTapUrl: (link) async {
                          print(link);
                          if (link.contains('doctak/jobs-detail')) {
                            String jobID =
                                Uri.parse(link).pathSegments.last;
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
                      fontSize: 14.0,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    linkStyle: const TextStyle(
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.left,
                  ),
                if (words.length > 25)
                  TextButton(
                    onPressed: () => setState(() {
                      _isExpanded = !_isExpanded;
                    }),
                    child: Text(
                      _isExpanded ? 'Show Less' : 'Show More',
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

  bool _isHtml(String text) {
    // Simple regex to check if the string contains HTML tags
    final htmlTagPattern = RegExp(r'<[^>]*>');
    return htmlTagPattern.hasMatch(text);
  }

  Widget _buildMediaContent(context, index) {
    return PostMediaWidget(
        mediaList: widget.homeBloc.postList[index].media ?? [],
        imageUrlBase: AppData.imageUrl,
        onImageTap: (url) {
          showFullScreenImage(
            context,
            1,
            url,
            widget.homeBloc.postList[index],
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
            widget.homeBloc.postList[index],
            mediaUrls,
          );
        });
  }

  bool _isExpanded = false;

  void _showBottomSheet(BuildContext context, Post postList) {
    showModalBottomSheet(
      showDragHandle: true,
      enableDrag: true,
      isScrollControlled: true,
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.9,
              maxChildSize: 1.0,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SharePostBottomDialog(postList),
                );
              });
        });
      },
    );
  }
}
