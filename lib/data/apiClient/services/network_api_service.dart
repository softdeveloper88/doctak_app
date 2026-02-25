import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;

/// API service for network/connections/friend requests
/// Uses v5 endpoints (/api/v5/...)
class NetworkApiService {
  static final NetworkApiService _instance = NetworkApiService._internal();
  factory NetworkApiService() => _instance;
  NetworkApiService._internal();

  String get _baseUrl => AppData.remoteUrl2.replaceAll('/v4', '/v5');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppData.userToken}',
    'Accept': 'application/json',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  Future<Map<String, dynamic>> _get(String endpoint) async {
    final url = '$_baseUrl$endpoint';
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('NetworkApiService._get FAILED: $url → ${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
    throw Exception('API Error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _post(String endpoint, [Map<String, String>? body]) async {
    final url = '$_baseUrl$endpoint';
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body ?? {},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    print('NetworkApiService._post FAILED: $url → ${response.statusCode} body=${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
    throw Exception('API Error: ${response.statusCode} ${response.body}');
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
  Future<Map<String, dynamic>> getConnections({String search = '', int page = 1}) async {
    try {
      return await _get('/connections?search=$search&page=$page');
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
    final endpoint = '/friend-requests?type=$type&status=$status&search=$search&page=$page';
    try {
      final result = await _get(endpoint);
      print('NetworkApiService.getFriendRequests($type) OK: keys=${result.keys.toList()}, total=${result['total']}');
      return result;
    } catch (e) {
      print('NetworkApiService.getFriendRequests($type) ERROR: $e');
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
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'limit': '$limit',
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
  Future<Map<String, dynamic>> searchSuggestions({required String query, int limit = 7}) async {
    try {
      final q = Uri.encodeQueryComponent(query);
      return await _get('/search-suggestions?q=$q&limit=$limit');
    } catch (e) {
      print('NetworkApiService.searchSuggestions ERROR: $e');
      rethrow;
    }
  }
}
