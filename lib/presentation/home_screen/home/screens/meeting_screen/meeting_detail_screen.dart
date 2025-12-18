import 'dart:convert';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';

import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_call_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
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
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(translation(context).lbl_meeting_detail,
                textAlign: TextAlign.center,
                style: boldTextStyle(size: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDetailRow(translation(context).lbl_date, widget.date),
            buildDivider(),
            buildDetailRow(translation(context).lbl_time,  widget.sessions.time),
            buildDivider(),
            buildDetailRow(translation(context).lbl_topic, widget.sessions.title),
            buildDivider(),
            buildDetailRow(translation(context).lbl_meeting_id, widget.sessions.channel),
            buildDivider(),
            const Spacer(),
            // Join Button
            SizedBox(
              width: double.infinity,
              child: svAppButton(
                onTap: () {
                    ProgressDialogUtils.showProgressDialog();
                    askToJoin(context, widget.sessions.channel).then((resp) async {
                      print("join response ${jsonEncode(resp.data)}");
                      Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
                      if(responseData['success']=='1'){
                        await joinMeetings(widget.sessions.channel).then((joinMeetingData) {
                          ProgressDialogUtils.hideProgressDialog();
                          VideoCallScreen(
                            meetingDetailsModel: joinMeetingData,
                            isHost: false,
                          ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                        });
                      }else {
                        ConnectPusher(context,responseData['meeting_id'], widget.sessions.channel);
                      }
                    }).catchError((error) {
                      // Stop the timer when condition is met
                      ProgressDialogUtils.hideProgressDialog();
                      toast(translation(context).msg_something_wrong);
                    });
                  // const HomeScreen1().launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                  // Action for Join button

                },
                text: translation(context).lbl_join, context: context
              ),
            ),
          ],
        ),
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
  Future<dynamic>? onAuthorizer(
      String channelName, String socketId, dynamic options) async {
    print(
        "onAuthorizer called for channel: $channelName, socketId: $socketId");
    
    // For public channels (not starting with 'private-' or 'presence-'),
    // return null
    if (!channelName.startsWith('private-') &&
        !channelName.startsWith('presence-')) {
      return null;
    }
    
    return null;
  }

  void ConnectPusher(context,meetingId,channel) async {
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
          onAuthorizer: onAuthorizer);

      pusher.connect();

      if (pusher != null) {
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
                  VideoCallScreen(
                    meetingDetailsModel: joinMeetingData,
                    isHost: false,
                  ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
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
      } else {
        // Handle the case where Pusher connection failed
        // print("Failed to connect to Pusher");
      }
    } catch (e) {
      print('eee $e');
    }
  }
  Widget buildDetailRow(String title, String value) {
    return Builder(
      builder: (BuildContext context) {
        final textColor = Theme.of(context).textTheme.bodyMedium?.color;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget buildDivider() {
    return const Divider(color: Colors.grey, height: 16);
  }
}
