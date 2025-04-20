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


class MeetingDetailScreen extends StatelessWidget {

  MeetingDetailScreen({required this.sessions,required this.date, super.key});
  Session sessions;
  String date;
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
        title: Expanded(
            child: Text('Meeting Detail',
                textAlign: TextAlign.left,
                style: boldTextStyle(size: 18))),
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
            buildDetailRow("Date", date),
            buildDivider(),
            buildDetailRow("Time",  sessions.time),
            buildDivider(),
            buildDetailRow("Topic", sessions.title),
            buildDivider(),
            buildDetailRow("Meeting ID", sessions.channel),
            buildDivider(),
            const Spacer(),
            // Join Button
            SizedBox(
              width: double.infinity,
              child: svAppButton(
                onTap: () {
                    ProgressDialogUtils.showProgressDialog();
                    askToJoin(context, sessions.channel).then((resp) async {
                      print("join response ${jsonEncode(resp.data)}");
                      Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
                      if(responseData['success']=='1'){
                        await joinMeetings(sessions.channel).then((joinMeetingData) {
                          ProgressDialogUtils.hideProgressDialog();
                          VideoCallScreen(
                            meetingDetailsModel: joinMeetingData,
                            isHost: false,
                          ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                        });
                      }else {
                        ConnectPusher(context,responseData['meeting_id'], sessions.channel);
                      }
                    }).catchError((error) {
                      // Stop the timer when condition is met
                      ProgressDialogUtils.hideProgressDialog();
                      toast("Something went wrong");
                    });
                  // const HomeScreen1().launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                  // Action for Join button

                },
                text: 'Join', context: context
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
          onAuthorizer: null);

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
                toast(eventName);
                break;
              case 'new-user-rejected':
                ProgressDialogUtils.hideProgressDialog();

                print("eventName $eventName");
                toast(eventName);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(color: Colors.grey, height: 16);
  }
}
