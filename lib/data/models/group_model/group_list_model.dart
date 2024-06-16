import 'dart:convert';
GroupListModel groupListModelFromJson(String str) => GroupListModel.fromJson(json.decode(str));
String groupListModelToJson(GroupListModel data) => json.encode(data.toJson());
class GroupListModel {
  GroupListModel({
      this.groups,});

  GroupListModel.fromJson(dynamic json) {
    if (json['groups'] != null) {
      groups = [];
      json['groups'].forEach((v) {
        groups?.add(Groups.fromJson(v));
      });
    }
  }
  List<Groups>? groups;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (groups != null) {
      map['groups'] = groups?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Groups groupsFromJson(String str) => Groups.fromJson(json.decode(str));
String groupsToJson(Groups data) => json.encode(data.toJson());
class Groups {
  Groups({
      this.id, 
      this.name, 
      this.description, 
      this.specialtyFocus, 
      this.privacySetting, 
      this.logo, 
      this.memberLimit,});

  Groups.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    specialtyFocus = json['specialty_focus'];
    privacySetting = json['privacy_setting'];
    logo = json['logo'];
    memberLimit = json['member_limit'];
  }
  String? id;
  String? name;
  String? description;
  String? specialtyFocus;
  String? privacySetting;
  String? logo;
  String? memberLimit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['specialty_focus'] = specialtyFocus;
    map['privacy_setting'] = privacySetting;
    map['logo'] = logo;
    map['member_limit'] = memberLimit;
    return map;
  }

}