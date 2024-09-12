import 'dart:convert';
NotificationsModel notificationModelFromJson(String str) => NotificationsModel.fromJson(json.decode(str));
String notificationModelToJson(NotificationsModel data) => json.encode(data.toJson());
class NotificationsModel {
  NotificationsModel({
      this.notifications,});

  NotificationsModel.fromJson(dynamic json) {
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
      this.invitationId, 
      this.text, 
      this.url, 
      this.image, 
      this.isRead, 
      this.type, 
      this.createdAt, 
      this.updatedAt, 
      this.groupEventId, 
      this.groupId, 
      this.user,});

  Data.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    userName = json['user_name'];
    groupName = json['group_name'];
    postId = json['post_id'];
    invitationId = json['invitation_id'];
    text = json['text'];
    url = json['url'];
    image = json['image'];
    isRead = json['is_read'];
    type = json['type'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    groupEventId = json['group_event_id'];
    groupId = json['group_id'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  int? id;
  String? userId;
  dynamic userName;
  dynamic groupName;
  dynamic postId;
  dynamic invitationId;
  String? text;
  String? url;
  dynamic image;
  int? isRead;
  String? type;
  String? createdAt;
  String? updatedAt;
  dynamic groupEventId;
  dynamic groupId;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['user_name'] = userName;
    map['group_name'] = groupName;
    map['post_id'] = postId;
    map['invitation_id'] = invitationId;
    map['text'] = text;
    map['url'] = url;
    map['image'] = image;
    map['is_read'] = isRead;
    map['type'] = type;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['group_event_id'] = groupEventId;
    map['group_id'] = groupId;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }

}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
      this.id, 
      this.firstName, 
      this.lastName, 
      this.emailVerifiedAt, 
      this.userType, 
      this.name, 
      this.email, 
      this.token, 
      this.phone, 
      this.licenseNo, 
      this.specialty, 
      this.status, 
      this.role, 
      this.gender, 
      this.dob, 
      this.clinicName, 
      this.college, 
      this.countryOrigin, 
      this.profilePic, 
      this.practicingCountry, 
      this.otpCode, 
      this.balance, 
      this.title, 
      this.city, 
      this.country, 
      this.isAdmin, 
      this.createdAt, 
      this.updatedAt, 
      this.activeStatus, 
      this.avatar, 
      this.darkMode, 
      this.messengerColor, 
      this.isPremium, 
      this.background,});

  User.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    emailVerifiedAt = json['email_verified_at'];
    userType = json['user_type'];
    name = json['name'];
    email = json['email'];
    token = json['token'];
    phone = json['phone'];
    licenseNo = json['license_no'];
    specialty = json['specialty'];
    status = json['status'];
    role = json['role'];
    gender = json['gender'];
    dob = json['dob'];
    clinicName = json['clinic_name'];
    college = json['college'];
    countryOrigin = json['country_origin'];
    profilePic = json['profile_pic'];
    practicingCountry = json['practicing_country'];
    otpCode = json['otp_code'];
    balance = json['balance'];
    title = json['title'];
    city = json['city'];
    country = json['country'];
    isAdmin = json['is_admin'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    activeStatus = json['active_status'];
    avatar = json['avatar'];
    darkMode = json['dark_mode'];
    messengerColor = json['messenger_color'];
    isPremium = json['is_premium'];
    background = json['background'];
  }
  String? id;
  String? firstName;
  String? lastName;
  String? emailVerifiedAt;
  String? userType;
  String? name;
  String? email;
  dynamic token;
  String? phone;
  String? licenseNo;
  String? specialty;
  String? status;
  String? role;
  String? gender;
  String? dob;
  String? clinicName;
  String? college;
  String? countryOrigin;
  String? profilePic;
  String? practicingCountry;
  dynamic otpCode;
  int? balance;
  String? title;
  String? city;
  String? country;
  dynamic isAdmin;
  String? createdAt;
  String? updatedAt;
  dynamic activeStatus;
  dynamic avatar;
  int? darkMode;
  dynamic messengerColor;
  int? isPremium;
  String? background;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['email_verified_at'] = emailVerifiedAt;
    map['user_type'] = userType;
    map['name'] = name;
    map['email'] = email;
    map['token'] = token;
    map['phone'] = phone;
    map['license_no'] = licenseNo;
    map['specialty'] = specialty;
    map['status'] = status;
    map['role'] = role;
    map['gender'] = gender;
    map['dob'] = dob;
    map['clinic_name'] = clinicName;
    map['college'] = college;
    map['country_origin'] = countryOrigin;
    map['profile_pic'] = profilePic;
    map['practicing_country'] = practicingCountry;
    map['otp_code'] = otpCode;
    map['balance'] = balance;
    map['title'] = title;
    map['city'] = city;
    map['country'] = country;
    map['is_admin'] = isAdmin;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['active_status'] = activeStatus;
    map['avatar'] = avatar;
    map['dark_mode'] = darkMode;
    map['messenger_color'] = messengerColor;
    map['is_premium'] = isPremium;
    map['background'] = background;
    return map;
  }

}