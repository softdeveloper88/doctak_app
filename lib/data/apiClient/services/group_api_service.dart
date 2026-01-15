import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/group_model/group_details_model.dart';
import 'package:doctak_app/data/models/group_model/group_list_model.dart';
import 'package:doctak_app/data/models/group_model/group_member_request_model.dart';
import 'package:doctak_app/data/models/group_model/group_post_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Group API Service
/// Handles all group-related API calls
class GroupApiService {
  static final GroupApiService _instance = GroupApiService._internal();
  factory GroupApiService() => _instance;
  GroupApiService._internal();

  /// Get all groups with pagination
  Future<ApiResponse<GroupListModel>> getGroups({required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups?page=$page', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupListModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get groups: $e');
    }
  }

  /// Get user's joined groups
  Future<ApiResponse<GroupListModel>> getMyGroups({required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/my-groups?page=$page', method: networkUtils.HttpMethod.POST));
      return ApiResponse.success(GroupListModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get my groups: $e');
    }
  }

  /// Get group details by ID
  Future<ApiResponse<GroupDetailsModel>> getGroupDetails({required String groupId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/group-details/$groupId', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupDetailsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get group details: $e');
    }
  }

  /// Search groups by keyword
  Future<ApiResponse<GroupListModel>> searchGroups({required String page, required String keyword}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/search?page=$page&keyword=$keyword', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupListModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search groups: $e');
    }
  }

  /// Join a group
  Future<ApiResponse<Map<String, dynamic>>> joinGroup({required String groupId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/join', method: networkUtils.HttpMethod.POST));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to join group: $e');
    }
  }

  /// Leave a group
  Future<ApiResponse<Map<String, dynamic>>> leaveGroup({required String groupId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/leave', method: networkUtils.HttpMethod.POST));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to leave group: $e');
    }
  }

  /// Create a new group
  Future<ApiResponse<Map<String, dynamic>>> createGroup({
    required String name,
    required String description,
    required String privacy, // "public", "private"
    String? coverImagePath,
  }) async {
    try {
      final request = {'name': name, 'description': description, 'privacy': privacy};

      if (coverImagePath != null) {
        request['cover_image'] = coverImagePath; // This would need proper file upload handling
      }

      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/create', method: networkUtils.HttpMethod.POST, request: request));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create group: $e');
    }
  }

  /// Update group information (for group admins)
  Future<ApiResponse<Map<String, dynamic>>> updateGroup({required String groupId, required String name, required String description, required String privacy, String? coverImagePath}) async {
    try {
      final request = {'group_id': groupId, 'name': name, 'description': description, 'privacy': privacy};

      if (coverImagePath != null) {
        request['cover_image'] = coverImagePath;
      }

      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/update', method: networkUtils.HttpMethod.POST, request: request));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update group: $e');
    }
  }

  /// Delete a group (for group admins)
  Future<ApiResponse<Map<String, dynamic>>> deleteGroup({required String groupId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/delete', method: networkUtils.HttpMethod.DELETE));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete group: $e');
    }
  }

  /// Get group members
  Future<ApiResponse<GroupMemberRequestModel>> getGroupMembers({required String groupId, required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/members?page=$page', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupMemberRequestModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get group members: $e');
    }
  }

  /// Add member to group (for group admins)
  Future<ApiResponse<Map<String, dynamic>>> addGroupMember({required String groupId, required String userId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/add-member', method: networkUtils.HttpMethod.POST, request: {'user_id': userId}));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to add group member: $e');
    }
  }

  /// Remove member from group (for group admins)
  Future<ApiResponse<Map<String, dynamic>>> removeGroupMember({required String groupId, required String userId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/remove-member', method: networkUtils.HttpMethod.POST, request: {'user_id': userId}));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to remove group member: $e');
    }
  }

  /// Promote member to admin (for group owners)
  Future<ApiResponse<Map<String, dynamic>>> promoteMemberToAdmin({required String groupId, required String userId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/promote-admin', method: networkUtils.HttpMethod.POST, request: {'user_id': userId}));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to promote member to admin: $e');
    }
  }

  /// Demote admin to member (for group owners)
  Future<ApiResponse<Map<String, dynamic>>> demoteAdminToMember({required String groupId, required String userId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/demote-admin', method: networkUtils.HttpMethod.POST, request: {'user_id': userId}));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to demote admin to member: $e');
    }
  }

  /// Get group posts/feed
  Future<ApiResponse<GroupPostModel>> getGroupPosts({required String groupId, required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/posts?page=$page', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupPostModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get group posts: $e');
    }
  }

  /// Post to group
  Future<ApiResponse<Map<String, dynamic>>> postToGroup({required String groupId, required String content, List<String>? imagePaths, String? videoPath}) async {
    try {
      final request = {'group_id': groupId, 'content': content};

      if (imagePaths != null && imagePaths.isNotEmpty) {
        request['images'] = imagePaths.join(','); // Convert list to comma-separated string
      }

      if (videoPath != null) {
        request['video'] = videoPath; // This would need proper file upload handling
      }

      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/post', method: networkUtils.HttpMethod.POST, request: request));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to post to group: $e');
    }
  }

  /// Get recommended groups based on user interests
  Future<ApiResponse<GroupListModel>> getRecommendedGroups({required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/recommended?page=$page', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupListModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get recommended groups: $e');
    }
  }

  /// Get popular/trending groups
  Future<ApiResponse<GroupListModel>> getPopularGroups({required String page}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/popular?page=$page', method: networkUtils.HttpMethod.GET));
      return ApiResponse.success(GroupListModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get popular groups: $e');
    }
  }

  /// Invite users to group
  Future<ApiResponse<Map<String, dynamic>>> inviteUsersToGroup({required String groupId, required List<String> userIds}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/$groupId/invite', method: networkUtils.HttpMethod.POST, request: {'user_ids': userIds}));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to invite users to group: $e');
    }
  }

  /// Accept group invitation
  Future<ApiResponse<Map<String, dynamic>>> acceptGroupInvitation({required String invitationId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/invitation/$invitationId/accept', method: networkUtils.HttpMethod.POST));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to accept group invitation: $e');
    }
  }

  /// Decline group invitation
  Future<ApiResponse<Map<String, dynamic>>> declineGroupInvitation({required String invitationId}) async {
    try {
      final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/groups/invitation/$invitationId/decline', method: networkUtils.HttpMethod.POST));
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to decline group invitation: $e');
    }
  }
}
