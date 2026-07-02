import 'dart:convert';

CreateMeetingModel createMeetingModelFromJson(String str) => CreateMeetingModel.fromJson(json.decode(str));
String createMeetingModelToJson(CreateMeetingModel data) => json.encode(data.toJson());

class CreateMeetingModel {
  CreateMeetingModel({this.success, this.data, this.code});

  /// Parses doctak-node response: {success, code, meeting, settings}
  /// Falls back to old Laravel shape: {success, data: {meeting, settings, user}}
  CreateMeetingModel.fromJson(dynamic json) {
    success = json['success'];
    code = json['code']?.toString();
    if (json['data'] != null) {
      data = Meetings.fromJson(json['data']);
    } else if (json['meeting'] != null) {
      data = Meetings.fromJson(json);
    }
  }
  bool? success;
  /// Channel code for the meeting (doctak-node only)
  String? code;
  Meetings? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['code'] = code;
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
    meetingId = (json['meetingId'] ?? json['meeting_id'])?.toString();
    startStopMeeting = (json['startStopMeeting'] ?? json['start_stop_meeting'])?.toString();
    muteAll = (json['muteAll'] ?? json['mute_all'])?.toString();
    unmuteAll = (json['unmuteAll'] ?? json['unmute_all'])?.toString();
    addRemoveHost = (json['addRemoveHost'] ?? json['add_remove_host'])?.toString();
    shareScreen = (json['shareScreen'] ?? json['share_screen'])?.toString();
    raisedHand = (json['raisedHand'] ?? json['raised_hand'])?.toString();
    sendReactions = json['sendReactions'] ?? json['send_reactions'];
    toggleMicrophone = json['toggleMicrophone'] ?? json['toggle_microphone'];
    toggleVideo = json['toggleVideo'] ?? json['toggle_video'];
    enableWaitingRoom = json['enableWaitingRoom'] ?? json['enable_waiting_room'];
    requirePassword = json['requirePassword'] ?? json['require_password'];
    createdAt = (json['createdAt'] ?? json['created_at'])?.toString();
    updatedAt = (json['updatedAt'] ?? json['updated_at'])?.toString();
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
  Meeting({this.id, this.meetingToken, this.meetingChannel, this.userId, this.isEnded, this.createdAt, this.updatedAt, this.name, this.title, this.hostUserId});

  /// Parses both camelCase (doctak-node) and snake_case (Laravel) field names.
  Meeting.fromJson(dynamic json) {
    id = json['id']?.toString();
    // New doctak-node field: 'token' / 'channel'; old: 'meetingToken' / 'meetingChannel'
    meetingToken = (json['token'] ?? json['meetingToken'])?.toString();
    meetingChannel = (json['channel'] ?? json['meetingChannel'])?.toString();
    userId = (json['hostUserId'] ?? json['userId'])?.toString();
    hostUserId = (json['hostUserId'] ?? json['userId'])?.toString();
    name = json['name']?.toString();
    title = json['title']?.toString();
    isEnded = json['isEnded'] == true || json['isEnded'] == 1;
    createdAt = json['createdAt']?.toString() ?? json['created_at']?.toString();
    updatedAt = json['updatedAt']?.toString() ?? json['updated_at']?.toString();
  }
  String? id;
  String? meetingToken;
  String? meetingChannel;
  String? userId;
  String? hostUserId;
  String? name;
  String? title;
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
