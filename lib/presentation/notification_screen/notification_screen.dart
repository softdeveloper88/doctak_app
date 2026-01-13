import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../localization/app_localization.dart';
import '../../widgets/custom_image_view.dart';
import '../user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'bloc/notification_event.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen(this.notificationBloc, {Key? key}) : super(key: key);
  final NotificationBloc notificationBloc;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isFilterShow = false;
  int selectedFilterIndex = 0; // 0 for All, 1 for Unread

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    widget.notificationBloc.add(
      NotificationLoadPageEvent(page: 1, readStatus: ''),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_notifications,
        titleIcon: Icons.notifications_rounded,
        onBackPressed: () {
          widget.notificationBloc.add(NotificationLoadPageEvent(page: 1));
          Navigator.pop(context);
        },
        actions: [
          // Filter icon button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: theme.primary,
                size: 14,
              ),
            ),
            onPressed: () {
              setState(() {
                isFilterShow = !isFilterShow;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter toggle buttons
          Container(
            color: theme.scaffoldBackground,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isFilterShow ? 66 : 0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: isFilterShow
                    ? Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFilterIndex = 0;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedFilterIndex == 0
                                        ? theme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (selectedFilterIndex == 0)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.all_inclusive,
                                              size: 14,
                                              color: theme.primary,
                                            ),
                                          ),
                                        Text(
                                          'All',
                                          style: TextStyle(
                                            color: selectedFilterIndex == 0
                                                ? Colors.white
                                                : theme.textSecondary,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFilterIndex = 1;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedFilterIndex == 1
                                        ? theme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (selectedFilterIndex == 1)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.mark_email_unread,
                                              size: 14,
                                              color: theme.primary,
                                            ),
                                          ),
                                        Text(
                                          'Unread',
                                          style: TextStyle(
                                            color: selectedFilterIndex == 1
                                                ? Colors.white
                                                : theme.textSecondary,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ),
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
                  return const NotificationShimmer();
                } else if (state is PaginationLoadedState) {
                  // print(state.drugsModel.length);
                  return _buildPostList(context);
                } else if (state is DataError) {
                  return Center(child: Text(state.errorMessage));
                } else {
                  return Center(
                    child: Text(translation(context).msg_notification_error),
                  );
                }
              },
            ),
          ),
          if (widget.notificationBloc.totalNotifications > 0 &&
              widget.notificationBloc.notificationsList.any(
                (n) => n.isRead != 1,
              ))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.isDark ? 0.3 : 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.notificationBloc.totalNotifications > 0) {
                    widget.notificationBloc.add(
                      NotificationLoadPageEvent(
                        page: 1,
                        readStatus: 'mark-read',
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.done_all, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      translation(context).lbl_mark_all_read,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bloc = widget.notificationBloc;
    if (bloc.notificationsList.isNotEmpty) {
      // Filter notifications based on selectedFilterIndex
      final filteredList = selectedFilterIndex == 0
          ? bloc.notificationsList
          : bloc.notificationsList
                .where((notification) => notification.isRead != 1)
                .toList();

      if (filteredList.isEmpty && selectedFilterIndex == 1) {
        // Show empty state for unread filter when no unread notifications
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read,
                  size: 48,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No unread notifications',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final notification = filteredList[index];
          final originalIndex = bloc.notificationsList.indexOf(notification);

          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (originalIndex ==
                bloc.notificationsList.length - bloc.nextPageTrigger) {
              bloc.add(
                NotificationCheckIfNeedMoreDataEvent(index: originalIndex),
              );
            }
          }
          if (bloc.numberOfPage != bloc.pageNumber - 1 &&
              index >= filteredList.length - 1 &&
              selectedFilterIndex == 0) {
            return const SizedBox(height: 200, child: NotificationShimmer());
          } else {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: notification.isRead == 1
                    ? theme.cardBackground
                    : theme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notification.isRead == 1
                      ? theme.divider
                      : theme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(theme.isDark ? 0.2 : 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    bloc.add(
                      ReadNotificationEvent(
                        notificationId: notification.id.toString(),
                      ),
                    );
                    notification.isRead = 1;
                    var typeNotification = notification.type;
                    if (typeNotification == 'message') {
                      ChatRoomScreen(
                        username:
                            '${notification.senderFirstName ?? ''} ${notification.senderLastName ?? ''}',
                        profilePic:
                            '${notification.senderProfilePic?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                        id: '${notification.userId}',
                        roomId: '',
                      ).launch(context);
                    } else if (typeNotification == 'message_received') {
                      ChatRoomScreen(
                        username:
                            '${notification.senderFirstName ?? ''} ${notification.senderLastName ?? ''}',
                        profilePic:
                            '${notification.senderProfilePic?.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '')}',
                        id: '${notification.fromUserId}',
                        roomId: '',
                      ).launch(context);
                    } else if (typeNotification ==
                        'discuss_case_comment_like') {
                      // CaseDiscussion().launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                    } else if (typeNotification == 'follow_request' ||
                        typeNotification == 'friend_request' ||
                        typeNotification == 'follower_notification' ||
                        typeNotification == 'un_follower_notification') {
                      SVProfileFragment(
                        userId: notification.fromUserId,
                      ).launch(context);
                    } else if (typeNotification == 'comments_on_posts' ||
                        typeNotification == 'reply_to_comment' ||
                        typeNotification == 'like_comment_on_post' ||
                        typeNotification == 'like_comments') {
                      PostDetailsScreen(
                        commentId: notification.postId.toInt(),
                      ).launch(context);
                      // SVCommentScreen(
                      //   id: notification.postId.toInt(), homeBloc: HomeBloc(),)
                      //     .launch(context);
                    } else if (typeNotification == 'new_like' ||
                        typeNotification == 'like_on_posts' ||
                        typeNotification == 'likes_on_posts' ||
                        typeNotification == 'post_liked') {
                      PostDetailsScreen(
                        postId: notification.postId.toInt(),
                      ).launch(context);
                    } else if (typeNotification == 'new_job_posted' ||
                        typeNotification == 'job_post_notification' ||
                        typeNotification == 'job_update') {
                      JobsDetailsScreen(
                        jobId: notification.postId ?? '',
                      ).launch(context);
                    }
                    // Add your onTap functionality here
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Avatar with notification type indicator
                        Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                SVProfileFragment(
                                  userId: notification.fromUserId,
                                ).launch(context);
                              },
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: CustomImageView(
                                    fit: BoxFit.cover,
                                    width: 50,
                                    height: 50,
                                    imagePath:
                                        '${AppData.imageUrl}${notification.senderProfilePic ?? ''}',
                                  ),
                                ),
                              ),
                            ),
                            // Notification type indicator
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(
                                    notification.type,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getNotificationIcon(notification.type),
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              RichText(
                                text: TextSpan(
                                  text:
                                      '${notification.senderFirstName ?? ''} ${notification.senderLastName ?? ''} ',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: theme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: notification.text ?? "",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Time
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: theme.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeAgo.format(
                                      DateTime.parse(
                                        notification.createdAt ?? "",
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: theme.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.primary,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              translation(context).msg_no_notifications,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'message':
      case 'message_received':
        return Colors.green;
      case 'new_like':
      case 'like_on_posts':
      case 'likes_on_posts':
      case 'post_liked':
        return Colors.red;
      case 'comments_on_posts':
      case 'reply_to_comment':
      case 'like_comment_on_post':
      case 'like_comments':
        return Colors.blue;
      case 'follow_request':
      case 'friend_request':
      case 'follower_notification':
      case 'un_follower_notification':
        return Colors.purple;
      case 'new_job_posted':
      case 'job_post_notification':
      case 'job_update':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'message':
      case 'message_received':
        return Icons.message;
      case 'new_like':
      case 'like_on_posts':
      case 'likes_on_posts':
      case 'post_liked':
        return Icons.favorite;
      case 'comments_on_posts':
      case 'reply_to_comment':
      case 'like_comment_on_post':
      case 'like_comments':
        return Icons.comment;
      case 'follow_request':
      case 'friend_request':
      case 'follower_notification':
      case 'un_follower_notification':
        return Icons.person_add;
      case 'new_job_posted':
      case 'job_post_notification':
      case 'job_update':
        return Icons.work;
      default:
        return Icons.notifications;
    }
  }
}
