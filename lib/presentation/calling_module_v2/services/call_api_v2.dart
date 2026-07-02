import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/call_protocol.dart';

/// Calling module v2 — REST control plane client.
///
/// Talks to the doctak-node `/api/calls/*` routes with the same Bearer token
/// the app already uses for other node routes (meetings, notifications).
/// The REST surface is only for control-plane operations; live signaling
/// flows over the per-call WebSocket ([CallSignalingV2]).
class CallApiV2 {
  CallApiV2._();
  static final CallApiV2 instance = CallApiV2._();

  String get _base {
    final base = AppData.nodeApiUrl;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  String? _cachedToken;

  /// Bearer token: AppData when populated, secure storage on cold starts
  /// (CallKit accept from a killed app runs before the splash flow loads
  /// AppData).
  Future<String?> _token() async {
    final fromAppData = AppData.userToken;
    if (fromAppData != null && fromAppData.isNotEmpty) return fromAppData;
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      _cachedToken = await prefs.getString('token');
    } catch (_) {}
    return _cachedToken;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse('$_base$path'), headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      return _decode(response, path);
    } catch (e) {
      debugPrint('📞 [CallApiV2] POST $path failed: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$_base$path'), headers: await _headers())
          .timeout(const Duration(seconds: 20));
      return _decode(response, path);
    } catch (e) {
      debugPrint('📞 [CallApiV2] GET $path failed: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Map<String, dynamic> _decode(http.Response response, String path) {
    final body = response.body;
    if (body.trimLeft().startsWith('<')) {
      debugPrint('📞 [CallApiV2] $path returned HTML (${response.statusCode})');
      return {'success': false, 'message': 'Server error ${response.statusCode}'};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {'success': false, 'message': 'Invalid response'};
  }

  /// Starts a call. Returns `{success, callId, wsUrl, reason?, message?}`.
  Future<Map<String, dynamic>> initiate({
    required String calleeId,
    required CallTypeV2 callType,
    required String deviceId,
    required String platform,
  }) {
    return _post('/api/calls/initiate', {
      'calleeId': calleeId,
      'callType': callType.wire,
      'deviceId': deviceId,
      'platform': platform,
    });
  }

  /// Fresh signaling socket URL for a call (used on answer-from-push and on
  /// socket reconnect).
  Future<String?> wsTicket({
    required String callId,
    required String deviceId,
    required String platform,
  }) async {
    final result = await _get(
      '/api/calls/ws-ticket?callId=${Uri.encodeComponent(callId)}'
      '&deviceId=${Uri.encodeComponent(deviceId)}&platform=$platform',
    );
    final wsUrl = result['wsUrl']?.toString();
    return (result['success'] == true && wsUrl != null && wsUrl.isNotEmpty) ? wsUrl : null;
  }

  /// REST fallback into the state machine for socket-less moments
  /// (CallKit decline from killed state, busy responses). `deviceId` marks
  /// this device as the media owner on accept (multi-device §6).
  Future<Map<String, dynamic>> action({
    required String callId,
    required String action,
    String? reason,
    String? deviceId,
  }) {
    return _post('/api/calls/${Uri.encodeComponent(callId)}/action', {
      'action': action,
      'reason': ?reason,
      'deviceId': ?deviceId,
    });
  }

  /// Authoritative snapshot — ghost-ring guard for stale pushes (edge 26).
  Future<CallSnapshotV2?> getCall(String callId) async {
    final result = await _get('/api/calls/${Uri.encodeComponent(callId)}');
    final call = result['call'];
    if (result['success'] == true && call is Map) {
      try {
        return CallSnapshotV2.fromJson(Map<String, dynamic>.from(call));
      } catch (_) {}
    }
    return null;
  }

  /// The user's current live call (reconcile after app restart).
  Future<({CallSnapshotV2 snapshot, String wsUrl})?> getActiveCall({
    required String deviceId,
    required String platform,
  }) async {
    final result = await _get(
      '/api/calls/active?deviceId=${Uri.encodeComponent(deviceId)}&platform=$platform',
    );
    final call = result['call'];
    final wsUrl = result['wsUrl']?.toString();
    if (result['success'] == true && call is Map && wsUrl != null && wsUrl.isNotEmpty) {
      try {
        return (
          snapshot: CallSnapshotV2.fromJson(Map<String, dynamic>.from(call)),
          wsUrl: wsUrl,
        );
      } catch (_) {}
    }
    return null;
  }

  /// Call history with missed flags.
  Future<List<Map<String, dynamic>>> history({int limit = 50, int offset = 0}) async {
    final result = await _get('/api/calls/history?limit=$limit&offset=$offset');
    final history = result['history'];
    if (result['success'] == true && history is List) {
      return history.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  /// iOS: registers the PushKit VoIP token for killed-app call delivery.
  Future<void> registerVoipToken({required String token, required String deviceId}) async {
    await _post('/api/calls/register-voip-token', {'token': token, 'deviceId': deviceId});
  }
}
