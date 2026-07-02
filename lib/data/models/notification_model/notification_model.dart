import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';

NotificationModel notificationModelFromJson(String str) => NotificationModel.fromJson(json.decode(str));
String notificationModelToJson(NotificationModel data) => json.encode(data.toJson());

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int? _asReadFlag(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value ? 1 : 0;
  return _asInt(value);
}

class NotificationModel {
  NotificationModel({this.notifications, this.unreadCount});

  NotificationModel.fromJson(dynamic json) {
    notifications = json['notifications'] != null ? Notifications.fromJson(json['notifications']) : null;
    unreadCount = _asInt(json['unread_count']) ?? _asInt(json['unreadCount']);
  }
  Notifications? notifications;
  int? unreadCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (notifications != null) {
      map['notifications'] = notifications?.toJson();
    }
    map['unread_count'] = unreadCount;
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
    this.total,
  });

  Notifications.fromJson(dynamic json) {
    currentPage = _asInt(json['current_page']);
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = _asInt(json['from']);
    lastPage = _asInt(json['last_page']);
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = [];
      json['links'].forEach((v) {
        links?.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = _asInt(json['per_page']);
    prevPageUrl = json['prev_page_url'];
    to = _asInt(json['to']);
    total = _asInt(json['total']);
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
  Links({this.url, this.label, this.active});

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
    this.fromUserId,
    this.senderFirstName,
    this.senderLastName,
    this.senderSpecialty,
    this.senderProfilePic,
    this.receiverFirstName,
    this.receiverLastName,
    this.receiverSpecialty,
    this.receiverProfilePic,
    this.actorName,
    this.actionText,
    this.othersCount,
    this.snippet,
    this.category,
    this.friendRequestId,
    this.showConnectionActions,
  });

  Data.fromJson(dynamic json) {
    id = _asInt(json['id']);
    userId = json['user_id']?.toString();
    userName = json['user_name'];
    groupName = json['group_name'];
    postId = json['post_id']?.toString();
    groupEventId = json['group_event_id'];
    groupId = json['group_id'];
    invitationId = json['invitation_id'];
    text = json['text']?.toString();
    url = json['url']?.toString();
    image = json['image'];
    if (json['is_read'] != null) {
      isRead = _asReadFlag(json['is_read']);
    } else {
      final readAt = json['read_at'];
      isRead = readAt != null && '$readAt'.trim().isNotEmpty ? 1 : 0;
    }
    type = json['type']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    fromUserId = json['from_user_id']?.toString();
    senderFirstName = json['sender_first_name']?.toString();
    senderLastName = json['sender_last_name']?.toString();
    senderSpecialty = json['sender_specialty']?.toString();
    senderProfilePic = AppData.fullImageUrl(json['sender_profile_pic']?.toString());
    receiverFirstName = json['receiver_first_name']?.toString();
    receiverLastName = json['receiver_last_name']?.toString();
    receiverSpecialty = json['receiver_specialty']?.toString();
    receiverProfilePic = AppData.fullImageUrl(json['receiver_profile_pic']?.toString());
    actorName = json['actor_name']?.toString();
    actionText = json['action_text']?.toString();
    othersCount = _asInt(json['others_count']);
    snippet = json['snippet']?.toString();
    category = json['category']?.toString();
    friendRequestId = json['friend_request_id']?.toString() ??
        json['invitation_id']?.toString();
    final rawType = type?.toLowerCase() ?? '';
    final rawText = (text ?? '').toLowerCase();
    showConnectionActions =
        (json['show_connection_actions'] == true ||
                json['show_connection_actions'] == 1) &&
            rawType != 'connection_accepted' &&
            rawType != 'friend_request.accepted' &&
            !rawText.contains('accepted your connection request');

    _parseMetadata(json['data']);
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
  String? fromUserId;
  String? senderFirstName;
  String? senderLastName;
  String? senderSpecialty;
  String? senderProfilePic;
  String? receiverFirstName;
  String? receiverLastName;
  String? receiverSpecialty;
  String? receiverProfilePic;
  String? actorName;
  String? actionText;
  int? othersCount;
  String? snippet;
  String? category;
  String? friendRequestId;
  bool? showConnectionActions;
  Map<String, dynamic>? _metadata;

  void _parseMetadata(dynamic raw) {
    if (raw == null) return;
    if (raw is Map) {
      _metadata = raw.map((key, value) => MapEntry(key.toString(), value));
      return;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          _metadata = decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        /* ignore malformed metadata */
      }
    }
  }

  int? _metaInt(List<String> keys) {
    final meta = _metadata;
    if (meta == null) return null;
    for (final key in keys) {
      final value = meta[key];
      if (value == null) continue;
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _caseIdFromUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(
      trimmed.startsWith('http') ? trimmed : 'https://doctak.net$trimmed',
    );
    if (uri == null) return null;

    final fromQuery = uri.queryParameters['case'];
    if (fromQuery != null && fromQuery.isNotEmpty) {
      return int.tryParse(fromQuery);
    }

    final path = uri.path.toLowerCase();
    if (path.contains('/case/')) {
      final segment = uri.path.split('/case/').last.split('/').first.split('?').first;
      return int.tryParse(segment);
    }
    return null;
  }

  /// Whether this notification refers to a case discussion (not a feed post).
  bool get isCaseDiscussionNotification {
    final normalizedType = (type ?? '').toLowerCase();
    if (normalizedType == 'case.reply' ||
        normalizedType == 'new_discuss_case' ||
        normalizedType.contains('discuss_case')) {
      return true;
    }

    final link = (url ?? '').toLowerCase();
    if (link.contains('discuss-case') || link.contains('/case/')) {
      return true;
    }

    final copy = '${text ?? ''} ${actionText ?? ''}'.toLowerCase();
    if (copy.contains('commented on your case') ||
        copy.contains('case discussion') ||
        copy.contains('liked your case comment')) {
      return true;
    }

    return _metaInt(['caseId', 'case_id']) != null;
  }

  /// Resolved discuss-case id for deep-link navigation.
  int? get resolvedCaseId {
    final fromMeta = _metaInt(['caseId', 'case_id']);
    if (fromMeta != null) return fromMeta;

    final fromUrl = _caseIdFromUrl(url);
    if (fromUrl != null) return fromUrl;

    if (isCaseDiscussionNotification) {
      return int.tryParse(postId ?? '');
    }
    return null;
  }

  /// Map consumed by [NotificationNavigation.open].
  Map<String, dynamic> toNavigationMap() {
    final map = <String, dynamic>{
      'type': type,
      'postId': postId,
      'post_id': postId,
      'url': url,
      'link': url,
      'from_user_id': fromUserId,
      'actorUserId': fromUserId,
      'userId': userId,
      'groupId': groupId,
      'group_id': groupId,
      'invitationId': invitationId,
      'invitation_id': invitationId,
      'friend_request_id': friendRequestId,
    };

    final caseId = resolvedCaseId;
    if (caseId != null) {
      map['caseId'] = caseId;
      map['case_id'] = caseId;
    }

    final commentId = _metaInt(['commentId', 'comment_id']);
    if (commentId != null) {
      map['commentId'] = commentId;
      map['comment_id'] = commentId;
    }

    return map;
  }

  String get displayActorName {
    final fromApi = (actorName ?? '').trim();
    if (fromApi.isNotEmpty) return fromApi;
    final combined = '${senderFirstName ?? ''} ${senderLastName ?? ''}'.trim();
    if (combined.isNotEmpty) return combined;
    return (userName ?? '').toString().trim().isNotEmpty
        ? userName.toString()
        : 'Member';
  }

  bool get isUnread => isRead != 1;

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
    map['from_user_id'] = fromUserId;
    map['sender_first_name'] = senderFirstName;
    map['sender_last_name'] = senderLastName;
    map['sender_specialty'] = senderSpecialty;
    map['sender_profile_pic'] = senderProfilePic;
    map['receiver_first_name'] = receiverFirstName;
    map['receiver_last_name'] = receiverLastName;
    map['receiver_specialty'] = receiverSpecialty;
    map['receiver_profile_pic'] = receiverProfilePic;
    map['actor_name'] = actorName;
    map['action_text'] = actionText;
    map['others_count'] = othersCount;
    map['snippet'] = snippet;
    map['category'] = category;
    map['friend_request_id'] = friendRequestId;
    map['show_connection_actions'] = showConnectionActions;
    return map;
  }
}
