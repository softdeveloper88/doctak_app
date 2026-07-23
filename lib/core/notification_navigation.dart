import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_detail_screen.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Routes push-notification taps (FCM / local tray) to the correct in-app screen.
class NotificationNavigation {
  NotificationNavigation._();

  static Map<String, dynamic>? _pendingTapData;
  static bool _isOpening = false;

  static void setPendingTap(Map<String, dynamic> data) {
    _pendingTapData = Map<String, dynamic>.from(data);
  }

  static Future<void> consumePendingTap() async {
    final data = _pendingTapData;
    if (data == null) return;
    _pendingTapData = null;
    await openWhenReady(data);
  }

  /// Waits until [NavigatorService] and an auth session are ready, then navigates.
  static Future<void> openWhenReady(
    Map<String, dynamic> rawData, {
    int maxAttempts = 40,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final context = NavigatorService.navigatorKey.currentContext;
      final nav = NavigatorService.navigatorKey.currentState;
      if (context != null && nav != null && nav.mounted) {
        if (_isOpening) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }
        final opened = await open(context, rawData);
        if (opened) return;
        setPendingTap(rawData);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    setPendingTap(rawData);
  }

  static Future<bool> open(BuildContext context, Map<String, dynamic> rawData) async {
    if (_isOpening) return false;
    _isOpening = true;
    try {
      final data = _normalize(rawData);
      _applyLinkHints(data);
      final type = _typeOf(data);

      if (type.isEmpty) {
        debugPrint('NotificationNavigation: missing type in $data');
        return false;
      }

      if (type == 'call') return false;

      final widget = _screenForType(data, type);
      if (widget == null) {
        debugPrint('NotificationNavigation: no route for type=$type data=$data');
        return false;
      }

      await launchScreen(
        context,
        widget,
        pageRouteAnimation: PageRouteAnimation.Slide,
        duration: const Duration(milliseconds: 280),
      );
      return true;
    } catch (e, st) {
      debugPrint('NotificationNavigation.open failed: $e');
      debugPrint('$st');
      return false;
    } finally {
      _isOpening = false;
    }
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value == null) return;
      out[key.toString()] = value;
    });
    return out;
  }

  static String _typeOf(Map<String, dynamic> data) {
    return (data['type'] ?? '').toString().trim().toLowerCase();
  }

  static String? _str(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _int(Map<String, dynamic> data, List<String> keys) {
    final text = _str(data, keys);
    if (text == null) return null;
    return int.tryParse(text);
  }

  static void _applyLinkHints(Map<String, dynamic> data) {
    final link = _str(data, ['link']) ?? '';
    if (link.isEmpty) return;

    final uri = Uri.tryParse(link.startsWith('http') ? link : 'https://doctak.net$link');
    final path = uri?.path ?? link;

    if (path.contains('/post/')) {
      final id = path.split('/post/').last.split('/').first.split('?').first;
      data.putIfAbsent('postId', () => id);
    } else if (path.contains('/chat/')) {
      final id = path.split('/chat/').last.split('/').first.split('?').first;
      data.putIfAbsent('conversationId', () => id);
    } else if (path.contains('/job/') || path.contains('/jobs/')) {
      final segment = path.contains('/jobs/') ? '/jobs/' : '/job/';
      final id = path.split(segment).last.split('/').first.split('?').first;
      data.putIfAbsent('jobId', () => id);
    } else if (path.contains('/profile/')) {
      final id = path.split('/profile/').last.split('/').first.split('?').first;
      data.putIfAbsent('actorUserId', () => id);
    } else if (path.contains('/meetings/live/')) {
      final channel = path.split('/meetings/live/').last.split('/').first.split('?').first;
      data.putIfAbsent('channel', () => channel);
    } else if (path.contains('discuss-case') || path.contains('/case/')) {
      final caseId = uri?.queryParameters['case'] ??
          path.split('/case/').last.split('/').first.split('?').first;
      if (caseId != null && caseId.isNotEmpty) {
        data.putIfAbsent('caseId', () => caseId);
      }
    } else if (path.contains('/groups/')) {
      final groupId = path.split('/groups/').last.split('/').first.split('?').first;
      if (groupId.isNotEmpty) {
        data.putIfAbsent('groupId', () => groupId);
      }
      final invite = uri?.queryParameters['invite'];
      if (invite != null && invite.isNotEmpty) {
        data.putIfAbsent('invitationId', () => invite);
      }
    }
  }

  static Widget? _screenForType(Map<String, dynamic> data, String type) {
    if (_isMessageType(type)) {
      final conversationId = _int(data, ['conversationId', 'conversation_id', 'entityId', 'id']) ?? 0;
      final senderId = _str(data, ['actorUserId', 'senderId', 'sender_id', 'userId', 'user_id']) ?? '';
      // Prefer the explicit senderName the API now sends; `title` may be a
      // generic push title ("New message") rather than the sender's name.
      final username = _str(data, ['senderName', 'sender_name', 'title']) ?? 'Chat';
      final profilePic = AppData.fullImageUrl(_str(data, ['profile_pic', 'image']));
      return ChatRoomScreen(
        id: senderId,
        conversationId: conversationId,
        username: username,
        profilePic: profilePic,
      );
    }

    if (_isProfileType(type)) {
      final userId = _str(data, [
            'actorUserId',
            'senderId',
            'sender_id',
            'from_user_id',
            'userId',
            'user_id',
            'id',
            'entityId',
          ]) ??
          '';
      if (userId.isEmpty) return null;
      return SVProfileFragment(userId: userId);
    }

    if (_isCommentType(type)) {
      // Case comment — caseId wins over postId/commentId.
      final caseId = _int(data, ['caseId', 'case_id']);
      if (caseId != null) return DiscussionDetailScreen(caseId: caseId);

      _applyLinkHints(data);
      final linkedCaseId = _int(data, ['caseId', 'case_id']);
      if (linkedCaseId != null) return DiscussionDetailScreen(caseId: linkedCaseId);

      final commentId = _int(data, ['commentId', 'comment_id', 'entityId', 'id']);
      if (commentId != null) {
        return PostDetailsScreen(commentId: commentId);
      }
      final postId = _int(data, ['postId', 'post_id']);
      if (postId != null) return PostDetailsScreen(postId: postId);
      return null;
    }

    if (_isPostReactionType(type)) {
      final postId = _int(data, ['postId', 'post_id', 'entityId', 'id']);
      if (postId == null) return null;
      return PostDetailsScreen(postId: postId);
    }

    if (_isJobType(type)) {
      final jobId = _str(data, ['jobId', 'job_id', 'entityId', 'id', 'postId', 'post_id']);
      if (jobId == null) return null;
      return JobsDetailsScreen(jobId: jobId);
    }

    if (type == 'conference_invitation' || type == 'conference.invite') {
      return ConferencesScreen();
    }

    if (_isCaseType(type)) {
      final caseId = _int(data, ['caseId', 'case_id', 'entityId', 'id']);
      if (caseId != null) return DiscussionDetailScreen(caseId: caseId);
      return const DiscussionListScreen();
    }

    if (type == 'meeting.invite' || type == 'meeting_invite') {
      final code = _str(data, ['channel', 'meetingId', 'meeting_id', 'entityId', 'id']);
      return ManageMeetingScreen(meetingCode: code, autoJoin: code != null);
    }

    if (type == 'group.invite') {
      final groupId = _str(data, ['groupId', 'entityId', 'id']);
      if (groupId != null) {
        return GroupDetailScreen(
          groupId: groupId,
          pendingInvitationId: _str(data, ['invitationId', 'invite']),
          inviterName: _str(data, ['title', 'actorName']),
        );
      }
      final userId = _str(data, ['actorUserId', 'senderId']);
      if (userId != null) return SVProfileFragment(userId: userId);
      return null;
    }

    return null;
  }

  static bool _isMessageType(String type) {
    return type == 'message' ||
        type == 'message_received' ||
        type == 'message.received' ||
        type.contains('message');
  }

  static bool _isProfileType(String type) {
    return type == 'follow_request' ||
        type == 'friend_request' ||
        type == 'friend_request.sent' ||
        type == 'friend_request.accepted' ||
        type == 'connection_accepted' ||
        type == 'follower_notification' ||
        type == 'un_follower_notification' ||
        type == 'follow.new' ||
        type == 'follow.new_follower';
  }

  static bool _isCommentType(String type) {
    return type == 'comments_on_posts' ||
        type == 'reply_to_comment' ||
        type == 'like_comment_on_post' ||
        type == 'like_comments' ||
        type == 'comment.reply' ||
        type == 'post.commented';
  }

  static bool _isPostReactionType(String type) {
    return type == 'new_like' ||
        type == 'like_on_posts' ||
        type == 'likes_on_posts' ||
        type == 'post_liked' ||
        type == 'post.liked' ||
        type == 'post.reposted' ||
        type == 'mention.created' ||
        type == 'mentions';
  }

  static bool _isJobType(String type) {
    return type == 'new_job_posted' ||
        type == 'job_post_notification' ||
        type == 'job_update' ||
        type == 'job.posted' ||
        type == 'job.suggested';
  }

  static bool _isCaseType(String type) {
    return type == 'new_discuss_case' ||
        type == 'discuss_case_comment' ||
        type == 'case.reply' ||
        type == 'comment.liked' ||
        type.contains('discuss_case');
  }
}
