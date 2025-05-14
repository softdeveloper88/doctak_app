import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/case_discuss_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/case_discussion_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:doctak_app/presentation/notification_screen/user_announcement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:url_launcher/url_launcher.dart';

import '../../localization/app_localization.dart';
import '../../widgets/custom_image_view.dart';
import '../user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'bloc/notification_event.dart';

class NotificationScreen extends StatefulWidget {
  NotificationScreen(this.notificationBloc, {Key? key}) : super(key: key);
  NotificationBloc notificationBloc;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // NotificationBloc widget.notificationBloc = NotificationBloc();
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];
  int selectIndex = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    widget.notificationBloc.add(
      NotificationLoadPageEvent(page: 1, readStatus: ''),
    );

    super.initState();
  }

  // var selectedValue;
  // bool isShownSuggestion = false;
  // bool isSearchShow = true;
  int selectedIndex = 0;

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(translation(context).lbl_notifications,
            style: boldTextStyle(
              size: 20,
            )),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () {
              widget.notificationBloc.add(
                NotificationLoadPageEvent(
                  page: 1,
                ),
              );
              Navigator.pop(context);
            }),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<NotificationBloc, NotificationState>(
              bloc: widget.notificationBloc,
              // listenWhen: (previous, current) => current is PaginationLoadedState,
              // buildWhen: (previous, current) => current is! PaginationLoadedState,
              listener: (BuildContext context, NotificationState state) {
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
                if (state is PaginationLoadingState) {
                  return const UserShimmer();
                } else if (state is PaginationLoadedState) {
                  // print(state.drugsModel.length);
                  return _buildPostList(context);
                } else if (state is DataError) {
                  return Center(
                    child: Text(state.errorMessage),
                  );
                } else {
                  return Center(child: Text(translation(context).msg_notification_error));
                }
              },
            ),
          ),
          if (widget.notificationBloc.totalNotifications > 0)
            MaterialButton(
              onPressed: () {
                if (widget.notificationBloc.totalNotifications > 0) {
                  widget.notificationBloc.add(
                    NotificationLoadPageEvent(page: 1, readStatus: 'mark-read'),
                  );
                }
              },
              minWidth: 100.w,
              color: Colors.blue,
              child: Text(
                translation(context).lbl_mark_all_read,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = widget.notificationBloc;
    if (bloc.notificationsList.isNotEmpty) {
      return ListView.builder(
        itemCount: bloc.notificationsList.length,
        itemBuilder: (context, index) {
          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.notificationsList.length - bloc.nextPageTrigger) {
              bloc.add(NotificationCheckIfNeedMoreDataEvent(index: index));
              print(index);
            }
          }
          if (bloc.numberOfPage != bloc.pageNumber - 1 &&
              index >= bloc.notificationsList.length - 1) {
            return const SizedBox(height: 200, child: UserShimmer());
          } else {
            return Column(
              children: [
                Material(
                  color: bloc.notificationsList[index].isRead == 1
                      ? Colors.white
                      : Colors.blue[50],
                  // color: Theme.of(context).cardColor,
                  elevation: 0,
                  borderRadius: BorderRadius.circular(10),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    title: RichText(
                        text: TextSpan(
                            text:
                                '${bloc.notificationsList[index].senderFirstName ?? ''} ${bloc.notificationsList[index].senderLastName ?? ''} ', // Default style for the initial part
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black, // Default color
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold, // Default font size
                            ),
                            children: [
                          TextSpan(
                            text: bloc.notificationsList[index].text ?? "",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black, // Change color to blue
                            ),
                          ),
                        ])),
                    subtitle: Text(
                      timeAgo.format(DateTime.parse(
                          bloc.notificationsList[index].createdAt ?? "")),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey[600],
                        fontSize: 14.0,
                      ),
                    ),
                    leading: InkWell(
                      onTap: () {
                        SVProfileFragment(
                                userId:
                                    bloc.notificationsList[index].fromUserId)
                            .launch(context);
                      },
                      child: CircleAvatar(
                        child: CustomImageView(
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          radius: BorderRadius.circular(20),
                          imagePath:
                              '${AppData.imageUrl}${bloc.notificationsList[index].senderProfilePic ?? ''}',
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_outlined,
                      color: Colors.grey[600],
                      size: 16.0,
                    ),
                    onTap: () {

                      bloc.add(ReadNotificationEvent(
                          notificationId:
                              bloc.notificationsList[index].id.toString()));
                      bloc.notificationsList[index].isRead = 1;
                      var typeNotification =
                          bloc.notificationsList[index].type;
                      print(typeNotification);
                      if (typeNotification == 'message') {
                        ChatRoomScreen(
                          username:
                              '${bloc.notificationsList[index].senderFirstName ?? ''} ${bloc.notificationsList[index].senderLastName ?? ''}',
                          profilePic:
                              '${bloc.notificationsList[index].senderProfilePic?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                          id: '${bloc.notificationsList[index].userId}',
                          roomId: '',
                        ).launch(context);
                      } else if (typeNotification == 'message_received') {
                        ChatRoomScreen(
                          username:
                              '${bloc.notificationsList[index].senderFirstName ?? ''} ${bloc.notificationsList[index].senderLastName ?? ''}',
                          profilePic:
                              '${bloc.notificationsList[index].senderProfilePic?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                          id: '${bloc.notificationsList[index].fromUserId}',
                          roomId: '',
                        ).launch(context);
                      } else if (typeNotification == 'discuss_case_comment_like') {
                        CaseDiscussionScreen().launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                      } else if (typeNotification == 'follow_request' ||
                          typeNotification == 'friend_request' ||
                          typeNotification == 'follower_notification' ||
                          typeNotification == 'un_follower_notification') {
                        SVProfileFragment(
                                userId:
                                    bloc.notificationsList[index].fromUserId)
                            .launch(context);
                      } else if (typeNotification == 'comments_on_posts' || typeNotification == 'reply_to_comment' ||
                          typeNotification == 'like_comment_on_post' ||
                          typeNotification == 'like_comments') {
                        PostDetailsScreen(
                                commentId: bloc
                                    .notificationsList[index].postId
                                    .toInt())
                            .launch(context);
                        // SVCommentScreen(
                        //   id: bloc.notificationsList[index].postId.toInt(), homeBloc: HomeBloc(),)
                        //     .launch(context);
                      } else if (typeNotification == 'new_like' ||
                          typeNotification == 'like_on_posts' ||
                          typeNotification == 'likes_on_posts' ||
                          typeNotification == 'post_liked') {
                        PostDetailsScreen(
                                postId: bloc.notificationsList[index].postId
                                    .toInt())
                            .launch(context);
                      } else if (typeNotification == 'new_job_posted' ||
                          typeNotification == 'job_post_notification' ||
                          typeNotification == 'job_update') {
                        JobsDetailsScreen(
                                jobId: bloc.notificationsList[index].postId ??
                                    '')
                            .launch(context);
                      }
                      // Add your onTap functionality here
                    },
                  ),
                ),
                const Divider(
                  thickness: 0.2,
                  endIndent: 16,
                  indent: 16,
                  color: Colors.grey,
                )
              ],
            );
          }
        },
      );
    } else {
      return Center(
        child: Text(translation(context).msg_no_notifications),
      );
    }
  }
}
