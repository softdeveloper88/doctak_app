import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';

MeetingDetailsModel meetingDetailsModelFromJson(String str) => MeetingDetailsModel.fromJson(json.decode(str));
String meetingDetailsModelToJson(MeetingDetailsModel data) => json.encode(data.toJson());

class MeetingDetailsModel {
  MeetingDetailsModel({this.success, this.data, this.message, this.waiting, this.isHost});

  /// Parses doctak-node flat shape: {success, meeting, settings, participant, waiting, isHost}
  /// and old Laravel shape: {success, data: {meeting, settings, users: [...]}}
  MeetingDetailsModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    waiting = json['waiting'];
    isHost = json['isHost'];
    if (json['data'] != null) {
      data = Data.fromJson(json['data']);
    } else if (json['meeting'] != null) {
      data = Data.fromJson(json);
    }
  }
  bool? success;
  Data? data;
  String? message;
  bool? waiting;
  bool? isHost;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['waiting'] = waiting;
    map['isHost'] = isHost;
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
  Data({this.meeting, this.settings, this.users, this.participant});

  /// Accepts both doctak-node flat join response and old Laravel nested shape.
  Data.fromJson(dynamic json) {
    meeting = json['meeting'] != null ? Meeting.fromJson(json['meeting']) : null;
    settings = json['settings'] != null ? Settings.fromJson(json['settings']) : null;
    // doctak-node returns a single `participant` object for the current user
    if (json['participant'] != null) {
      participant = Users.fromParticipant(json['participant']);
    }
    // Prefer 'participants' array (all meeting members) when available
    if (json['participants'] != null) {
      users = [];
      json['participants'].forEach((v) {
        users?.add(Users.fromParticipant(v));
      });
    } else if (json['users'] != null) {
      users = [];
      json['users'].forEach((v) {
        users?.add(Users.fromJson(v));
      });
    } else if (participant != null) {
      users = [participant!];
    }
  }
  Meeting? meeting;
  Settings? settings;
  List<Users>? users;
  Users? participant;

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
  Users({this.id, this.firstName, this.lastName, this.specialty, this.profilePic, this.meetingDetails, this.participantDetail});

  Users.fromJson(dynamic json) {
    id = json['id']?.toString();
    firstName = json['first_name'];
    lastName = json['last_name'];
    specialty = json['specialty'];
    profilePic = AppData.fullImageUrl(json['profile_pic']);
    if (json['meeting_details'] != null) {
      meetingDetails = [];
      json['meeting_details'].forEach((v) {
        meetingDetails?.add(MeetingDetails.fromJson(v));
      });
    }
  }

  /// Construct from doctak-node LiveMeetingParticipant shape.
  Users.fromParticipant(dynamic json) {
    id = json['userId']?.toString();
    firstName = json['userName']?.toString();
    profilePic = AppData.fullImageUrl(json['userAvatar']);
    final detail = MeetingDetails();
    detail.id = json['id']?.toString();
    detail.meetingId = json['meetingId']?.toString();
    detail.userId = json['userId']?.toString();
    detail.joinedAt = json['joinedAt']?.toString();
    detail.isAllowed = json['isAllowed'] == true || json['isAllowed'] == 1 ? '1' : '0';
    detail.isMicOn = (json['isMicOn'] == true || json['isMicOn'] == 1) ? 1 : 0;
    detail.isVideoOn = (json['isVideoOn'] == true || json['isVideoOn'] == 1) ? 1 : 0;
    detail.isScreenShared = (json['isScreenShared'] == true || json['isScreenShared'] == 1) ? 1 : 0;
    detail.isHandUp = (json['isHandUp'] == true || json['isHandUp'] == 1) ? 1 : 0;
    detail.isMeetingLeaved = (json['isMeetingLeaved'] == true || json['isMeetingLeaved'] == 1) ? 1 : 0;
    meetingDetails = [detail];
    participantDetail = detail;
  }

  String? id;
  String? firstName;
  String? lastName;
  String? specialty;
  String? profilePic;
  List<MeetingDetails>? meetingDetails;
  MeetingDetails? participantDetail;

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
    this.isHandUp,
  });

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
    this.updatedAt,
  });

  // Normalize backend payloads: legacy Laravel sends "1"/"0" strings while
  // doctak-node sends real booleans. We canonicalize to "1"/"0" so all the
  // downstream `== '1'` checks keep working without touching every call site.
  static String? _flagToString(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw ? '1' : '0';
    if (raw is num) return raw != 0 ? '1' : '0';
    final s = raw.toString().toLowerCase();
    if (s == 'true' || s == '1') return '1';
    if (s == 'false' || s == '0') return '0';
    return raw.toString();
  }

  Settings.fromJson(dynamic json) {
    id = json['id'];
    meetingId = (json['meetingId'] ?? json['meeting_id'])?.toString();
    startStopMeeting = _flagToString(json['startStopMeeting'] ?? json['start_stop_meeting']);
    muteAll = _flagToString(json['muteAll'] ?? json['mute_all']);
    unmuteAll = _flagToString(json['unmuteAll'] ?? json['unmute_all']);
    addRemoveHost = _flagToString(json['addRemoveHost'] ?? json['add_remove_host']);
    shareScreen = _flagToString(json['shareScreen'] ?? json['share_screen']);
    raisedHand = _flagToString(json['raisedHand'] ?? json['raised_hand']);
    final sr = json['sendReactions'] ?? json['send_reactions'];
    sendReactions = sr == true ? 1 : sr == false ? 0 : sr as int?;
    final tm = json['toggleMicrophone'] ?? json['toggle_microphone'];
    toggleMicrophone = tm == true ? 1 : tm == false ? 0 : tm as int?;
    final tv = json['toggleVideo'] ?? json['toggle_video'];
    toggleVideo = tv == true ? 1 : tv == false ? 0 : tv as int?;
    final ew = json['enableWaitingRoom'] ?? json['enable_waiting_room'];
    enableWaitingRoom = ew == true ? 1 : ew == false ? 0 : ew as int?;
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
  Meeting({this.id, this.meetingToken, this.meetingChannel, this.createdAt, this.updatedAt, this.meetingId, this.userId, this.isEnded});

  Meeting.fromJson(dynamic json) {
    id = json['id'];
    // doctak-node returns 'token'/'channel'; old Laravel returns 'meetingToken'/'meetingChannel'
    meetingToken = (json['token'] ?? json['meetingToken'])?.toString();
    meetingChannel = (json['channel'] ?? json['meetingChannel'])?.toString();
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
