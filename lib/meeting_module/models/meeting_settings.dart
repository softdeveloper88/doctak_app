class MeetingSettings {
  final String id;
  final String meetingId;
  final bool startStopMeeting;
  final bool muteAll;
  final bool unmuteAll;
  final bool addRemoveHost;
  final bool shareScreen;
  final bool raisedHand;
  final bool sendReactions;
  final bool toggleMicrophone;
  final bool toggleVideo;
  final bool enableWaitingRoom;
  final bool requirePassword;

  MeetingSettings({
    required this.id,
    required this.meetingId,
    required this.startStopMeeting,
    required this.muteAll,
    required this.unmuteAll,
    required this.addRemoveHost,
    required this.shareScreen,
    required this.raisedHand,
    required this.sendReactions,
    required this.toggleMicrophone,
    required this.toggleVideo,
    required this.enableWaitingRoom,
    required this.requirePassword,
  });

  factory MeetingSettings.fromJson(Map<String, dynamic> json) {
    return MeetingSettings(
      id: json['id'],
      meetingId: json['meeting_id'],
      startStopMeeting: json['start_stop_meeting'] == 1 || json['start_stop_meeting'] == true,
      muteAll: json['mute_all'] == 1 || json['mute_all'] == true,
      unmuteAll: json['unmute_all'] == 1 || json['unmute_all'] == true,
      addRemoveHost: json['add_remove_host'] == 1 || json['add_remove_host'] == true,
      shareScreen: json['share_screen'] == 1 || json['share_screen'] == true,
      raisedHand: json['raised_hand'] == 1 || json['raised_hand'] == true,
      sendReactions: json['send_reactions'] == 1 || json['send_reactions'] == true,
      toggleMicrophone: json['toggle_microphone'] == 1 || json['toggle_microphone'] == true,
      toggleVideo: json['toggle_video'] == 1 || json['toggle_video'] == true,
      enableWaitingRoom: json['enable_waiting_room'] == 1 || json['enable_waiting_room'] == true,
      requirePassword: json['require_password'] == 1 || json['require_password'] == true,
    );
  }
}