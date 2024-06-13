import 'dart:convert';
GroupMemberRequestModel groupMemberRequestModelFromJson(String str) => GroupMemberRequestModel.fromJson(json.decode(str));
String groupMemberRequestModelToJson(GroupMemberRequestModel data) => json.encode(data.toJson());
class GroupMemberRequestModel {
  GroupMemberRequestModel({
      this.groupMembers,});

  GroupMemberRequestModel.fromJson(dynamic json) {
    if (json['group_members'] != null) {
      groupMembers = [];
      json['group_members'].forEach((v) {
        groupMembers?.add(GroupMembers.fromJson(v));
      });
    }
  }
  List<GroupMembers>? groupMembers;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (groupMembers != null) {
      map['group_members'] = groupMembers?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

GroupMembers groupMembersFromJson(String str) => GroupMembers.fromJson(json.decode(str));
String groupMembersToJson(GroupMembers data) => json.encode(data.toJson());
class GroupMembers {
  GroupMembers({
      this.id, 
      this.userId, 
      this.joinedAt, 
      this.adminType, 
      this.name, 
      this.profilePic,});

  GroupMembers.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    joinedAt = json['joined_at'];
    adminType = json['admin_type'];
    name = json['name'];
    profilePic = json['profile_pic'];
  }
  int? id;
  String? userId;
  String? joinedAt;
  String? adminType;
  String? name;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['joined_at'] = joinedAt;
    map['admin_type'] = adminType;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    return map;
  }

}