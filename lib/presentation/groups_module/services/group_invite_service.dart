import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';

/// Loads connections eligible for group invites (v1 API + connections fallback).
class GroupInviteService {
  GroupInviteService._();
  static final GroupInviteService instance = GroupInviteService._();

  static const _groups = '/api/v1/groups';

  Future<List<GroupUserStubModel>> loadCandidates(
    String groupId, {
    String? query,
  }) async {
    try {
      return await _fetchFromGroupApi(groupId, query: query);
    } catch (_) {
      return _fetchFromConnections(query: query);
    }
  }

  Future<void> sendInvite(
    String groupId, {
    required String inviteeId,
    String? message,
  }) async {
    final body = <String, dynamic>{'inviteeId': inviteeId};
    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }
    await handleResponse(
      await buildHttpResponseNode(
        '$_groups/$groupId/invitations',
        method: HttpMethod.POST,
        body: body,
      ),
    );
  }

  Future<List<GroupUserStubModel>> _fetchFromGroupApi(
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
    return _parseUserList(data['items']);
  }

  Future<List<GroupUserStubModel>> _fetchFromConnections({String? query}) async {
    final result = await NetworkApiService().getConnections(
      search: query?.trim() ?? '',
      page: 1,
    );
    final connsObj = result['connections'];
    final Map<String, dynamic>? paginator =
        connsObj is Map ? Map<String, dynamic>.from(connsObj) : null;
    final data = paginator != null
        ? (paginator['data'] as List<dynamic>? ?? [])
        : (result['data'] as List<dynamic>? ?? []);

    return data.map((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final first = m['first_name']?.toString() ?? m['firstName']?.toString() ?? '';
      final last = m['last_name']?.toString() ?? m['lastName']?.toString() ?? '';
      final name = [first, last].where((s) => s.trim().isNotEmpty).join(' ').trim();
      return GroupUserStubModel(
        id: m['id']?.toString() ?? m['user_id']?.toString() ?? '',
        name: name.isNotEmpty
            ? name
            : (m['name']?.toString() ?? m['username']?.toString() ?? 'Connection'),
        avatar: m['profile_pic']?.toString() ?? m['profilePic']?.toString(),
        specialty: m['specialty']?.toString(),
        verified: m['verified'] == true,
      );
    }).where((u) => u.id.isNotEmpty).toList();
  }

  List<GroupUserStubModel> _parseUserList(dynamic raw) {
    return (raw as List<dynamic>? ?? [])
        .map((e) => GroupUserStubModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }
}
