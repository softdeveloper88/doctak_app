import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/auth_token_service.dart';

/// API service for network/connections/friend requests
/// Uses compatibility endpoints exposed by the migrated Node backend.
class NetworkApiService {
  static final NetworkApiService _instance = NetworkApiService._internal();
  factory NetworkApiService() => _instance;
  NetworkApiService._internal();

  final AuthTokenService _auth = AuthTokenService.instance;

  String get _baseUrl => AppData.remoteUrl2;

  String _normalizeRequestType(String type) {
    switch (type) {
      case 'received':
        return 'incoming';
      case 'sent':
        return 'outgoing';
      default:
        return type;
    }
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await _auth.get(url);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('NetworkApiService._get FAILED: $url → ${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
    throw Exception('API Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await _auth.delete(url);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('NetworkApiService._delete FAILED: $url → ${response.statusCode}');
    throw Exception('API Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _post(String endpoint, [Map<String, String>? body]) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await _auth.post(url, body: body ?? {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('NetworkApiService._post FAILED: $url → ${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
    throw Exception('API Error: ${response.statusCode} ${response.body}');
  }

  // ── Network Home (bootstrap) ──
  Future<Map<String, dynamic>> getNetworkHome() async {
    try {
      return await _get('/network/home');
    } catch (e) {
      print('NetworkApiService.getNetworkHome ERROR: $e');
      rethrow;
    }
  }

  // ── Organizations / Businesses ──
  Future<Map<String, dynamic>> getNetworkBusinesses({
    String search = '',
    int page = 1,
    int limit = 12,
  }) async {
    try {
      final q = search.isNotEmpty ? '&search=${Uri.encodeQueryComponent(search)}' : '';
      return await _get('/network/businesses?page=$page&limit=$limit$q');
    } catch (e) {
      print('NetworkApiService.getNetworkBusinesses ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> followOrganization(String organizationId) async {
    try {
      return await _post('/organizations/$organizationId/follow');
    } catch (e) {
      print('NetworkApiService.followOrganization ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> unfollowOrganization(String organizationId) async {
    try {
      return await _delete('/organizations/$organizationId/follow');
    } catch (e) {
      print('NetworkApiService.unfollowOrganization ERROR: $e');
      rethrow;
    }
  }

  // ── Network Stats ──
  Future<Map<String, dynamic>> getNetworkStats() async {
    try {
      return await _get('/network-stats');
    } catch (e) {
      print('Error fetching network stats: $e');
      return {};
    }
  }

  // ── Connections ──
  Future<Map<String, dynamic>> getConnections({
    String search = '',
    int page = 1,
    String viewUserId = '',
  }) async {
    try {
      final endpoint = viewUserId.isNotEmpty
          ? '/connections/$viewUserId?search=$search&page=$page'
          : '/connections?search=$search&page=$page';
      return await _get(endpoint);
    } catch (e) {
      print('NetworkApiService.getConnections ERROR: $e');
      rethrow;
    }
  }

  // ── Friend Requests ──
  Future<Map<String, dynamic>> getFriendRequests({
    String type = 'received',
    String status = 'pending',
    String search = '',
    int page = 1,
  }) async {
    final normalizedType = _normalizeRequestType(type);
    final endpoint = '/friend-requests?type=$normalizedType&status=$status&search=$search&page=$page';
    try {
      final result = await _get(endpoint);
      print('NetworkApiService.getFriendRequests($normalizedType) OK: keys=${result.keys.toList()}, total=${result['total']}');
      return result;
    } catch (e) {
      print('NetworkApiService.getFriendRequests($normalizedType) ERROR: $e');
      rethrow;
    }
  }

  // ── Send Friend Request ──
  Future<Map<String, dynamic>> sendFriendRequest(String userId) async {
    try {
      return await _post('/friend-request/send/$userId');
    } catch (e) {
      print('NetworkApiService.sendFriendRequest ERROR: $e');
      rethrow;
    }
  }

  // ── Accept Friend Request ──
  Future<Map<String, dynamic>> acceptFriendRequest(String requestId) async {
    try {
      return await _post('/friend-request/accept/$requestId');
    } catch (e) {
      print('NetworkApiService.acceptFriendRequest ERROR: $e');
      rethrow;
    }
  }

  /// Resolve a pending received request id for [targetUserId].
  ///
  /// This is used by profile/chat/call flows where we only know the user id,
  /// but the accept endpoint requires the friend request id.
  Future<String?> findPendingReceivedRequestIdByUserId(
    String targetUserId, {
    int maxPages = 3,
  }) async {
    for (int page = 1; page <= maxPages; page++) {
      final result = await getFriendRequests(type: 'received', status: 'pending', page: page);
      final requestsObj = result['requests'];
      final List<dynamic> data = requestsObj is Map
          ? (requestsObj['data'] as List<dynamic>? ?? [])
          : (result['data'] as List<dynamic>? ?? []);

      for (final item in data) {
        if (item is! Map) continue;
        final request = Map<String, dynamic>.from(item);

        final senderId =
            request['sender_id']?.toString() ??
            request['senderId']?.toString() ??
            (request['sender'] is Map
                ? (request['sender']['id']?.toString() ?? request['sender']['user_id']?.toString())
                : null) ??
            request['user_id']?.toString() ??
            request['userId']?.toString();

        if (senderId == targetUserId) {
          return request['id']?.toString() ??
              request['friend_request_id']?.toString() ??
              request['friendRequestId']?.toString() ??
              request['request_id']?.toString() ??
              request['requestId']?.toString();
        }
      }

      final currentPage = int.tryParse(result['current_page']?.toString() ?? '') ?? page;
      final lastPage = int.tryParse(result['last_page']?.toString() ?? '') ?? page;
      if (currentPage >= lastPage) break;
    }

    return null;
  }

  // ── Reject Friend Request ──
  Future<Map<String, dynamic>> rejectFriendRequest(String requestId) async {
    try {
      return await _post('/friend-request/reject/$requestId');
    } catch (e) {
      print('NetworkApiService.rejectFriendRequest ERROR: $e');
      rethrow;
    }
  }

  // ── Cancel Sent Friend Request ──
  Future<Map<String, dynamic>> cancelFriendRequest(String requestId) async {
    try {
      return await _post('/friend-request/cancel/$requestId');
    } catch (e) {
      print('NetworkApiService.cancelFriendRequest ERROR: $e');
      rethrow;
    }
  }

  // ── Remove Connection ──
  Future<Map<String, dynamic>> removeConnection(String userId) async {
    try {
      return await _post('/remove-connection', {'user_id': userId});
    } catch (e) {
      print('NetworkApiService.removeConnection ERROR: $e');
      rethrow;
    }
  }

  // ── People You May Know ──
  Future<Map<String, dynamic>> getPeopleYouMayKnow({String search = '', int page = 1}) async {
    try {
      return await _get('/people-you-may-know?search=$search&page=$page&limit=10');
    } catch (e) {
      print('NetworkApiService.getPeopleYouMayKnow ERROR: $e');
      rethrow;
    }
  }

  // ── Network Search (with connection status + filters) ──
  Future<Map<String, dynamic>> networkSearch({
    String query = '',
    int page = 1,
    int limit = 20,
    String specialty = '',
    String country = '',
    String type = 'all',
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
        'type': type,
      };
      if (query.isNotEmpty) params['q'] = query;
      if (specialty.isNotEmpty) params['specialty'] = specialty;
      if (country.isNotEmpty) params['country'] = country;
      final qs = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      return await _get('/network-search?$qs');
    } catch (e) {
      print('NetworkApiService.networkSearch ERROR: $e');
      rethrow;
    }
  }

  // ── Quick Search Suggestions (typeahead) ──
  Future<Map<String, dynamic>> searchSuggestions({
    required String query,
    int limit = 7,
    String type = 'all',
  }) async {
    try {
      final q = Uri.encodeQueryComponent(query);
      final t = Uri.encodeQueryComponent(type);
      return await _get('/search-suggestions?q=$q&limit=$limit&type=$t');
    } catch (e) {
      print('NetworkApiService.searchSuggestions ERROR: $e');
      rethrow;
    }
  }
}
