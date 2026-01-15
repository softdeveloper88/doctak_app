import 'dart:convert';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';

import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_call_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        surfaceTintColor: theme.scaffoldBackground,
        backgroundColor: theme.scaffoldBackground,
        iconTheme: IconThemeData(color: theme.textPrimary),
        title: Text(
          translation(context).lbl_meeting_detail,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details Card
              Container(
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.isDark ? theme.surfaceVariant : Colors.transparent, width: 1),
                  boxShadow: theme.isDark ? [] : [BoxShadow(color: theme.primary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(theme, translation(context).lbl_date, widget.date),
                      _buildDivider(theme),
                      _buildDetailRow(theme, translation(context).lbl_time, widget.sessions.time),
                      _buildDivider(theme),
                      _buildDetailRow(theme, translation(context).lbl_topic, widget.sessions.title),
                      _buildDivider(theme),
                      _buildDetailRow(theme, translation(context).lbl_meeting_id, widget.sessions.channel),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Join Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ProgressDialogUtils.showProgressDialog();
                        askToJoin(context, widget.sessions.channel)
                            .then((resp) async {
                              print("join response ${jsonEncode(resp.data)}");
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
                              // Stop the timer when condition is met
                              ProgressDialogUtils.hideProgressDialog();
                              toast(translation(context).msg_something_wrong);
                            });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              translation(context).lbl_join,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(OneUITheme theme, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: theme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 16, color: theme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(OneUITheme theme) {
    return Divider(color: theme.surfaceVariant, height: 16);
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
