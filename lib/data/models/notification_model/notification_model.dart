import 'dart:convert';
NotificationModel notificationModelFromJson(String str) => NotificationModel.fromJson(json.decode(str));
String notificationModelToJson(NotificationModel data) => json.encode(data.toJson());
class NotificationModel {
  NotificationModel({
      this.notifications,});

  NotificationModel.fromJson(dynamic json) {
    notifications = json['notifications'] != null ? Notifications.fromJson(json['notifications']) : null;
  }
  Notifications? notifications;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (notifications != null) {
      map['notifications'] = notifications?.toJson();
    }
    return map;
  }

}

Notifications notificationsFromJson(String str) => Notifications.fromJson(json.decode(str));
String notificationsToJson(Notifications data) => json.encode(data.toJson());
class Notifications {
  Notifications({
      this.currentPage, 
      this.data, 
      this.firstPageUrl, 
      this.from, 
      this.lastPage, 
      this.lastPageUrl, 
      this.links, 
      this.nextPageUrl, 
      this.path, 
      this.perPage, 
      this.prevPageUrl, 
      this.to, 
      this.total,});

  Notifications.fromJson(dynamic json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = [];
      json['links'].forEach((v) {
        links?.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  dynamic nextPageUrl;
  String? path;
  int? perPage;
  dynamic prevPageUrl;
  int? to;
  int? total;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['current_page'] = currentPage;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['first_page_url'] = firstPageUrl;
    map['from'] = from;
    map['last_page'] = lastPage;
    map['last_page_url'] = lastPageUrl;
    if (links != null) {
      map['links'] = links?.map((v) => v.toJson()).toList();
    }
    map['next_page_url'] = nextPageUrl;
    map['path'] = path;
    map['per_page'] = perPage;
    map['prev_page_url'] = prevPageUrl;
    map['to'] = to;
    map['total'] = total;
    return map;
  }

}

Links linksFromJson(String str) => Links.fromJson(json.decode(str));
String linksToJson(Links data) => json.encode(data.toJson());
class Links {
  Links({
      this.url, 
      this.label, 
      this.active,});

  Links.fromJson(dynamic json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }
  dynamic url;
  String? label;
  bool? active;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['label'] = label;
    map['active'] = active;
    return map;
  }

}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.id, 
      this.userId, 
      this.userName, 
      this.groupName, 
      this.postId, 
      this.groupEventId, 
      this.groupId, 
      this.invitationId, 
      this.text, 
      this.url, 
      this.image, 
      this.isRead, 
      this.type, 
      this.createdAt, 
      this.updatedAt, 
      this.toUserId, 
      this.senderFirstName, 
      this.senderLastName, 
      this.senderSpecialty, 
      this.senderProfilePic, 
      this.receiverFirstName, 
      this.receiverLastName, 
      this.receiverSpecialty, 
      this.receiverProfilePic,});

  Data.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    userName = json['user_name'];
    groupName = json['group_name'];
    postId = json['post_id'];
    groupEventId = json['group_event_id'];
    groupId = json['group_id'];
    invitationId = json['invitation_id'];
    text = json['text'];
    url = json['url'];
    image = json['image'];
    isRead = json['is_read'];
    type = json['type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    toUserId = json['to_user_id'];
    senderFirstName = json['sender_first_name'];
    senderLastName = json['sender_last_name'];
    senderSpecialty = json['sender_specialty'];
    senderProfilePic = json['sender_profile_pic'];
    receiverFirstName = json['receiver_first_name'];
    receiverLastName = json['receiver_last_name'];
    receiverSpecialty = json['receiver_specialty'];
    receiverProfilePic = json['receiver_profile_pic'];
  }
  int? id;
  String? userId;
  dynamic userName;
  dynamic groupName;
  String? postId;
  dynamic groupEventId;
  dynamic groupId;
  dynamic invitationId;
  String? text;
  String? url;
  dynamic image;
  int? isRead;
  String? type;
  String? createdAt;
  String? updatedAt;
  String? toUserId;
  String? senderFirstName;
  String? senderLastName;
  String? senderSpecialty;
  String? senderProfilePic;
  String? receiverFirstName;
  String? receiverLastName;
  String? receiverSpecialty;
  String? receiverProfilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['user_name'] = userName;
    map['group_name'] = groupName;
    map['post_id'] = postId;
    map['group_event_id'] = groupEventId;
    map['group_id'] = groupId;
    map['invitation_id'] = invitationId;
    map['text'] = text;
    map['url'] = url;
    map['image'] = image;
    map['is_read'] = isRead;
    map['type'] = type;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['to_user_id'] = toUserId;
    map['sender_first_name'] = senderFirstName;
    map['sender_last_name'] = senderLastName;
    map['sender_specialty'] = senderSpecialty;
    map['sender_profile_pic'] = senderProfilePic;
    map['receiver_first_name'] = receiverFirstName;
    map['receiver_last_name'] = receiverLastName;
    map['receiver_specialty'] = receiverSpecialty;
    map['receiver_profile_pic'] = receiverProfilePic;
    return map;
  }

}