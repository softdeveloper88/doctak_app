import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;

/// Model representing communication permission between current user and a target user.
class CommunicationPermission {
  final bool canMessage;
  final bool canCall;
  final String? reason;
  final String? reasonCode; // 'blocked', 'not_connected', null
  final String connectionStatus; // 'connected', 'pending_sent', 'pending_received', 'none'
  final bool isBlocked;
  final String? blockedDirection; // 'you_blocked', 'blocked_you', 'mutual', null
  final String? pendingRequestId; // request id when status is pending_received/pending_sent

  const CommunicationPermission({
    required this.canMessage,
    required this.canCall,
    this.reason,
    this.reasonCode,
    required this.connectionStatus,
    required this.isBlocked,
    this.blockedDirection,
    this.pendingRequestId,
  });

  /// Fully allowed
  static const allowed = CommunicationPermission(
    canMessage: true,
    canCall: true,
    connectionStatus: 'connected',
    isBlocked: false,
  );

  /// Default fallback (allow to avoid blocking users due to network errors)
  static const fallback = CommunicationPermission(
    canMessage: true,
    canCall: true,
    connectionStatus: 'unknown',
    isBlocked: false,
  );

  factory CommunicationPermission.fromJson(Map<String, dynamic> json) {
    return CommunicationPermission(
      canMessage: json['can_message'] ?? true,
      canCall: json['can_call'] ?? true,
      reason: json['reason'],
      reasonCode: json['reason_code'],
      connectionStatus: json['connection_status'] ?? 'unknown',
      isBlocked: json['is_blocked'] ?? false,
      blockedDirection: json['blocked_direction'],
      pendingRequestId:
          json['friend_request_id']?.toString() ??
          json['friendRequestId']?.toString() ??
          json['request_id']?.toString() ??
          json['requestId']?.toString(),
    );
  }

  bool get isRestricted => !canMessage || !canCall;
}

/// Service to check communication permissions via v5 API.
class CommunicationService {
  static final CommunicationService _instance = CommunicationService._internal();
  factory CommunicationService() => _instance;
  CommunicationService._internal();

  String get _baseUrl => AppData.remoteUrl2.replaceAll('/v4', '/v5');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppData.userToken}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Check communication permission for a single user.
  Future<CommunicationPermission> checkPermission(String targetUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/communication/check/$targetUserId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CommunicationPermission.fromJson(data);
      }
      return CommunicationPermission.fallback;
    } catch (e) {
      print('CommunicationService.checkPermission error: $e');
      return CommunicationPermission.fallback;
    }
  }

  /// Batch-check communication permissions for multiple users.
  Future<Map<String, CommunicationPermission>> checkBatch(List<String> userIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/communication/check-batch'),
        headers: _headers,
        body: jsonEncode({'user_ids': userIds}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final permissions = data['permissions'] as Map<String, dynamic>? ?? {};
        return permissions.map(
          (key, value) => MapEntry(key, CommunicationPermission.fromJson(value)),
        );
      }
      return {};
    } catch (e) {
      print('CommunicationService.checkBatch error: $e');
      return {};
    }
  }
}
