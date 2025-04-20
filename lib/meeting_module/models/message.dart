class Message {
  final String id;
  final String meetingId;
  final String userId;
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;
  final String? userName;
  final String? userProfilePic;

  Message({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
    this.userName,
    this.userProfilePic,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      meetingId: json['meeting_id'],
      userId: json['user_id'],
      message: json['message'],
      attachmentUrl: json['attachment_url'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['name'] ?? json['user_name'],
      userProfilePic: json['profile_pic'],
    );
  }
}