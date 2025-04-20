import 'dart:convert';
MeetingDetailsModel meetingDetailsModelFromJson(String str) => MeetingDetailsModel.fromJson(json.decode(str));
String meetingDetailsModelToJson(MeetingDetailsModel data) => json.encode(data.toJson());
class MeetingDetailsModel {
  MeetingDetailsModel({
      this.success, 
      this.data, 
      this.message,});

  MeetingDetailsModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    message = json['message'];
  }
  bool? success;
  Data? data;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['message'] = message;
    return map;
  }

}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.meeting, 
      this.settings, 
      this.users,});

  Data.fromJson(dynamic json) {
    meeting = json['meeting'] != null ? Meeting.fromJson(json['meeting']) : null;
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
    if (json['users'] != null) {
      users = [];
      json['users'].forEach((v) {
        users?.add(Users.fromJson(v));
      });
    }
  }
  Meeting? meeting;
  Settings? settings;
  List<Users>? users;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (meeting != null) {
      map['meeting'] = meeting?.toJson();
    }
    if (settings != null) {
      map['settings'] = settings?.toJson();
    }
    if (users != null) {
      map['users'] = users?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Users usersFromJson(String str) => Users.fromJson(json.decode(str));
String usersToJson(Users data) => json.encode(data.toJson());
class Users {
  Users({
      this.id, 
      this.firstName, 
      this.lastName, 
      this.specialty, 
      this.profilePic, 
      this.meetingDetails,});

  Users.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    specialty = json['specialty'];
    profilePic = json['profile_pic'];
    if (json['meeting_details'] != null) {
      meetingDetails = [];
      json['meeting_details'].forEach((v) {
        meetingDetails?.add(MeetingDetails.fromJson(v));
      });
    }
  }
  String? id;
  String? firstName;
  String? lastName;
  String? specialty;
  String? profilePic;
  List<MeetingDetails>? meetingDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['specialty'] = specialty;
    map['profile_pic'] = profilePic;
    if (meetingDetails != null) {
      map['meeting_details'] = meetingDetails?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

MeetingDetails meetingDetailsFromJson(String str) => MeetingDetails.fromJson(json.decode(str));
String meetingDetailsToJson(MeetingDetails data) => json.encode(data.toJson());
class MeetingDetails {
  MeetingDetails({
      this.id, 
      this.meetingId, 
      this.userId, 
      this.joinedAt, 
      this.isAllowed, 
      this.isMicOn, 
      this.isVideoOn, 
      this.isMeetingLeaved, 
      this.createdAt, 
      this.updatedAt, 
      this.isScreenShared, 
      this.isHandUp,});

  MeetingDetails.fromJson(dynamic json) {
    id = json['id'];
    meetingId = json['meeting_id'];
    userId = json['user_id'];
    joinedAt = json['joined_at'];
    isAllowed = json['is_allowed'];
    isMicOn = json['is_mic_on'];
    isVideoOn = json['is_video_on'];
    isMeetingLeaved = json['is_meeting_leaved'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isScreenShared = json['is_screen_shared'];
    isHandUp = json['is_hand_up'];
  }
  String? id;
  String? meetingId;
  String? userId;
  String? joinedAt;
  String? isAllowed;
  int? isMicOn;
  int? isVideoOn;
  int? isMeetingLeaved;
  String? createdAt;
  String? updatedAt;
  int? isScreenShared;
  int? isHandUp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['meeting_id'] = meetingId;
    map['user_id'] = userId;
    map['joined_at'] = joinedAt;
    map['is_allowed'] = isAllowed;
    map['is_mic_on'] = isMicOn;
    map['is_video_on'] = isVideoOn;
    map['is_meeting_leaved'] = isMeetingLeaved;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['is_screen_shared'] = isScreenShared;
    map['is_hand_up'] = isHandUp;
    return map;
  }

}

Settings settingsFromJson(String str) => Settings.fromJson(json.decode(str));
String settingsToJson(Settings data) => json.encode(data.toJson());
class Settings {
  Settings({
      this.id, 
      this.meetingId, 
      this.startStopMeeting, 
      this.muteAll, 
      this.unmuteAll, 
      this.addRemoveHost, 
      this.shareScreen, 
      this.raisedHand, 
      this.sendReactions, 
      this.toggleMicrophone, 
      this.toggleVideo, 
      this.enableWaitingRoom, 
      this.createdAt, 
      this.updatedAt,});

  Settings.fromJson(dynamic json) {
    id = json['id'];
    meetingId = json['meeting_id'];
    startStopMeeting = json['start_stop_meeting'];
    muteAll = json['mute_all'];
    unmuteAll = json['unmute_all'];
    addRemoveHost = json['add_remove_host'];
    shareScreen = json['share_screen'];
    raisedHand = json['raised_hand'];
    sendReactions = json['send_reactions'];
    toggleMicrophone = json['toggle_microphone'];
    toggleVideo = json['toggle_video'];
    enableWaitingRoom = json['enable_waiting_room'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? meetingId;
  String? startStopMeeting;
  String? muteAll;
  String? unmuteAll;
  String? addRemoveHost;
  String? shareScreen;
  String? raisedHand;
  int? sendReactions;
  int? toggleMicrophone;
  int? toggleVideo;
  int? enableWaitingRoom;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['meeting_id'] = meetingId;
    map['start_stop_meeting'] = startStopMeeting;
    map['mute_all'] = muteAll;
    map['unmute_all'] = unmuteAll;
    map['add_remove_host'] = addRemoveHost;
    map['share_screen'] = shareScreen;
    map['raised_hand'] = raisedHand;
    map['send_reactions'] = sendReactions;
    map['toggle_microphone'] = toggleMicrophone;
    map['toggle_video'] = toggleVideo;
    map['enable_waiting_room'] = enableWaitingRoom;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }

}

Meeting meetingFromJson(String str) => Meeting.fromJson(json.decode(str));
String meetingToJson(Meeting data) => json.encode(data.toJson());
class Meeting {
  Meeting({
      this.id, 
      this.meetingToken, 
      this.meetingChannel, 
      this.createdAt, 
      this.updatedAt, 
      this.meetingId, 
      this.userId, 
      this.isEnded,});

  Meeting.fromJson(dynamic json) {
    id = json['id'];
    meetingToken = json['meetingToken'];
    meetingChannel = json['meetingChannel'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    meetingId = json['meetingId'];
    userId = json['userId'];
    isEnded = json['isEnded'];
  }
  String? id;
  String? meetingToken;
  String? meetingChannel;
  String? createdAt;
  String? updatedAt;
  dynamic meetingId;
  String? userId;
  bool? isEnded;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['meetingToken'] = meetingToken;
    map['meetingChannel'] = meetingChannel;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['meetingId'] = meetingId;
    map['userId'] = userId;
    map['isEnded'] = isEnded;
    return map;
  }

}