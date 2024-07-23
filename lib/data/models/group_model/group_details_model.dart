import 'dart:convert';

GroupDetailsModel groupDetailsModelFromJson(String str) =>
    GroupDetailsModel.fromJson(json.decode(str));
String groupDetailsModelToJson(GroupDetailsModel data) =>
    json.encode(data.toJson());

class GroupDetailsModel {
  GroupDetailsModel({
    this.group,
    this.groupStatus,
    this.groupMembers,
    this.totalMembers,
    this.membersRequest,
    this.postsRequest,
    this.isAdmin,
  });

  GroupDetailsModel.fromJson(dynamic json) {
    group = json['group'] != null ? Group.fromJson(json['group']) : null;
    groupStatus = json['group_status'] != null
        ? GroupStatus.fromJson(json['group_status'])
        : null;
    if (json['group_members'] != null) {
      groupMembers = [];
      json['group_members'].forEach((v) {
        groupMembers?.add(GroupMembers.fromJson(v));
      });
    }
    totalMembers = json['total_members'];
    membersRequest = json['members_request'];
    postsRequest = json['posts_request'];
    isAdmin = json['isAdmin'];
  }
  Group? group;
  GroupStatus? groupStatus;
  List<GroupMembers>? groupMembers;
  int? totalMembers;
  int? membersRequest;
  int? postsRequest;
  dynamic isAdmin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (group != null) {
      map['group'] = group?.toJson();
    }
    if (groupStatus != null) {
      map['group_status'] = groupStatus?.toJson();
    }
    if (groupMembers != null) {
      map['group_members'] = groupMembers?.map((v) => v.toJson()).toList();
    }
    map['total_members'] = totalMembers;
    map['members_request'] = membersRequest;
    map['posts_request'] = postsRequest;
    map['isAdmin'] = isAdmin;
    return map;
  }
}

GroupMembers groupMembersFromJson(String str) =>
    GroupMembers.fromJson(json.decode(str));
String groupMembersToJson(GroupMembers data) => json.encode(data.toJson());

class GroupMembers {
  GroupMembers({
    this.joinedAt,
    this.adminType,
    this.name,
    this.profilePic,
  });

  GroupMembers.fromJson(dynamic json) {
    joinedAt = json['joined_at'];
    adminType = json['admin_type'];
    name = json['name'];
    profilePic = json['profile_pic'];
  }
  String? joinedAt;
  String? adminType;
  String? name;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['joined_at'] = joinedAt;
    map['admin_type'] = adminType;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    return map;
  }
}

GroupStatus groupStatusFromJson(String str) =>
    GroupStatus.fromJson(json.decode(str));
String groupStatusToJson(GroupStatus data) => json.encode(data.toJson());

class GroupStatus {
  GroupStatus({
    this.status,
    this.adminType,
  });

  GroupStatus.fromJson(dynamic json) {
    status = json['status'];
    adminType = json['admin_type'];
  }
  String? status;
  String? adminType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['admin_type'] = adminType;
    return map;
  }
}

Group groupFromJson(String str) => Group.fromJson(json.decode(str));
String groupToJson(Group data) => json.encode(data.toJson());

class Group {
  Group({
    this.id,
    this.name,
    this.privacySetting,
    this.logo,
    this.banner,
  });

  Group.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    privacySetting = json['privacy_setting'];
    logo = json['logo'];
    banner = json['banner'];
  }
  String? id;
  String? name;
  String? privacySetting;
  String? logo;
  String? banner;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['privacy_setting'] = privacySetting;
    map['logo'] = logo;
    map['banner'] = banner;
    return map;
  }
}
