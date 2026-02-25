import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Moderation API Service
/// Handles all content moderation related API calls including:
/// - Reporting posts, comments, and users
/// - Blocking/unblocking users
/// - Getting blocked users list
/// 
/// Apple App Store Guideline 1.2 Compliance:
/// - Report mechanism for objectionable content
/// - Block mechanism for abusive users
/// - 24-hour content moderation support
class ModerationApiService {
  static final ModerationApiService _instance = ModerationApiService._internal();
  factory ModerationApiService() => _instance;
  ModerationApiService._internal();

  // ================================== REPORT ENDPOINTS ==================================

  /// Report a post
  /// [postId] - The ID of the post to report
  /// [reason] - The reason for reporting (e.g., 'spam', 'harassment', 'inappropriate', etc.)
  /// [description] - Optional additional details about the report
  Future<ApiResponse<Map<String, dynamic>>> reportPost({
    required int postId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/report/post',
          method: networkUtils.HttpMethod.POST,
          request: {
            'post_id': postId,
            'reason': reason,
            if (description != null) 'description': description,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Report a comment
  /// [commentId] - The ID of the comment to report
  /// [reason] - The reason for reporting
  /// [description] - Optional additional details
  Future<ApiResponse<Map<String, dynamic>>> reportComment({
    required int commentId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/report/comment',
          method: networkUtils.HttpMethod.POST,
          request: {
            'comment_id': commentId,
            'reason': reason,
            if (description != null) 'description': description,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Report a user
  /// [userId] - The ID of the user to report
  /// [reason] - The reason for reporting
  /// [description] - Optional additional details
  Future<ApiResponse<Map<String, dynamic>>> reportUser({
    required String userId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/report/user',
          method: networkUtils.HttpMethod.POST,
          request: {
            'user_id': userId,
            'reason': reason,
            if (description != null) 'description': description,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ================================== BLOCK ENDPOINTS ==================================

  /// Block a user
  /// [userId] - The ID of the user to block
  /// Blocking will:
  /// - Remove their content from your feed instantly
  /// - Prevent them from messaging you
  /// - Notify the developer about the block
  Future<ApiResponse<Map<String, dynamic>>> blockUser({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/block',
          method: networkUtils.HttpMethod.POST,
          request: {
            'user_id': userId,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Unblock a user
  /// [userId] - The ID of the user to unblock
  Future<ApiResponse<Map<String, dynamic>>> unblockUser({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/unblock',
          method: networkUtils.HttpMethod.POST,
          request: {
            'user_id': userId,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get list of blocked users
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/blocked-list',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> data = response['data'] ?? [];
      return ApiResponse.success(
        data.map((e) => BlockedUser.fromJson(e)).toList(),
      );
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Check if a user is blocked
  /// [userId] - The ID of the user to check
  Future<ApiResponse<bool>> isUserBlocked({required String userId}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/is-blocked/$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(response['is_blocked'] ?? false);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ================================== REPORT HISTORY ==================================

  /// Get the current user's report history
  Future<ApiResponse<ReportHistoryResponse>> getMyReports({int page = 1}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/report/my-reports?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(ReportHistoryResponse.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // ================================== COMMUNICATION CHECK ==================================

  /// Check if the current user can communicate with a target user
  /// Returns false if either user has blocked the other
  Future<ApiResponse<bool>> canCommunicate({required String targetUserId}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/can-communicate/$targetUserId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(response['can_communicate'] ?? true);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Get all blocked user IDs (both directions) for local filtering
  Future<ApiResponse<BlockedIdsResponse>> getBlockedUserIds() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/blocked-ids',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(BlockedIdsResponse.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

// ================================== MODELS ==================================

/// Report reason types for content moderation
enum ReportReason {
  spam('spam', 'Spam or misleading'),
  harassment('harassment', 'Harassment or bullying'),
  hateSpeech('hate_speech', 'Hate speech or discrimination'),
  violence('violence', 'Violence or dangerous content'),
  inappropriateContent('inappropriate_content', 'Inappropriate or offensive content'),
  falseInformation('false_information', 'False or misleading information'),
  intellectualProperty('intellectual_property', 'Intellectual property violation'),
  impersonation('impersonation', 'Impersonation or fake account'),
  privacyViolation('privacy_violation', 'Privacy violation'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const ReportReason(this.value, this.displayName);

  static ReportReason fromValue(String value) {
    return ReportReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportReason.other,
    );
  }
}

/// Model for blocked user
class BlockedUser {
  final String id;
  final String name;
  final String? profilePic;
  final DateTime? blockedAt;

  BlockedUser({
    required this.id,
    required this.name,
    this.profilePic,
    this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profilePic: json['profile_pic'],
      blockedAt: json['blocked_at'] != null 
          ? DateTime.tryParse(json['blocked_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_pic': profilePic,
      'blocked_at': blockedAt?.toIso8601String(),
    };
  }
}

/// Model for report submission
class ReportSubmission {
  final int contentId;
  final String contentType; // 'post', 'comment', 'user'
  final ReportReason reason;
  final String? description;

  ReportSubmission({
    required this.contentId,
    required this.contentType,
    required this.reason,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'content_type': contentType,
      'reason': reason.value,
      if (description != null) 'description': description,
    };
  }
}

/// Model for a single report in report history
class ReportHistoryItem {
  final int id;
  final String contentType;
  final String? contentId;
  final String contentPreview;
  final String reason;
  final String? reasonOption;
  final String? note;
  final int status;
  final String statusLabel;
  final String? adminResponse;
  final DateTime? adminRespondedAt;
  final bool isOverdue;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportHistoryItem({
    required this.id,
    required this.contentType,
    this.contentId,
    required this.contentPreview,
    required this.reason,
    this.reasonOption,
    this.note,
    required this.status,
    required this.statusLabel,
    this.adminResponse,
    this.adminRespondedAt,
    required this.isOverdue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReportHistoryItem(
      id: json['id'] ?? 0,
      contentType: json['content_type'] ?? 'post',
      contentId: json['content_id']?.toString(),
      contentPreview: json['content_preview'] ?? '',
      reason: json['reason'] ?? '',
      reasonOption: json['reason_option'],
      note: json['note'],
      status: json['status'] ?? 0,
      statusLabel: json['status_label'] ?? 'Pending',
      adminResponse: json['admin_response'],
      adminRespondedAt: json['admin_responded_at'] != null
          ? DateTime.tryParse(json['admin_responded_at'])
          : null,
      isOverdue: json['is_overdue'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Response model for report history pagination
class ReportHistoryResponse {
  final List<ReportHistoryItem> reports;
  final int currentPage;
  final int lastPage;
  final int total;

  ReportHistoryResponse({
    required this.reports,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ReportHistoryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    final pagination = json['pagination'] ?? {};
    return ReportHistoryResponse(
      reports: data.map((e) => ReportHistoryItem.fromJson(e)).toList(),
      currentPage: pagination['current_page'] ?? 1,
      lastPage: pagination['last_page'] ?? 1,
      total: pagination['total'] ?? 0,
    );
  }
}

/// Response model for blocked IDs
class BlockedIdsResponse {
  final List<String> blockedIds;
  final List<String> blockedByIds;
  final List<String> allBlockedIds;

  BlockedIdsResponse({
    required this.blockedIds,
    required this.blockedByIds,
    required this.allBlockedIds,
  });

  factory BlockedIdsResponse.fromJson(Map<String, dynamic> json) {
    return BlockedIdsResponse(
      blockedIds: List<String>.from((json['blocked_ids'] ?? []).map((e) => e.toString())),
      blockedByIds: List<String>.from((json['blocked_by_ids'] ?? []).map((e) => e.toString())),
      allBlockedIds: List<String>.from((json['all_blocked_ids'] ?? []).map((e) => e.toString())),
    );
  }
}
