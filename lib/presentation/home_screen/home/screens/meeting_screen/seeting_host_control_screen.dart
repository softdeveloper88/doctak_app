import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:flutter/material.dart';

class SettingsHostControlsScreen extends StatefulWidget {
  SettingsHostControlsScreen(this.settings,this.meetingId, {super.key});

  Settings? settings;
  String? meetingId;
  @override
  _SettingsHostControlsScreenState createState() =>
      _SettingsHostControlsScreenState();
}

class _SettingsHostControlsScreenState
    extends State<SettingsHostControlsScreen> {
  bool startStopMeeting = true;
  bool muteAll = true;
  bool unMuteAll = true;
  bool addRemoveHost = true;
  bool shareScreen = true;
  bool raiseHand = true;
  bool sendReactions = true;
  bool turnOnOffMicrophone = true;
  bool turnOnOffVideo = true;
  bool enableWaitingRoom = true;

  Widget buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      activeColor: Colors.blue,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      value: value,
      inactiveTrackColor: Colors.blue,
      inactiveThumbColor: Colors.blue,
      thumbColor: MaterialStateProperty.all(Colors.white),
      onChanged: (newValue) {
        setState(() {
          onChanged(newValue);
        });
      },
    );
  }

  @override
  void initState() {
    setState(() {
      widget.settings?.startStopMeeting == '1';
      muteAll = widget.settings?.muteAll == '1';
      unMuteAll = widget.settings?.unmuteAll == '1';
      addRemoveHost = widget.settings?.addRemoveHost == '1';
      shareScreen = widget.settings?.shareScreen == '1';
      raiseHand = widget.settings?.raisedHand == '1';
      sendReactions = widget.settings?.sendReactions == 1;
      turnOnOffMicrophone = widget.settings?.toggleMicrophone == 1;
      turnOnOffVideo = widget.settings?.toggleVideo == 1;
      enableWaitingRoom = widget.settings?.enableWaitingRoom == 1;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context,true),
        ),
        title: Text(
          translation(context).lbl_settings_host_controls,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(translation(context).lbl_host_management),
          _buildDescription(
              translation(context).desc_host_management),
          buildSwitchTile(translation(context).lbl_start_stop_meeting, startStopMeeting, (val) async {
            startStopMeeting = val;
            await updateMeetingSetting(
               meetingId:  widget.meetingId,
               startStopMeeting: startStopMeeting?'1':'0',
               addRemoveHost: addRemoveHost?'1':'0',
              shareScreen: shareScreen?'1':'0',
              raisedHand: raiseHand?'1':'0',
              sendReactions: sendReactions?'1':'0',
              toggleMicrophone: turnOnOffMicrophone?'1':'0',
              toggleVideo: turnOnOffVideo?'1':'0',
              enableWaitingRoom: enableWaitingRoom?'1':'0',

            ).then((response){
              print(response);
            });
          }),
          buildSwitchTile(translation(context).lbl_add_remove_host, addRemoveHost, (val) async {
            addRemoveHost = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',

            ).then((response){
              print(response);
            });
          }),
          // buildSwitchTile("All Mute", muteAll, (val) {
          //   muteAll = val;
          //
          // }),
          const Divider(),
          _buildSectionTitle(translation(context).lbl_participant_controls),
          _buildDescription(
              translation(context).desc_participant_controls),
          buildSwitchTile(translation(context).lbl_share_screen, shareScreen, (val) async {
            shareScreen = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',
                requirePassword: '0'

            ).then((response){
              print(response);
            });
          }),
          buildSwitchTile(translation(context).lbl_raise_hand, raiseHand, (val) async {
            raiseHand = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',
                requirePassword: '0'

            ).then((response){
              print(response);
            });
          }),
          buildSwitchTile(translation(context).lbl_send_reactions, sendReactions, (val) async {
            sendReactions = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',
                requirePassword: '0'

            ).then((response){
              print(response);
            });
          }),
          buildSwitchTile(translation(context).lbl_toggle_microphone, turnOnOffMicrophone, (val) async {
            turnOnOffMicrophone = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',
                requirePassword: '0'

            ).then((response){
              print(response);
            });
          }),
          buildSwitchTile(translation(context).lbl_toggle_video, turnOnOffVideo, (val) async {
            turnOnOffVideo = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',
                requirePassword: '0'

            ).then((response){
              print(response);
            });
          }),
          const Divider(),
          _buildSectionTitle(translation(context).lbl_meeting_privacy_settings),
          _buildDescription(
              translation(context).desc_meeting_privacy_settings),
          buildSwitchTile(translation(context).lbl_enable_waiting_room, enableWaitingRoom, (val) async {
            enableWaitingRoom = val;
            await updateMeetingSetting(
            meetingId:  widget.meetingId,
            startStopMeeting: startStopMeeting?'1':'0',
            addRemoveHost: addRemoveHost?'1':'0',
            shareScreen: shareScreen?'1':'0',
            raisedHand: raiseHand?'1':'0',
            sendReactions: sendReactions?'1':'0',
            toggleMicrophone: turnOnOffMicrophone?'1':'0',
            toggleVideo: turnOnOffVideo?'1':'0',
            enableWaitingRoom: enableWaitingRoom?'1':'0',
                requirePassword: '0'

            ).then((response){
              print(response);
            });
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        description,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }
}
// 'start_stop_meetingCheckbox' => 'start_stop_meeting',
// 'addRemoveHostCheckbox' => 'add_remove_host',
// 'shareScreenCheckbox' => 'share_screen',
// 'raiseHandCheckbox' => 'raised_hand',
// 'sendReactionsCheckbox' => 'send_reactions',
// 'toggleMicCheckbox' => 'toggle_microphone',
// 'toggleVideoCheckbox' => 'toggle_video',
// 'enableWaitingRoomCheckbox' => 'enable_waiting_room',
// 'requirePasswordCheckbox' => 'require_password'
