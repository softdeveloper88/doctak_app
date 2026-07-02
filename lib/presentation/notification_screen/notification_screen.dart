import 'package:doctak_app/core/notification_navigation.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/data/models/notification_model/notification_model.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_state.dart';
import 'package:doctak_app/presentation/notification_screen/notification_screen_widgets.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../localization/app_localization.dart';
import 'bloc/notification_event.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen(this.notificationBloc, {super.key});
  final NotificationBloc notificationBloc;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    final bloc = widget.notificationBloc;
    if (!bloc.hasCompletedInitialLoad) {
      bloc.add(NotificationLoadPageEvent(page: 1, readStatus: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bloc = widget.notificationBloc;
    final unreadCount = bloc.totalNotifications;
    final hasUnread = bloc.notificationsList.any((n) => n.isUnread) || unreadCount > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_notifications,
        titleIcon: Icons.notifications_rounded,
        titleFontWeight: FontWeight.w700,
        centerTitle: false,
        toolbarHeight: 56,
        onBackPressed: () {
          bloc.add(NotificationLoadPageEvent(page: 1));
          Navigator.pop(context);
        },
        actions: hasUnread
            ? [
                TextButton.icon(
                  onPressed: () {
                    bloc.add(NotificationLoadPageEvent(page: 1, readStatus: 'mark-read'));
                    setState(() => selectedFilterIndex = 0);
                  },
                  icon: Icon(Icons.check_circle_outline, size: 18, color: theme.primary),
                  label: Text(
                    translation(context).lbl_mark_all_read,
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Column(
        children: [
          NotificationFilterBar(
              selectedIndex: selectedFilterIndex,
              unreadCount: unreadCount,
              onChanged: (index) {
                if (selectedFilterIndex == index) return;
                setState(() => selectedFilterIndex = index);
                bloc.add(
                  NotificationLoadPageEvent(
                    page: 1,
                    readStatus: index == 1 ? 'unread' : '',
                  ),
                );
              },
            ),
            Expanded(
              child: BlocConsumer<NotificationBloc, NotificationState>(
                bloc: bloc,
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is PaginationLoadingState) {
                    return const NotificationShimmer();
                  }
                  if (state is DataError) {
                    return Center(child: Text(state.errorMessage));
                  }
                  if (state is PaginationLoadedState) {
                    return _buildNotificationList(context, theme, state);
                  }
                  return Center(child: Text(translation(context).msg_notification_error));
                },
              ),
            ),
          if (AppData.isShowGoogleBannerAds ?? false) const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    OneUITheme theme,
    PaginationLoadedState state,
  ) {
    final bloc = widget.notificationBloc;
    final list = bloc.notificationsList;
    final isUnreadFilter = selectedFilterIndex == 1;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnreadFilter
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_outlined,
              size: 52,
              color: theme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              isUnreadFilter
                  ? 'No unread notifications'
                  : translation(context).msg_no_notifications,
              style: theme.bodyMedium.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      );
    }

    final entries = <_NotificationListEntry>[];

    if (isUnreadFilter) {
      // API already scoped to unread rows — show them directly.
      for (final item in list) {
        entries.add(_NotificationListEntry.item(item));
      }
    } else {
      final unreadItems = list.where((n) => n.isUnread).toList();
      final readItems = list.where((n) => !n.isUnread).toList();
      final showEarlier = readItems.isNotEmpty;

      if (unreadItems.isNotEmpty) {
        entries.add(const _NotificationListEntry.header('NEW'));
        for (final item in unreadItems) {
          entries.add(_NotificationListEntry.item(item));
        }
      }
      if (showEarlier) {
        entries.add(const _NotificationListEntry.header('EARLIER'));
        for (final item in readItems) {
          entries.add(_NotificationListEntry.item(item));
        }
      } else if (unreadItems.isEmpty) {
        for (final item in readItems) {
          entries.add(_NotificationListEntry.item(item));
        }
      }
    }

    final showLoadMore = !isUnreadFilter && state.isLoadingMore;
    if (showLoadMore) {
      entries.add(const _NotificationListEntry.loading());
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isHeader) {
          return NotificationSectionHeader(title: entry.headerTitle!);
        }
        if (entry.isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primary,
                ),
              ),
            ),
          );
        }
        final notification = entry.notification!;
        final listIndex = list.indexOf(notification);
        if (listIndex >= 0) {
          _maybeLoadMore(bloc, listIndex);
        }
        return _buildTile(context, notification);
      },
    );
  }

  void _maybeLoadMore(NotificationBloc bloc, int index) {
    if (selectedFilterIndex != 0) return;
    if (bloc.isLoadingMore) return;
    if (bloc.pageNumber > bloc.numberOfPage) return;
    if (index == bloc.notificationsList.length - bloc.nextPageTrigger) {
      bloc.add(NotificationCheckIfNeedMoreDataEvent(index: index));
    }
  }

  Widget _buildTile(BuildContext context, Data notification) {
    final bloc = widget.notificationBloc;
    final isConnection =
        notification.isUnread && notification.showConnectionActions == true;

    return NotificationListTile(
      notification: notification,
      timeLabel: _formatNotificationTime(notification.createdAt),
      onTap: () => _onNotificationTap(context, notification),
      onAvatarTap: notification.fromUserId != null
          ? () => ProfileNavigation.openUser(context, notification.fromUserId)
          : null,
      onAccept: isConnection
          ? () => bloc.add(
                AcceptConnectionRequestEvent(
                  notificationId: notification.id ?? 0,
                  requestId: notification.friendRequestId,
                  fromUserId: notification.fromUserId,
                ),
              )
          : null,
      onDecline: isConnection
          ? () => bloc.add(
                DeclineConnectionRequestEvent(
                  notificationId: notification.id ?? 0,
                  requestId: notification.friendRequestId,
                  fromUserId: notification.fromUserId,
                ),
              )
          : null,
    );
  }

  Future<void> _onNotificationTap(BuildContext context, Data notification) async {
    final bloc = widget.notificationBloc;
    bloc.add(ReadNotificationEvent(notificationId: notification.id.toString()));
    notification.isRead = 1;

    await NotificationNavigation.open(context, notification.toNavigationMap());
  }

}

class _NotificationListEntry {
  final String? headerTitle;
  final Data? notification;
  final bool isLoading;

  const _NotificationListEntry.header(this.headerTitle)
      : notification = null,
        isLoading = false;

  const _NotificationListEntry.item(this.notification)
      : headerTitle = null,
        isLoading = false;

  const _NotificationListEntry.loading()
      : headerTitle = null,
        notification = null,
        isLoading = true;

  bool get isHeader => headerTitle != null;
}

extension on _NotificationScreenState {
  String _formatNotificationTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return '';
    return timeAgo.format(parsed);
  }
}
