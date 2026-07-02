import 'dart:convert';

import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_call_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/meeting_waiting_room_controller.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SetScheduleScreen extends StatefulWidget {
  const SetScheduleScreen({super.key});

  @override
  _SetScheduleScreenState createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController timeZoneController = TextEditingController();
  final MeetingWaitingRoomController _waitingRoom = MeetingWaitingRoomController();

  @override
  void dispose() {
    topicController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    timeZoneController.dispose();
    _waitingRoom.dispose();
    super.dispose();
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (pickedDate != null) {
      setState(() {
        dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
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
          CustomTextField(labelText: translation(context).lbl_meeting_topic, controller: topicController),
          const SizedBox(height: 20),
          CustomTextField(labelText: translation(context).lbl_date, controller: dateController, icon: Icons.calendar_today, readOnly: true, onTap: _selectDate),
          const SizedBox(height: 20),
          CustomTextField(labelText: translation(context).lbl_time, controller: startTimeController, icon: Icons.access_time, readOnly: true, onTap: () => _selectTime(startTimeController)),

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
                  if (topicController.text.isEmpty || dateController.text.isEmpty || startTimeController.text.isEmpty) {
                    toast(translation(context).msg_all_fields_required);
                    return;
                  }

                  try {
                    final response = await setScheduleMeeting(title: topicController.text, date: dateController.text, time: startTimeController.text);

                    Map<String, dynamic> responseData = json.decode(jsonEncode(response.data));
                    toast(responseData['message']);

                    // Clear fields after successful submission
                    topicController.clear();
                    dateController.clear();
                    startTimeController.clear();
                    endTimeController.clear();
                  } catch (e) {
                    toast(translation(context).msg_error_scheduling_meeting);
                  }
                },
                text: translation(context).lbl_schedule,
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
                  await startMeetings()
                      .then((createMeeting) async {
                        await joinMeetings(createMeeting.data?.meeting?.meetingChannel ?? '').then((joinMeetingData) {
                          ProgressDialogUtils.hideProgressDialog();
                          VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: true).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                        });
                      })
                      .catchError((error) {
                        showToast(error);
                      });
                },
                text: translation(context).lbl_create_instant_meeting,
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
                text: translation(context).lbl_join_meeting,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void checkJoinStatus(BuildContext context, String channel) {
    ProgressDialogUtils.showProgressDialog();
    askToJoin(context, channel)
        .then((resp) async {
          Map<String, dynamic> responseData =
              json.decode(jsonEncode(resp.data));
          final isSuccess = responseData['success'] == true ||
              responseData['success'] == '1';
          final isWaiting = responseData['waiting'] == true ||
              responseData['status']?.toString() == 'waiting_room';

          if (isSuccess && !isWaiting) {
            await joinMeetings(channel).then((joinMeetingData) {
              ProgressDialogUtils.hideProgressDialog();
              VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: false)
                  .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
            });
          } else if (isSuccess && isWaiting) {
            final meetingId =
                (responseData['meeting'] as Map?)?['id']?.toString() ??
                responseData['meeting_id']?.toString() ??
                '';
            _waitingRoom.connect(
              context: context,
              meetingId: meetingId,
              channel: channel,
              onApproved: () async {
                final joinMeetingData = await joinMeetings(channel);
                if (!mounted) return;
                ProgressDialogUtils.hideProgressDialog();
                VideoCallScreen(
                  meetingDetailsModel: joinMeetingData,
                  isHost: false,
                ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
              },
              onRejected: () {
                if (!mounted) return;
                toast('Join request rejected');
              },
            );
          } else {
            ProgressDialogUtils.hideProgressDialog();
            toast(responseData['message']?.toString() ??
                translation(context).msg_something_wrong);
          }
        })
        .catchError((error) {
          ProgressDialogUtils.hideProgressDialog();
          toast(translation(context).msg_something_went_wrong);
        });
  }

  Future<void> _navigateToCallScreen(BuildContext context, String getChannelName) async {
    if (getChannelName.isNotEmpty) {
      checkJoinStatus(context, getChannelName);
    } else {
      ProgressDialogUtils.showProgressDialog();
      await startMeetings().then((createMeeting) async {
        await joinMeetings(createMeeting.data?.meeting?.meetingChannel ?? '').then((joinMeetingData) {
          ProgressDialogUtils.hideProgressDialog();
          VideoCallScreen(meetingDetailsModel: joinMeetingData, isHost: true).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
        });
      });
    }
  }

  void _showJoinDialog(BuildContext context) {
    TextEditingController channelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context).lbl_join_meeting),
        content: TextField(
          controller: channelController,
          decoration: InputDecoration(labelText: translation(context).lbl_channel_name),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context).lbl_cancel)),
          TextButton(
            onPressed: () {
              if (channelController.text.isNotEmpty) {
                setState(() {
                  String channelNames = channelController.text;
                  _navigateToCallScreen(context, channelNames);
                });
              }
            },
            child: Text(translation(context).lbl_join),
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

  const CustomTextField({super.key, required this.labelText, required this.controller, this.icon, this.readOnly = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                        color: const Color(0xFFE6E6E6),
                      ),
                      child: Icon(icon),
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
