import 'dart:convert';

import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_call_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class SetScheduleScreen extends StatefulWidget {
  @override
  _SetScheduleScreenState createState() => _SetScheduleScreenState();
}
class _SetScheduleScreenState extends State<SetScheduleScreen> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController timeZoneController = TextEditingController();

  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        controller.text = pickedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TabBar
          const SizedBox(height: 20),
          // Form Fields
          CustomTextField(
            labelText: "Meeting Topic",
            controller: topicController,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            labelText: "Date",
            controller: dateController,
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: _selectDate,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            labelText: "Time",
            controller: startTimeController,
            icon: Icons.access_time,
            readOnly: true,
            onTap: () => _selectTime(startTimeController),
          ),
          // Row(
          //   children: [
          //     Expanded(
          //       child: CustomTextField(
          //         labelText: "Start from",
          //         controller: startTimeController,
          //         icon: Icons.access_time,
          //         readOnly: true,
          //         onTap: () => _selectTime(startTimeController),
          //       ),
          //     ),
          //     const SizedBox(width: 10),
          //     Expanded(
          //       child: CustomTextField(
          //         labelText: "End",
          //         controller: endTimeController,
          //         icon: Icons.access_time,
          //         readOnly: true,
          //         onTap: () => _selectTime(endTimeController),
          //       ),
          //     ),
          //   ],
          // ),

          const SizedBox(height: 100),
          // Submit Button
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                context: context,
                onTap: () async {
                  if (topicController.text.isEmpty ||
                      dateController.text.isEmpty ||
                      startTimeController.text.isEmpty) {
                    toast('All fields are required');
                    return;
                  }

                  try {
                    final response = await setScheduleMeeting(
                      title: topicController.text,
                      date: dateController.text,
                      time: '${startTimeController.text}',
                    );

                    Map<String, dynamic> responseData =
                        json.decode(jsonEncode(response.data));
                    toast(responseData['message']);

                    // Clear fields after successful submission
                    topicController.clear();
                    dateController.clear();
                    startTimeController.clear();
                    endTimeController.clear();
                  } catch (e) {
                    toast('Error scheduling meeting');
                  }
                },
                text: 'SCHEDULE',
              ),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                context: context,
                onTap: () async {
                  ProgressDialogUtils.showProgressDialog();
                  await startMeetings().then((createMeeting) async {
                    await joinMeetings(
                            createMeeting.data?.meeting?.meetingChannel ?? '')
                        .then((joinMeetingData) {
                      ProgressDialogUtils.hideProgressDialog();
                      VideoCallScreen(
                        meetingDetailsModel: joinMeetingData,
                        isHost: true,
                      ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                    });
                  }).catchError((error){
                   showToast(error);
                  });
                },
                text: 'Create Instant Meeting',
              ),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                context: context,
                onTap: () async {
                  _showJoinDialog(context);
                },
                text: 'Join  Meeting',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void checkJoinStatus(BuildContext context, String channel) {
    ProgressDialogUtils.showProgressDialog();
    askToJoin(context, channel).then((resp) async {
      print("join response ${jsonEncode(resp.data)}");
      Map<String, dynamic> responseData = json.decode(jsonEncode(resp.data));
      if (responseData['success'] == '1') {
        await joinMeetings(channel).then((joinMeetingData) {
          ProgressDialogUtils.hideProgressDialog();
          VideoCallScreen(
            meetingDetailsModel: joinMeetingData,
            isHost: false,
          ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
        });
      } else {
        ConnectPusher(responseData['meeting_id'], channel);
      }
    }).catchError((error) {
      // Stop the timer when condition is met
      ProgressDialogUtils.hideProgressDialog();
      toast("Something went wrong");
    });
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

  void ConnectPusher(meetingId, channel) async {
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
                  ).launch(context,
                      pageRouteAnimation: PageRouteAnimation.Slide);
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

  Future<void> _navigateToCallScreen(
      BuildContext context, String getChannelName) async {
    if (getChannelName.isNotEmpty) {
      checkJoinStatus(context, getChannelName);
    } else {
      ProgressDialogUtils.showProgressDialog();
      await startMeetings().then((createMeeting) async {
        await joinMeetings(createMeeting.data?.meeting?.meetingChannel ?? '')
            .then((joinMeetingData) {
          ProgressDialogUtils.hideProgressDialog();
          VideoCallScreen(
            meetingDetailsModel: joinMeetingData,
            isHost: true,
          ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
        });
      });
    }
  }

  void _showJoinDialog(BuildContext context) {
    TextEditingController channelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Meeting'),
        content: TextField(
          controller: channelController,
          decoration: const InputDecoration(labelText: 'Channel Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (channelController.text.isNotEmpty) {
                setState(() {
                  String channelNames = channelController.text;
                  _navigateToCallScreen(context, channelNames);
                });
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final IconData? icon;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.controller,
    this.icon,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          height: 50,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              filled: false,
              // fillColor: Colors.grey.shade200,
              hintText: labelText,
              suffixIcon: icon != null
                  ? Container(
                      // height: 50,
                      width: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.8),
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8)),
                        color: const Color(0xFFE6E6E6),
                      ),
                      child: Icon(icon))
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
