class Participant {
  final String id;
  final String userId;
  final String meetingId;
  final String firstName;
  final String lastName;
  final String? profilePic;
  final bool isAllowed;
  final bool isMicOn;
  final bool isVideoOn;
  final bool isMeetingLeaved;
  final bool isScreenShared;
  final bool isHandUp;
  final bool isHost;
  final bool isSpeaking;

  Participant({
    required this.id,
    required this.userId,
    required this.meetingId,
    required this.firstName,
    required this.lastName,
    this.profilePic,
    required this.isAllowed,
    required this.isMicOn,
    required this.isVideoOn,
    required this.isMeetingLeaved,
    required this.isScreenShared,
    required this.isHandUp,
    required this.isHost,
    this.isSpeaking = false,
  });

  String get fullName => '$firstName $lastName';

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      userId: json['user_id'],
      meetingId: json['meeting_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePic: json['profile_pic'],
      isAllowed: json['is_allowed'] == 1 || json['is_allowed'] == true,
      isMicOn: json['is_mic_on'] == 1 || json['is_mic_on'] == true,
      isVideoOn: json['is_video_on'] == 1 || json['is_video_on'] == true,
      isMeetingLeaved: json['is_meeting_leaved'] == 1 || json['is_meeting_leaved'] == true,
      isScreenShared: json['is_screen_shared'] == 1 || json['is_screen_shared'] == true,
      isHandUp: json['is_hand_up'] == 1 || json['is_hand_up'] == true,
      isHost: json['is_host'] == 1 || json['is_host'] == true,
    );
  }
}