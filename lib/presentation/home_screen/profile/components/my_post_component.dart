import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/sv_comment_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart' as comment_bloc;
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../../../data/models/post_model/post_data_model.dart';
import '../../fragments/home_main_screen/post_widget/find_likes.dart';
import '../../fragments/home_main_screen/post_widget/post_item_widget.dart';

class MyPostComponent extends StatefulWidget {
  const MyPostComponent(this.profileBloc, {super.key});

  final ProfileBloc profileBloc;

  @override
  State<MyPostComponent> createState() => _MyPostComponentState();
}

class _MyPostComponentState extends State<MyPostComponent> {
  HomeBloc homeBloc = HomeBloc();
  int isShowComment = -1;

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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: theme.divider, borderRadius: BorderRadius.circular(2)),
              ),
              // Comment Screen
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SVCommentScreen(id: postId, homeBloc: homeBloc),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AlertDialog showAlertDialog(ProfileBloc profileBloc, BuildContext context, int id) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text(translation(context).lbl_cancel, style: const TextStyle(color: Colors.red)),
      onPressed: () {
        setState(() {
          Navigator.of(context).pop('dismiss');
        });
      },
    );
    Widget continueButton = TextButton(
      child: Text(translation(context).lbl_yes, style: const TextStyle(color: Colors.black)),
      onPressed: () async {
        homeBloc.add(DeletePostEvent(postId: id));
        profileBloc.postList.removeWhere((post) => post.id == id);
        setState(() {
          Navigator.of(context).pop();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).msg_post_deleted_successfully)));
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
    return AlertDialog(title: Text(translation(context).lbl_warning), content: Text(translation(context).msg_delete_confirm), actions: [cancelButton, continueButton]);

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
              ? SizedBox(height: 200, child: Center(child: Text(translation(context).msg_no_post_found)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: widget.profileBloc.postList.length,
                  itemBuilder: (context, index) {
                    if (widget.profileBloc.pageNumber <= widget.profileBloc.numberOfPage) {
                      if (index == widget.profileBloc.postList.length - widget.profileBloc.nextPageTrigger) {
                        widget.profileBloc.add(CheckIfNeedMoreDataEvent(index: index));
                      }
                    }

                    if (widget.profileBloc.numberOfPage != widget.profileBloc.pageNumber - 1 && index >= widget.profileBloc.postList.length - 1) {
                      return Center(child: CircularProgressIndicator(color: svGetBodyColor()));
                      // Container(
                      //         padding: const EdgeInsets.only(top: 10),
                      //         margin: const EdgeInsets.symmetric(vertical: 4),
                      //         decoration: BoxDecoration(
                      //             borderRadius: radius(SVAppCommonRadius),
                      //             color: context.cardColor),
                      //         child: Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             Row(
                      //               mainAxisAlignment:
                      //                   MainAxisAlignment.spaceBetween,
                      //               children: [
                      //                 Expanded(
                      //                   child: Row(
                      //                     children: [
                      //                       CachedNetworkImage(
                      //                         imageUrl:
                      //                             "${AppData.imageUrl}${widget.profileBloc.postList[index].user?.profilePic!.validate()}",
                      //                         height: 50,
                      //                         width: 50,
                      //                         fit: BoxFit.cover,
                      //                       ).cornerRadiusWithClipRRect(20),
                      //                       12.width,
                      //                       Column(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment.start,
                      //                         crossAxisAlignment:
                      //                             CrossAxisAlignment.start,
                      //                         children: [
                      //                           TextIconWidget(
                      //                               text: widget
                      //                                       .profileBloc
                      //                                       .postList[index]
                      //                                       .user
                      //                                       ?.name ??
                      //                                   '',
                      //                               suffix: Image.asset(
                      //                                   'images/socialv/icons/ic_TickSquare.png',
                      //                                   height: 14,
                      //                                   width: 14,
                      //                                   fit: BoxFit.cover),
                      //                               textStyle: boldTextStyle()),
                      //                           Row(
                      //                             children: [
                      //                               Text(
                      //                                   timeAgo.format(DateTime
                      //                                       .parse(widget
                      //                                           .profileBloc
                      //                                           .postList[index]
                      //                                           .createdAt!)),
                      //                                   style: secondaryTextStyle(
                      //                                       color:
                      //                                           svGetBodyColor(),
                      //                                       size: 12)),
                      //                               const Padding(
                      //                                 padding: EdgeInsets.only(
                      //                                     left: 8.0),
                      //                                 child: Icon(
                      //                                   Icons.access_time,
                      //                                   size: 20,
                      //                                   color: Colors.grey,
                      //                                 ),
                      //                               )
                      //                             ],
                      //                           ),
                      //                         ],
                      //                       ),
                      //                       // 4.width,
                      //                     ],
                      //                   ).paddingSymmetric(horizontal: 16),
                      //                 ),
                      //                 Row(
                      //                   mainAxisAlignment:
                      //                       MainAxisAlignment.end,
                      //                   children: [
                      //                     if (widget.profileBloc.postList[index]
                      //                             .userId ==
                      //                         AppData.logInUserId)
                      //                       PopupMenuButton(
                      //                         itemBuilder: (context) {
                      //                           return [
                      //                             PopupMenuItem(
                      //                               child: Builder(
                      //                                   builder: (context) {
                      //                                 return Column(
                      //                                   children: ["Delete"]
                      //                                       .map((String item) {
                      //                                     return PopupMenuItem(
                      //                                       value: item,
                      //                                       child: Text(item),
                      //                                     );
                      //                                   }).toList(),
                      //                                 );
                      //                               }),
                      //                             ),
                      //                           ];
                      //                         },
                      //                         onSelected: (value) {
                      //                           if (value == 'Delete') {
                      //                             showDialog(
                      //                               context: context,
                      //                               builder:
                      //                                   (BuildContext context) {
                      //                                 return showAlertDialog(
                      //                                     widget.profileBloc,
                      //                                     context,
                      //                                     widget
                      //                                             .profileBloc
                      //                                             .postList[
                      //                                                 index]
                      //                                             .id ??
                      //                                         0);
                      //                               },
                      //                             );
                      //                           }
                      //                         },
                      //                       )
                      //                     // IconButton(onPressed: () {},
                      //                     //     icon: const Icon(Icons.more_horiz)),
                      //                   ],
                      //                 ),
                      //               ],
                      //             ),
                      //             16.height,
                      //             widget.profileBloc.postList[index].title
                      //                     .validate()
                      //                     .isNotEmpty
                      //                 ? _buildPlaceholderWithoutFile(
                      //                     context,
                      //                     widget.profileBloc.postList[index]
                      //                             .title ??
                      //                         '',
                      //                     widget.profileBloc.postList[index]
                      //                             .backgroundColor ??
                      //                         '#ffff',
                      //                     widget.profileBloc.postList[index]
                      //                         .image,
                      //                     widget.profileBloc.postList[index]
                      //                         .media,
                      //                     index)
                      //                 // ? svRobotoText(
                      //                 // text: homeBloc.postList[index].title.validate(),
                      //                 // textAlign: TextAlign.start).paddingSymmetric(
                      //                 // horizontal: 16)
                      //                 : const Offstage(),
                      //             widget.profileBloc.postList[index].title
                      //                     .validate()
                      //                     .isNotEmpty
                      //                 ? 16.height
                      //                 : const Offstage(),
                      //             _buildMediaContent(context, index)
                      //                 .cornerRadiusWithClipRRect(0)
                      //                 .center(),
                      //             // Image.asset('',
                      //             //   // homeBloc.postList[index].image?.validate(),
                      //             //   height: 300,
                      //             //   width: context.width() - 32,
                      //             //   fit: BoxFit.cover,
                      //             // ).cornerRadiusWithClipRRect(SVAppCommonRadius).center(),
                      //             Padding(
                      //               padding: const EdgeInsets.only(
                      //                   left: 8.0, right: 8.0, top: 8.0),
                      //               child: Row(
                      //                 mainAxisAlignment:
                      //                     MainAxisAlignment.spaceBetween,
                      //                 children: [
                      //                   GestureDetector(
                      //                     onTap: () {
                      //                       LikesListScreen(
                      //                               id: widget.profileBloc
                      //                                       .postList[index].id
                      //                                       .toString() ??
                      //                                   '0')
                      //                           .launch(context);
                      //                     },
                      //                     child: Text(
                      //                         '${widget.profileBloc.postList[index].likes?.length ?? 0.validate()} Likes',
                      //                         style: secondaryTextStyle(
                      //                             color: svGetBodyColor())),
                      //                   ),
                      //                   GestureDetector(
                      //                     onTap: () {
                      //                       SVCommentScreen(
                      //                         id: widget.profileBloc
                      //                                 .postList[index].id ??
                      //                             0,
                      //                         homeBloc: homeBloc,
                      //                       ).launch(context);
                      //                     },
                      //                     child: Text(
                      //                         '${widget.profileBloc.postList[index].comments?.length ?? 0.validate()} comments',
                      //                         style: secondaryTextStyle(
                      //                             color: svGetBodyColor())),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //             const Divider(
                      //               color: Colors.grey,
                      //               thickness: 0.2,
                      //             ),
                      //             Row(
                      //               mainAxisAlignment:
                      //                   MainAxisAlignment.spaceBetween,
                      //               children: [
                      //                 InkWell(
                      //                   splashColor: Colors.transparent,
                      //                   highlightColor: Colors.transparent,
                      //                   onTap: () {
                      //                     print('object');
                      //                     setState(() {});
                      //                     if (findIsLiked(widget.profileBloc
                      //                         .postList[index].likes)) {
                      //                       print('object unlike');
                      //                       widget.profileBloc.postList[index]
                      //                           .likes!
                      //                           .removeWhere((e) =>
                      //                               e.userId ==
                      //                               AppData.logInUserId);
                      //                     } else {
                      //                       widget.profileBloc.postList[index]
                      //                           .likes!
                      //                           .add(Likes(
                      //                               id: index,
                      //                               userId: AppData.logInUserId,
                      //                               postId: widget.profileBloc
                      //                                   .postList[index].id
                      //                                   .toString(),
                      //                               createdAt: '',
                      //                               updatedAt: ''));
                      //                     }
                      //                     homeBloc.add(PostLikeEvent(
                      //                         postId: widget.profileBloc
                      //                                 .postList[index].id ??
                      //                             0));
                      //                   },
                      //                   child: Column(
                      //                     children: [
                      //                       findIsLiked(widget.profileBloc
                      //                               .postList[index].likes)
                      //                           ? Image.asset(
                      //                               'images/socialv/icons/ic_HeartFilled.png',
                      //                               height: 20,
                      //                               width: 22,
                      //                               fit: BoxFit.fill)
                      //                           : Image.asset(
                      //                               'images/socialv/icons/ic_Heart.png',
                      //                               height: 22,
                      //                               width: 22,
                      //                               fit: BoxFit.cover,
                      //                               color: context.iconColor,
                      //                             ),
                      //                       Text('Like',
                      //                           style: secondaryTextStyle(
                      //                               color: svGetBodyColor())),
                      //                     ],
                      //                   ),
                      //                 ),
                      //                 InkWell(
                      //                   splashColor: Colors.transparent,
                      //                   highlightColor: Colors.transparent,
                      //                   onTap: () {
                      //                     setState(() {
                      //                       if (isShowComment == -1) {
                      //                         isShowComment = index;
                      //                       } else {
                      //                         isShowComment = -1;
                      //                       }
                      //                     });
                      //
                      //                     // SVCommentScreen(
                      //                     //         id: widget.profileBloc
                      //                     //                 .postList[index].id ??
                      //                     //             0,homeBloc: homeBloc,)
                      //                     //     .launch(context);
                      //                   },
                      //                   child: Column(
                      //                     children: [
                      //                       Image.asset(
                      //                         'images/socialv/icons/ic_Chat.png',
                      //                         height: 22,
                      //                         width: 22,
                      //                         fit: BoxFit.cover,
                      //                         color: context.iconColor,
                      //                       ),
                      //                       Text('Comment',
                      //                           style: secondaryTextStyle(
                      //                               color: svGetBodyColor())),
                      //                     ],
                      //                   ),
                      //                 ),
                      //                 InkWell(
                      //                   splashColor: Colors.transparent,
                      //                   highlightColor: Colors.transparent,
                      //                   onTap: () {
                      //                     String mediaLink;
                      //                     if (widget.profileBloc.postList[index]
                      //                         .media!.isNotEmpty) {
                      //                       mediaLink = widget
                      //                               .profileBloc
                      //                               .postList[index]
                      //                               .media
                      //                               ?.first
                      //                               .mediaPath ??
                      //                           "";
                      //                     } else {
                      //                       mediaLink = '';
                      //                     }
                      //                     Share.share(
                      //                         '${removeHtmlTags(widget.profileBloc.postList[index].title ?? '')}\n https://doctak.net/post/${widget.profileBloc.postList[index].id} \n'
                      //                         '${AppData.imageUrl}$mediaLink');
                      //                   },
                      //                   child: Column(
                      //                     children: [
                      //                       Icon(
                      //                         Icons.share_sharp,
                      //                         size: 22,
                      //                         // 'images/socialv/icons/ic_share.png',
                      //                         // height: 22,
                      //                         // width: 22,
                      //                         // fit: BoxFit.cover,
                      //                         color: context.iconColor,
                      //                       ),
                      //                       Text('Share',
                      //                           style: secondaryTextStyle(
                      //                               color: svGetBodyColor())),
                      //                     ],
                      //                   ),
                      //                 ),
                      //               ],
                      //             ).paddingSymmetric(
                      //                 horizontal: 16, vertical: 10),
                      //             if (isShowComment == index)
                      //               SVCommentReplyComponent(
                      //                   comment_bloc.CommentBloc(),
                      //                   widget.profileBloc.postList[index].id ??
                      //                       0, (value) {
                      //                 if (value.isNotEmpty) {
                      //                   var comments =
                      //                       comment_bloc.CommentBloc();
                      //                   comments.add(
                      //                       comment_bloc.PostCommentEvent(
                      //                           postId: widget.profileBloc
                      //                                   .postList[index].id ??
                      //                               0,
                      //                           comment: value));
                      //
                      //                   widget.profileBloc.postList[index]
                      //                       .comments!
                      //                       .add(Comments());
                      //                   setState(() {
                      //                     isShowComment = -1;
                      //                   });
                      //                 }
                      //               }),
                      //             Container(
                      //               height: 16,
                      //               color: svGetBgColor(),
                      //             )
                      //           ],
                      //         ),
                      //       );
                    } else {
                      final post = widget.profileBloc.postList[index];

                      return PostItemWidget(
                        profilePicUrl: '${AppData.imageUrl}${post.user?.profilePic}',
                        userName: post.user?.name ?? '',
                        createdAt: timeAgo.format(DateTime.parse(post.createdAt!)),
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
                          SVProfileFragment(userId: post.user?.id).launch(context);
                        },
                        onDeleteTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return CustomAlertDialog(
                                title: 'Are you sure you want to delete this post?',
                                callback: () {
                                  widget.profileBloc.postList.removeWhere((p) => p.id == post.id);
                                  homeBloc.add(DeletePostEvent(postId: post.id));
                                  // Dialog is already closed by CustomAlertDialog
                                },
                              );
                            },
                          );
                        },
                        onLikeTap: () {
                          setState(() {});
                          if (findIsLiked(widget.profileBloc.postList[index].likes)) {
                            print('object unlike');
                            widget.profileBloc.postList[index].likes!.removeWhere((e) => e.userId == AppData.logInUserId);
                          } else {
                            widget.profileBloc.postList[index].likes!.add(
                              Likes(id: index, userId: AppData.logInUserId, postId: widget.profileBloc.postList[index].id.toString(), createdAt: '', updatedAt: ''),
                            );
                          }
                          HomeBloc().add(PostLikeEvent(postId: post.id));
                        },
                        onViewLikesTap: () {
                          LikesListScreen(id: post.id.toString()).launch(context);
                        },
                        onViewCommentsTap: () {
                          SVCommentScreen(homeBloc: homeBloc, id: post.id ?? 0).launch(context);
                        },
                        onShareTap: () {
                          // Share functionality can be added here
                        },
                        onAddComment: (value) {
                          print('object');
                          comment_bloc.CommentBloc().add(comment_bloc.PostCommentEvent(postId: post.id ?? 0, comment: value));
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
                        postData: post,
                      );
                    }
                  },
                );
        } else if (state is DataError) {
          return Expanded(child: Center(child: Text(state.errorMessage)));
        } else {
          return const Expanded(child: Center(child: Text('Something went wrong')));
        }
      },
    );
  }
}
