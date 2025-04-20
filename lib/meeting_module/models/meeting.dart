class Meeting {
  final String id;
  final String meetingToken;
  final String meetingChannel;
  final String userId;
  final bool isEnded;
  final String? meetingName;
  final DateTime createdAt;
  final bool isRecording;

  Meeting({
    required this.id,
    required this.meetingToken,
    required this.meetingChannel,
    required this.userId,
    required this.isEnded,
    this.meetingName,
    required this.createdAt,
    this.isRecording = false,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      meetingToken: json['meetingToken'],
      meetingChannel: json['meetingChannel'],
      userId: json['userId'],
      isEnded: json['isEnded'] == 1 || json['isEnded'] == true,
      meetingName: json['meetingName'],
      createdAt: DateTime.parse(json['created_at']),
      isRecording: json['is_recording'] == 1 || json['is_recording'] == true,
    );
  }
}