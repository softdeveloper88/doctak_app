import 'dart:convert';

GroupAboutModel groupAboutModelFromJson(String str) => GroupAboutModel.fromJson(json.decode(str));
String groupAboutModelToJson(GroupAboutModel data) => json.encode(data.toJson());

class GroupAboutModel {
  GroupAboutModel({this.group});

  GroupAboutModel.fromJson(dynamic json) {
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
  }
  Group? group;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (group != null) {
      map['group'] = group?.toJson();
    }
    return map;
  }
}

Group groupFromJson(String str) => Group.fromJson(json.decode(str));
String groupToJson(Group data) => json.encode(data.toJson());

class Group {
  Group({
    this.id,
    this.name,
    this.description,
    this.specialtyFocus,
    this.privacySetting,
    this.tags,
    this.location,
    this.interest,
    this.rules,
    this.joinRequest,
    this.status,
    this.language,
    this.visibility,
  });

  Group.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    specialtyFocus = json['specialty_focus'];
    privacySetting = json['privacy_setting'];
    tags = json['tags'];
    location = json['location'];
    interest = json['interest'];
    rules = json['rules'];
    joinRequest = json['join_request'];
    status = json['status'];
    language = json['language'];
    visibility = json['visibility'];
  }
  String? id;
  String? name;
  String? description;
  String? specialtyFocus;
  String? privacySetting;
  String? tags;
  String? location;
  String? interest;
  String? rules;
  String? joinRequest;
  String? status;
  String? language;
  String? visibility;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['specialty_focus'] = specialtyFocus;
    map['privacy_setting'] = privacySetting;
    map['tags'] = tags;
    map['location'] = location;
    map['interest'] = interest;
    map['rules'] = rules;
    map['join_request'] = joinRequest;
    map['status'] = status;
    map['language'] = language;
    map['visibility'] = visibility;
    return map;
  }
}
