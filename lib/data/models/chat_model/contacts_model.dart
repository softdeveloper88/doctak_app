import 'dart:convert';
ContactsModel contactsModelFromJson(String str) => ContactsModel.fromJson(json.decode(str));
String contactsModelToJson(ContactsModel data) => json.encode(data.toJson());
class ContactsModel {
  ContactsModel({
      this.success, 
      this.groups, 
      this.contacts, 
      this.total, 
      this.lastPage,});

  ContactsModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['groups'] != null) {
      groups = [];
      json['groups'].forEach((v) {
        groups?.add(Groups.fromJson(v));
      });
    }
    if (json['contacts'] != null) {
      contacts = [];
      json['contacts'].forEach((v) {
        contacts?.add(Contacts.fromJson(v));
      });
    }
    total = json['total'];
    lastPage = json['last_page'];
  }
  bool? success;
  List<Groups>? groups;
  List<Contacts>? contacts;
  int? total;
  int? lastPage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (groups != null) {
      map['groups'] = groups?.map((v) => v.toJson()).toList();
    }
    if (contacts != null) {
      map['contacts'] = contacts?.map((v) => v.toJson()).toList();
    }
    map['total'] = total;
    map['last_page'] = lastPage;
    return map;
  }

}

Contacts contactsFromJson(String str) => Contacts.fromJson(json.decode(str));
String contactsToJson(Contacts data) => json.encode(data.toJson());
class Contacts {
  Contacts({
      this.roomId, 
      this.createdAt, 
      this.firstName, 
      this.lastName, 
      this.profilePic, 
      this.latestMessage, 
      this.latestMessageTime,});

  Contacts.fromJson(dynamic json) {
    roomId = json['room_id'];
    createdAt = json['created_at'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    profilePic = json['profile_pic'];
    latestMessage = json['latest_message'];
    latestMessageTime = json['latest_message_time'];
  }
  String? roomId;
  String? createdAt;
  String? firstName;
  String? lastName;
  String? profilePic;
  String? latestMessage;
  String? latestMessageTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['room_id'] = roomId;
    map['created_at'] = createdAt;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['profile_pic'] = profilePic;
    map['latest_message'] = latestMessage;
    map['latest_message_time'] = latestMessageTime;
    return map;
  }

}

Groups groupsFromJson(String str) => Groups.fromJson(json.decode(str));
String groupsToJson(Groups data) => json.encode(data.toJson());
class Groups {
  Groups({
      this.roomId, 
      this.createdAt, 
      this.groupName, 
      this.latestMessage, 
      this.latestMessageTime,});

  Groups.fromJson(dynamic json) {
    roomId = json['room_id'];
    createdAt = json['created_at'];
    groupName = json['group_name'];
    latestMessage = json['latest_message'];
    latestMessageTime = json['latest_message_time'];
  }
  String? roomId;
  String? createdAt;
  String? groupName;
  String? latestMessage;
  String? latestMessageTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['room_id'] = roomId;
    map['created_at'] = createdAt;
    map['group_name'] = groupName;
    map['latest_message'] = latestMessage;
    map['latest_message_time'] = latestMessageTime;
    return map;
  }

}