/// Story data models for the Stories/Status feature
///
/// Matches the backend API response format from StoryController
import 'package:doctak_app/core/utils/app/AppData.dart';

class StoryUserModel {
  final String id;
  final String fullName;
  final String profilePicUrl;

  StoryUserModel({
    required this.id,
    required this.fullName,
    required this.profilePicUrl,
  });

  factory StoryUserModel.fromJson(Map<String, dynamic> json) {
    return StoryUserModel(
      id: (json['id'] ?? '').toString(),
      fullName: json['full_name'] ?? json['name'] ?? '',
      profilePicUrl: AppData.fullImageUrl(json['profile_pic_url'] ?? json['profile_pic'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'profile_pic_url': profilePicUrl,
      };
}

class StoryItemModel {
  final int id;
  final String type; // 'image', 'video', 'text'
  final String? mediaUrl;
  final String? content;
  final String backgroundColor;
  final String timeAgo;
  final int viewCount;
  final bool hasViewed;
  final bool isOwn;
  StoryUserModel? user;

  StoryItemModel({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.content,
    required this.backgroundColor,
    required this.timeAgo,
    required this.viewCount,
    required this.hasViewed,
    required this.isOwn,
    this.user,
  });

  factory StoryItemModel.fromJson(Map<String, dynamic> json) {
    return StoryItemModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'text',
      mediaUrl: json['media_url'],
      content: json['content'],
      backgroundColor: json['background_color'] ?? '#0d6efd',
      timeAgo: json['time_ago'] ?? '',
      viewCount: json['view_count'] ?? 0,
      hasViewed: json['has_viewed'] ?? false,
      isOwn: json['is_own'] ?? false,
      user: json['user'] != null
          ? StoryUserModel.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'media_url': mediaUrl,
        'content': content,
        'background_color': backgroundColor,
        'time_ago': timeAgo,
        'view_count': viewCount,
        'has_viewed': hasViewed,
        'is_own': isOwn,
      };
}

class StoryGroupModel {
  final String userId;
  final StoryUserModel user;
  final int storyCount;
  final List<StoryItemModel> stories;
  final bool hasUnviewed;

  StoryGroupModel({
    required this.userId,
    required this.user,
    required this.storyCount,
    required this.stories,
    required this.hasUnviewed,
  });

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    return StoryGroupModel(
      userId: (json['user_id'] ?? '').toString(),
      user: StoryUserModel.fromJson(json['user'] ?? {}),
      storyCount: json['story_count'] ?? 0,
      stories: (json['stories'] as List<dynamic>?)
              ?.map((s) => StoryItemModel.fromJson(s))
              .toList() ??
          [],
      hasUnviewed: json['has_unviewed'] ?? false,
    );
  }
}

class StoryViewerModel {
  final String id;
  final String name;
  final String profilePic;
  final String viewedAt;

  StoryViewerModel({
    required this.id,
    required this.name,
    required this.profilePic,
    required this.viewedAt,
  });

  factory StoryViewerModel.fromJson(Map<String, dynamic> json) {
    return StoryViewerModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      profilePic: AppData.fullImageUrl(json['profile_pic'] ?? ''),
      viewedAt: json['viewed_at'] ?? '',
    );
  }
}

/// Response wrapper for story feed
class StoryFeedResponse {
  final bool success;
  final List<StoryGroupModel> data;

  StoryFeedResponse({required this.success, required this.data});

  factory StoryFeedResponse.fromJson(Map<String, dynamic> json) {
    return StoryFeedResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((g) => StoryGroupModel.fromJson(g))
              .toList() ??
          [],
    );
  }
}
