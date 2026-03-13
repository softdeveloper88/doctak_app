import 'dart:convert';

CmeNotificationsResponse cmeNotificationsResponseFromJson(String str) =>
    CmeNotificationsResponse.fromJson(json.decode(str));

class CmeNotificationsResponse {
  CmeNotificationsResponse({this.notifications, this.unreadCount});

  CmeNotificationsResponse.fromJson(dynamic json) {
    if (json['notifications'] != null) {
      notifications = [];
      if (json['notifications'] is List) {
        json['notifications'].forEach((v) {
          notifications?.add(CmeNotificationData.fromJson(v));
        });
      } else if (json['notifications']['data'] != null) {
        json['notifications']['data'].forEach((v) {
          notifications?.add(CmeNotificationData.fromJson(v));
        });
      }
    }
    unreadCount = json['unread_count'];
  }

  List<CmeNotificationData>? notifications;
  int? unreadCount;
}

class CmeNotificationData {
  CmeNotificationData({
    this.id,
    this.type,
    this.title,
    this.message,
    this.eventId,
    this.eventTitle,
    this.data,
    this.isRead,
    this.readAt,
    this.createdAt,
  });

  CmeNotificationData.fromJson(dynamic json) {
    id = json['id'];
    type = json['type'];
    title = json['title'];
    message = json['message'];
    eventId = json['event_id'];
    eventTitle = json['event_title'];
    data = json['data'];
    isRead = json['is_read'];
    readAt = json['read_at'];
    createdAt = json['created_at'];
  }

  String? id;
  String? type;
  String? title;
  String? message;
  String? eventId;
  String? eventTitle;
  dynamic data;
  dynamic isRead;
  String? readAt;
  String? createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['type'] = type;
    map['title'] = title;
    map['message'] = message;
    map['event_id'] = eventId;
    map['event_title'] = eventTitle;
    map['data'] = data;
    map['is_read'] = isRead;
    map['read_at'] = readAt;
    map['created_at'] = createdAt;
    return map;
  }

  bool get unread => isRead == false || isRead == 0;
}
