import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/post_media_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/text_icon_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentReplyComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/SVCommentScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/app/AppData.dart';
import '../../../../data/models/post_model/post_data_model.dart';
import '../../home/screens/likes_list_screen/likes_list_screen.dart';
import '../../utils/SVCommon.dart';
import 'bloc/home_bloc.dart';
import 'post_widget/find_likes.dart';
import 'post_widget/full_screen_image_widget.dart';

class PostDetailsScreen extends StatefulWidget {
  int? postId;

  PostDetailsScreen({this.postId, super.key});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  HomeBloc homeBloc = HomeBloc();

  @override
  void initState() {
    homeBloc.add(DetailsPostEvent(postId: widget.postId ?? 0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          surfaceTintColor: svGetScaffoldColor(),
          iconTheme: IconThemeData(color: context.iconColor),
          title: Text('Post Detail', style: boldTextStyle(size: 18)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: svGetBodyColor()),
              onPressed: () {
                NavigatorService.goBack();
                // backPress!();
              }),
          elevation: 0,
          centerTitle: true,
        ),
        body: BlocConsumer<HomeBloc, HomeState>(
            bloc: homeBloc,
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
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              borderRadius: radius(SVAppCommonRadius),
                              color: context.cardColor),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        SVProfileFragment(
                                                userId: homeBloc
                                                    .postData?.post?.user?.id)
                                            .launch(context);
                                      },
                                      child: Row(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl:
                                                "${AppData.imageUrl}${homeBloc.postData?.post?.user?.profilePic!.validate()}",
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
                                                  text: homeBloc.postData?.post
                                                          ?.user?.name ??
                                                      '',
                                                  suffix: Image.asset(
                                                      'images/socialv/icons/ic_TickSquare.png',
                                                      height: 14,
                                                      width: 14,
                                                      fit: BoxFit.cover),
                                                  textStyle: boldTextStyle()),
                                              Row(
                                                children: [
                                                  Text('',
                                                      style: secondaryTextStyle(
                                                          color: svGetBodyColor(),
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
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (homeBloc.postData?.post?.userId ==
                                          AppData.logInUserId)
                                        PopupMenuButton(
                                          itemBuilder: (context) {
                                            return [
                                              PopupMenuItem(
                                                child:
                                                    Builder(builder: (context) {
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
                                                builder: (BuildContext context) {
                                                  return showAlertDialog(
                                                      context,
                                                      homeBloc.postData?.post
                                                              ?.id ??
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
                              homeBloc.postData?.post?.title?.isNotEmpty ?? false
                                  ? _buildPlaceholderWithoutFile(
                                      context,
                                      homeBloc.postData?.post?.title ?? '',
                                      homeBloc.postData?.post?.backgroundColor ??
                                          '#ffff',
                                      homeBloc.postData?.post?.image,
                                      homeBloc.postData?.post?.media)
                                  // ? svRobotoText(
                                  // text: homeBloc.postData?.post?.title.validate(),
                                  // textAlign: TextAlign.start).paddingSymmetric(
                                  // horizontal: 16)
                                  : const Offstage(),
                              homeBloc.postData?.post?.title?.isNotEmpty ?? false
                                  ? 16.height
                                  : const Offstage(),
                              _buildMediaContent(context)
                                  .cornerRadiusWithClipRRect(0)
                                  .center(),
                              // Image.asset('',
                              //   // homeBloc.postData?.post?.image?.validate(),
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
                                                id: homeBloc.postData?.post?.id
                                                        ?.toString() ??
                                                    '0')
                                            .launch(context);
                                      },
                                      child: Text(
                                          '${homeBloc.postData?.post?.likes?.length ?? 0.validate()} Likes',
                                          style: secondaryTextStyle(
                                              color: svGetBodyColor())),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        SVCommentScreen(
                                                homeBloc: homeBloc,
                                                id: homeBloc.postData?.post?.id ??
                                                    0)
                                            .launch(context);
                                      },
                                      child: Text(
                                          '${homeBloc.postData?.post?.comments?.length ?? 0.validate()} comments',
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () {
                                        homeBloc.add(PostLikeEvent(
                                            postId: homeBloc.postData?.post?.id ??
                                                0));
                                      },
                                      child: Column(
                                        children: [
                                          findIsLiked(
                                                  homeBloc.postData?.post?.likes)
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
                                      )),
                                  InkWell(
                                    splashColor: Colors.grey,
                                    highlightColor: Colors.grey,
                                    onTap: () {
                                      setState(() {
                                        // if (isShowComment == -1) {
                                        //   isShowComment = index;
                                        // } else {
                                        //   FocusScope.of(context)
                                        //       .unfocus();
                                        //   isShowComment = -1;
                                        // }
                                      });
                                      // SVCommentScreen(
                                      //         id: widget
                                      //                 .homeBloc
                                      //                 .postData
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
                                      //     .postData);
                                      String mediaLink;
                                      if (homeBloc.postData?.post?.media
                                              ?.isNotEmpty ??
                                          false) {
                                        mediaLink = homeBloc.postData?.post?.media
                                                ?.first.mediaPath ??
                                            "";
                                      } else {
                                        mediaLink = '';
                                      }
                                      createDynamicLink(
                                          removeHtmlTags(
                                              homeBloc.postData?.post?.title ??
                                                  ''),
                                          'https://doctak.net/post/${homeBloc.postData?.post?.id}',
                                          mediaLink);
                                      // _handleIncomingLinks();
                                      //   Share.share('${removeHtmlTags(widget
                                      //     .homeBloc
                                      //     .postData?.title??'')}\n https://doctak.net/post/${widget
                                      //       .homeBloc
                                      //       .postData?.id} \n'
                                      //       '${AppData.imageUrl}$mediaLink');
                                      // // shareImageWithText('${AppData.imageUrl}$mediaLink',removeHtmlTags(widget
                                      //     .homeBloc
                                      //     .postData?.title??''));
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
                              // if (isShowComment == index)
                              SVCommentReplyComponent(
                                  CommentBloc(), homeBloc.postData?.post?.id ?? 0,
                                  (value) {
                                if (value.isNotEmpty) {
                                  var comments = CommentBloc();
                                  comments.add(PostCommentEvent(
                                      postId: homeBloc.postData?.post?.id ?? 0,
                                      comment: value));
                  
                                  homeBloc.postData?.post?.comments!
                                      .add(Comments());
                                  setState(() {
                                    // isShowComment = -1;
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
                              // //           TextSpan(text: '${homeBloc.postData?.post?.likes?.length??0} Others ',
                              // //               style: boldTextStyle(size: 12)),
                              // //         ],
                              // //       ),
                              // //     )
                              //   ],
                              // )
                            ],
                          ),
                        ),
                );
              } else {
                return RetryWidget(
                    errorMessage: "Something went wrong please try again",
                    onRetry: () {
                      try {
                        homeBloc.add(DetailsPostEvent(postId: widget.postId));

                        // Session newSession = await createNewChatSession();
                        // setState(() {
                        //   futureSessions = Future(() =>
                        //       [newSession, ...(snapshot.data ?? [])]);
                        // });
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    });
              }
            }));
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
        homeBloc.add(DeletePostEvent(postId: id));
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

  String parseHtmlString(String htmlString) {
    // Parse the HTML string
    dom.Document document = html_parser.parse(htmlString);

    // Extract and return the text content without tags
    return document.body?.text ?? '';
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
        return GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: parseHtmlString(title)));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Text copied to clipboard")),
            );
          },
          child: DecoratedBox(
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
                        textAlign: TextAlign.center,
                      )
                  else if (_isHtml(textToShow))
                    Container(
                      constraints: BoxConstraints(
                          minHeight: textToShow.length < 25 ? 200 : 0),
                      child: Center(
                        child: HtmlWidget(
                          textStyle: GoogleFonts.poppins(),
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

  Widget _buildMediaContent(context) {
    return PostMediaWidget(
        mediaList: homeBloc.postData?.post?.media ?? [],
        imageUrlBase: AppData.imageUrl,
        onImageTap: (url) {
          showFullScreenImage(
            context,
            1,
            url,
            homeBloc.postData,
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
            homeBloc.postData,
            mediaUrls,
          );
        });
  }

  bool _isExpanded = false;
}
