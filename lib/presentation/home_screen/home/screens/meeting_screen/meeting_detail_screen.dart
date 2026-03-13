import 'dart:convert';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';

import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_call_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../../data/models/meeting_model/fetching_meeting_model.dart';
import '../../../../../localization/app_localization.dart';

class MeetingDetailScreen extends StatefulWidget {
  final Session sessions;
  final String date;

  const MeetingDetailScreen({required this.sessions, required this.date, super.key});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  void _joinMeeting() {
    ProgressDialogUtils.showProgressDialog();
    askToJoin(context, widget.sessions.channel)
        .then((resp) async {
          Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
          if (responseData['success'] == '1') {
            await joinMeetings(widget.sessions.channel).then((joinMeetingData) {
              ProgressDialogUtils.hideProgressDialog();
              VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: false).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            });
          } else {
            ConnectPusher(context, responseData['meeting_id'], widget.sessions.channel);
          }
        })
        .catchError((error) {
          ProgressDialogUtils.hideProgressDialog();
          // If the meeting hasn't started yet (404), shows user-friendly message
          final errMsg = error.toString();
          if (errMsg.contains('No query results') || errMsg.contains('404')) {
            showToast('Meeting has not started yet');
          } else {
            showToast(translation(context).msg_something_wrong);
          }
        });
  }

  void _startMeeting() async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final joinMeetingData = await joinMeetings(widget.sessions.channel);
      ProgressDialogUtils.hideProgressDialog();
      VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: true)
          .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      final errMsg = e.toString();
      if (errMsg.contains('No query results') || errMsg.contains('404')) {
        showToast('Meeting has not started yet');
      } else {
        showToast(translation(context).msg_something_wrong);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final meetingDate = widget.date;
    final meetingTime = widget.sessions.time;
    final meetingTitle = widget.sessions.title;
    final meetingChannel = widget.sessions.channel;

    return Scaffold(
      backgroundColor: theme.isDark ? theme.scaffoldBackground : const Color(0xFFF6F6F8),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: theme.isDark ? theme.border : Colors.grey.shade200,
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: DoctakAppBar(
              title: translation(context).lbl_meeting_detail,
              titleIcon: Icons.event_rounded,
              backgroundColor: Colors.transparent,
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meeting title hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primary, theme.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                meetingTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '$meetingDate  •  $meetingTime',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Meeting info card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: theme.isDark
                          ? []
                          : [
                              BoxShadow(
                                color: theme.primary.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          theme,
                          icon: Icons.calendar_today_rounded,
                          label: translation(context).lbl_date,
                          value: meetingDate,
                          iconColor: theme.primary,
                        ),
                        Divider(height: 1, color: theme.surfaceVariant.withValues(alpha: 0.5)),
                        _buildInfoRow(
                          theme,
                          icon: Icons.access_time_rounded,
                          label: translation(context).lbl_time,
                          value: meetingTime,
                          iconColor: theme.warning,
                        ),
                        Divider(height: 1, color: theme.surfaceVariant.withValues(alpha: 0.5)),
                        _buildInfoRow(
                          theme,
                          icon: Icons.topic_rounded,
                          label: translation(context).lbl_topic,
                          value: meetingTitle,
                          iconColor: theme.success,
                        ),
                        Divider(height: 1, color: theme.surfaceVariant.withValues(alpha: 0.5)),
                        _buildInfoRow(
                          theme,
                          icon: Icons.tag_rounded,
                          label: translation(context).lbl_meeting_id,
                          value: meetingChannel,
                          iconColor: theme.secondary,
                          trailing: IconButton(
                            icon: Icon(Icons.copy_rounded, size: 18, color: theme.textSecondary),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: meetingChannel));
                              showToast(translation(context).msg_meeting_code_copied);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: theme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Share the meeting code with others to let them join.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textSecondary,
                              fontFamily: 'Poppins',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Join/Start buttons
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border(
                top: BorderSide(color: theme.isDark ? theme.border : Colors.grey.shade200, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Start Meeting button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _startMeeting,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_outline_rounded, color: theme.primary, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  translation(context).lbl_start_meeting,
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Join Meeting button
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primary, theme.primary.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _joinMeeting,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                translation(context).lbl_join,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    OneUITheme theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTertiary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("onSubscriptionSucceeded: $channelName data: $data");
  }

  void onSubscriptionError(String message, dynamic e) {
    print("onSubscriptionError: $message Exception: $e");
  }

  void onDecryptionFailure(String event, String reason) {
    print("onDecryptionFailure: $event reason: $reason");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print("onMemberRemoved: $channelName member: $member");
  }

  void onError(String message, int? code, dynamic e) {
    print("onError: $message code: $code exception: $e");
  }

  void onSubscriptionCount(String channelName, int subscriptionCount) {}

  // Authorizer method for Pusher - required to prevent iOS crash
  Future<dynamic>? onAuthorizer(String channelName, String socketId, dynamic options) async {
    print("onAuthorizer called for channel: $channelName, socketId: $socketId");

    // For public channels (not starting with 'private-' or 'presence-'),
    // return null
    if (!channelName.startsWith('private-') && !channelName.startsWith('presence-')) {
      return null;
    }

    return null;
  }

  void ConnectPusher(context, meetingId, channel) async {
    // Create the Pusher client
    try {
      await pusher.init(
        apiKey: PusherConfig.key,
        cluster: PusherConfig.cluster,
        useTLS: false,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onSubscriptionError: onSubscriptionError,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        // onEvent: onEvent,
        onDecryptionFailure: onDecryptionFailure,
        onError: onError,
        onSubscriptionCount: onSubscriptionCount,
        onAuthorizer: onAuthorizer,
      );

      pusher.connect();

      // Successfully created and connected to Pusher
      clientListenChannel = await pusher.subscribe(
        channelName: "meeting-channel$meetingId",
        onMemberAdded: (member) {
          // print("Member added: $member");
        },
        onMemberRemoved: (member) {
          print("Member removed: $member");
        },
        onEvent: (event) async {
          String eventName = event.eventName;
          print(eventName);
          switch (eventName) {
            case 'new-user-allowed':
              await joinMeetings(channel).then((joinMeetingData) {
                ProgressDialogUtils.hideProgressDialog();
                VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: false).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
              });
              print("eventName $eventName");
              toast(translation(context).msg_user_allowed);
              break;
            case 'new-user-rejected':
              ProgressDialogUtils.hideProgressDialog();

              print("eventName $eventName");
              toast(translation(context).msg_user_rejected);
              break;
            default:
              // Handle unknown event types or ignore them
              break;
          }
        },
      );

      // Attach an event listener to the channel
    } catch (e) {
      print('eee $e');
    }
  }
}
