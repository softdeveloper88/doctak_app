import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart' show ApiException;
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Mobile Groups APIs on doctak-node (`/api/v1/groups/*` + legacy `/api/groups/*`).
class GroupsNodeApiService {
  static const _groups = '/api/v1/groups';
  static const _legacyGroups = '/api/groups';

  static Future<GroupListResultModel> browseGroups({
    String? keyword,
    String scope = 'all',
    String privacy = 'all',
    String sort = 'newest',
    String? cursor,
    int limit = 12,
  }) async {
    final params = <String, String>{
      'scope': scope,
      'privacy': privacy,
      'sort': sort,
      'limit': '$limit',
    };
    if (keyword != null && keyword.trim().isNotEmpty) {
      params['q'] = keyword.trim();
    }
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }

    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final response = await buildHttpResponseNode('$_groups?$query');
    final data = await handleResponse(response);

    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return GroupListResultModel(
      items: items,
      nextCursor: data['nextCursor']?.toString(),
      total: _asInt(data['total']),
      facets: data['facets'] is Map
          ? GroupFacetsModel.fromJson(
              Map<String, dynamic>.from(data['facets'] as Map),
            )
          : null,
    );
  }

  static Future<GroupDetailModel> getGroupDetail(String groupId) async {
    final response =
        await buildHttpResponseNode('$_groups/$groupId/detail');
    final data = await handleResponse(response);
    final group = data['group'] as Map<String, dynamic>? ?? data;
    return GroupDetailModel.fromJson(Map<String, dynamic>.from(group));
  }

  static Future<GroupFeedResultModel> getGroupFeed(
    String groupId, {
    String? cursor,
    int limit = 15,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final response =
        await buildHttpResponseNode('$_groups/$groupId/feed?$query');
    final data = await handleResponse(response);

    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupFeedEntryModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();

    return GroupFeedResultModel(
      items: items,
      nextCursor: data['nextCursor']?.toString(),
      total: _asInt(data['total']),
    );
  }

  static Future<List<GroupInvitationModel>> getMyInvitations() async {
    final response = await buildHttpResponseNode('$_groups/me/invitations');
    final data = await handleResponse(response);
    return (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupInvitationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  static Future<void> respondInvitation(String invitationId, bool accept) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/invitations/$invitationId',
        method: HttpMethod.PATCH,
        body: {'accept': accept},
      ),
    );
  }

  /// Connections/friends eligible for a group invite (legacy enhanced-groups API).
  static Future<List<GroupUserStubModel>> searchInviteCandidates(
    String groupId, {
    String? query,
  }) async {
    final params = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    final queryString = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final path = queryString.isEmpty
        ? '$_groups/$groupId/invite-candidates'
        : '$_groups/$groupId/invite-candidates?$queryString';

    final data = await handleResponse(await buildHttpResponseNode(path));
    return (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupUserStubModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  /// Sends an in-app + FCM group invitation to a connection.
  static Future<String> sendGroupInvite(
    String groupId, {
    required String inviteeId,
    String? message,
  }) async {
    final body = <String, dynamic>{'inviteeId': inviteeId};
    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }
    final data = await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/invitations',
        method: HttpMethod.POST,
        body: body,
      ),
    );
    return data['id']?.toString() ?? '';
  }

  /// Updates group info (owner/admin).
  static Future<void> updateGroup(
    String groupId,
    Map<String, dynamic> patch,
  ) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_legacyGroups/$groupId',
        method: HttpMethod.PATCH,
        body: patch,
      ),
    );
  }

  /// Uploads group logo or cover image; returns public URL.
  static Future<String> uploadGroupMedia(
    String kind,
    File file, {
    String? groupId,
  }) async {
    final base = AppData.nodeApiUrl.endsWith('/')
        ? AppData.nodeApiUrl.substring(0, AppData.nodeApiUrl.length - 1)
        : AppData.nodeApiUrl;
    final uri = Uri.parse('$base$_legacyGroups/media');
    final request = http.MultipartRequest('POST', uri);

    final token = AppData.userToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.headers.addAll(ActingContextService.instance.actingHeaders());

    request.fields['kind'] = kind;
    if (groupId != null && groupId.isNotEmpty) {
      request.fields['groupId'] = groupId;
    }

    final name = file.path.split('/').last.toLowerCase();
    var mime = 'image/jpeg';
    if (name.endsWith('.png')) mime = 'image/png';
    if (name.endsWith('.webp')) mime = 'image/webp';
    if (name.endsWith('.gif')) mime = 'image/gif';

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType.parse(mime),
    ));

    final streamed = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw ApiException(message: 'Upload timed out', statusCode: 408),
    );
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map &&
        decoded['success'] == true &&
        decoded['url'] != null) {
      return decoded['url'].toString();
    }
    final message = decoded is Map
        ? (decoded['message']?.toString() ?? 'Upload failed')
        : 'Upload failed';
    throw ApiException(message: message, statusCode: response.statusCode);
  }

  static Future<List<GroupSummaryModel>> getSuggestions({
    int limit = 4,
    String? excludeGroupId,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (excludeGroupId != null && excludeGroupId.isNotEmpty) {
      params['excludeGroupId'] = excludeGroupId;
    }
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final response = await buildHttpResponseNode('$_groups/suggestions?$query');
    final data = await handleResponse(response);
    return (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupSummaryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<Map<String, dynamic>> joinGroup(String groupId) async {
    final data = await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/join',
        method: HttpMethod.POST,
      ),
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> leaveGroup(String groupId) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/leave',
        method: HttpMethod.POST,
      ),
    );
  }

  static Future<void> deleteGroup(String groupId) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_legacyGroups/$groupId',
        method: HttpMethod.DELETE,
      ),
    );
  }

  static Future<void> updateMemberStatus(
    String groupId, {
    required String memberId,
    required String action,
  }) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/members',
        method: HttpMethod.PATCH,
        body: {
          'memberId': memberId,
          'action': action,
        },
      ),
    );
  }

  static Future<void> setMemberRole(
    String groupId, {
    required String memberId,
    required String role,
  }) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/members',
        method: HttpMethod.PATCH,
        body: {
          'memberId': memberId,
          'action': 'set_role',
          'role': role,
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    String privacy = 'public',
    String groupType = 'general',
    int? specialtyId,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'privacy': privacy,
      'groupType': groupType,
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (specialtyId != null) {
      body['specialtyId'] = specialtyId;
    }

    final data = await handleResponse(
      await buildHttpResponseNode(
        '$_groups/create',
        method: HttpMethod.POST,
        body: body,
      ),
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<GroupMembersResultModel> getMembers(
    String groupId, {
    String status = 'active',
    String role = 'all',
    String? cursor,
    int limit = 30,
  }) async {
    final params = <String, String>{
      'status': status,
      'limit': '$limit',
    };
    if (role.isNotEmpty && role != 'all') {
      params['role'] = role;
    }
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final data = await handleResponse(
      await buildHttpResponseNode('$_groups/$groupId/members?$query'),
    );

    final countsRaw = data['counts'];
    final counts = countsRaw is Map
        ? countsRaw.map((k, v) => MapEntry(k.toString(), _asInt(v)))
        : <String, int>{};

    return GroupMembersResultModel(
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => GroupMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      nextCursor: data['nextCursor']?.toString(),
      total: _asInt(data['total']),
      counts: counts,
    );
  }

  static Future<List<GroupPollModel>> getPolls(String groupId) async {
    final data = await handleResponse(
      await buildHttpResponseNode('$_groups/$groupId/polls'),
    );
    return (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupPollModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> votePoll(
    String groupId,
    String pollId,
    List<String> selectedOptions,
  ) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/polls/$pollId/vote',
        method: HttpMethod.POST,
        body: {'selectedOptions': selectedOptions},
      ),
    );
  }

  static Future<void> closePoll(String groupId, String pollId) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/polls/$pollId/vote',
        method: HttpMethod.DELETE,
      ),
    );
  }

  static String _endsAtIso({
    required int durationValue,
    required String durationUnit,
  }) {
    final next = DateTime.now();
    final ends = switch (durationUnit) {
      'hours' => next.add(Duration(hours: durationValue)),
      'weeks' => next.add(Duration(days: durationValue * 7)),
      _ => next.add(Duration(days: durationValue)),
    };
    return ends.toUtc().toIso8601String();
  }

  static Future<String> createPoll(
    String groupId, {
    required String title,
    String? description,
    required List<String> options,
    bool allowMultipleSelections = false,
    bool anonymousVoting = false,
    int durationValue = 1,
    String durationUnit = 'days',
    bool showVoters = true,
  }) async {
    final data = await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/polls',
        method: HttpMethod.POST,
        body: {
          'title': title.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'pollType': allowMultipleSelections ? 'multiple_choice' : 'single_choice',
          'options': options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList(),
          'allowMultipleSelections': allowMultipleSelections,
          'anonymousVoting': anonymousVoting,
          'endsAt': _endsAtIso(durationValue: durationValue, durationUnit: durationUnit),
          'resultsVisibility': showVoters ? 'immediate' : 'after_voting',
        },
      ),
    );
    return data['id']?.toString() ?? '';
  }

  static Future<GroupPostsResultModel> getPosts(
    String groupId, {
    String view = 'feed',
    String? cursor,
    int limit = 20,
    String status = 'pending',
  }) async {
    final params = <String, String>{
      'view': view,
      'limit': '$limit',
    };
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }
    if (view == 'moderation') {
      params['status'] = status;
    }
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final data = await handleResponse(
      await buildHttpResponseNode('$_groups/$groupId/posts?$query'),
    );

    Map<String, int>? counts;
    if (data['counts'] is Map) {
      counts = Map<String, dynamic>.from(data['counts'] as Map)
          .map((k, v) => MapEntry(k, _asInt(v)));
    }

    return GroupPostsResultModel(
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => GroupFeedPostModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      nextCursor: data['nextCursor']?.toString(),
      total: _asInt(data['total']),
      counts: counts,
    );
  }

  static Future<Map<String, dynamic>> createGroupPost(
    String groupId, {
    required String body,
    String? title,
    String? postType,
    String? caption,
    List<GroupPostMediaUpload>? media,
  }) async {
    final payload = <String, dynamic>{'body': body.trim()};
    if (title != null && title.trim().isNotEmpty) {
      payload['title'] = title.trim();
    }
    if (postType != null && postType.trim().isNotEmpty) {
      payload['postType'] = postType.trim();
    }
    if (caption != null && caption.trim().isNotEmpty) {
      payload['caption'] = caption.trim();
    }
    if (media != null && media.isNotEmpty) {
      payload['media'] = media.map((m) => m.toJson()).toList();
    }
    final data = await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/posts',
        method: HttpMethod.POST,
        body: payload,
      ),
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<GroupPostMediaUpload> uploadPostMedia(
    String groupId,
    File file,
  ) async {
    final base = AppData.nodeApiUrl.endsWith('/')
        ? AppData.nodeApiUrl.substring(0, AppData.nodeApiUrl.length - 1)
        : AppData.nodeApiUrl;
    final uri = Uri.parse('$base$_groups/$groupId/posts/media');
    final request = http.MultipartRequest('POST', uri);

    final token = AppData.userToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.headers.addAll(ActingContextService.instance.actingHeaders());

    final name = file.path.split('/').last.toLowerCase();
    var mime = 'image/jpeg';
    if (name.endsWith('.png')) mime = 'image/png';
    if (name.endsWith('.webp')) mime = 'image/webp';
    if (name.endsWith('.gif')) mime = 'image/gif';
    if (name.endsWith('.mp4')) mime = 'video/mp4';
    if (name.endsWith('.mov')) mime = 'video/quicktime';

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType.parse(mime),
    ));

    final streamed = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw ApiException(message: 'Upload timed out', statusCode: 408),
    );
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map &&
        decoded['success'] == true) {
      final media = decoded['media'] as Map<String, dynamic>? ?? decoded;
      return GroupPostMediaUpload.fromJson(Map<String, dynamic>.from(media));
    }
    final message = decoded is Map
        ? (decoded['message']?.toString() ?? 'Upload failed')
        : 'Upload failed';
    throw ApiException(message: message, statusCode: response.statusCode);
  }

  static Future<void> moderatePost(
    String groupId, {
    required String postId,
    required String decision,
    String? notes,
  }) async {
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/posts',
        method: HttpMethod.PATCH,
        body: {
          'postId': postId,
          'decision': decision,
          if (notes != null) 'notes': notes,
        },
      ),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
