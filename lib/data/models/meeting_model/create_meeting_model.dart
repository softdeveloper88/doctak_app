import 'dart:convert';

CreateMeetingModel createMeetingModelFromJson(String str) => CreateMeetingModel.fromJson(json.decode(str));
String createMeetingModelToJson(CreateMeetingModel data) => json.encode(data.toJson());

class CreateMeetingModel {
  CreateMeetingModel({this.success, this.data});

  CreateMeetingModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? Meetings.fromJson(json['data']) : null;
  }
  bool? success;
  Meetings? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

Meetings dataFromJson(String str) => Meetings.fromJson(json.decode(str));
String dataToJson(Meetings data) => json.encode(data.toJson());

class Meetings {
  Meetings({this.meeting, this.settings, this.user});

  Meetings.fromJson(dynamic json) {
    meeting = json['meeting'] != null ? Meeting.fromJson(json['meeting']) : null;
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  Meeting? meeting;
  Settings? settings;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (meeting != null) {
      map['meeting'] = meeting?.toJson();
    }
    if (settings != null) {
      map['settings'] = settings?.toJson();
    }
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }
}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());

class User {
  User({this.id, this.name, this.email});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
  }
  String? id;
  String? name;
  String? email;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['email'] = email;
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
    this.requirePassword,
    this.createdAt,
    this.updatedAt,
  });

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
    requirePassword = json['require_password'];
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
  bool? sendReactions;
  bool? toggleMicrophone;
  bool? toggleVideo;
  bool? enableWaitingRoom;
  dynamic requirePassword;
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
    map['require_password'] = requirePassword;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}

Meeting meetingFromJson(String str) => Meeting.fromJson(json.decode(str));
String meetingToJson(Meeting data) => json.encode(data.toJson());

class Meeting {
  Meeting({this.id, this.meetingToken, this.meetingChannel, this.userId, this.isEnded, this.createdAt, this.updatedAt});

  Meeting.fromJson(dynamic json) {
    id = json['id'];
    meetingToken = json['meetingToken'];
    meetingChannel = json['meetingChannel'];
    userId = json['userId'];
    isEnded = json['isEnded'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  String? id;
  String? meetingToken;
  String? meetingChannel;
  String? userId;
  bool? isEnded;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['meetingToken'] = meetingToken;
    map['meetingChannel'] = meetingChannel;
    map['userId'] = userId;
    map['isEnded'] = isEnded;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
