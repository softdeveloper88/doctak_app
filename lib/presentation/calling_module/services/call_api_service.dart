import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

class CallApiService {
  // Base URL of your backend API
  final String baseUrl;
  String? _cachedToken;
  bool _isTokenLoading = false;

  CallApiService({required this.baseUrl}) {
    // Load token when service is created
    _loadToken();
  }

  /// Safely parse JSON response, handling HTML error pages gracefully
  Map<String, dynamic> _safeJsonDecode(http.Response response, String operation) {
    final body = response.body;

    // Check if response is HTML (error page)
    if (body.trimLeft().startsWith('<!DOCTYPE') || body.trimLeft().startsWith('<html') || body.trimLeft().startsWith('<HTML')) {
      debugPrint('⚠️ Server returned HTML instead of JSON for $operation');
      debugPrint('Status code: ${response.statusCode}');

      // Return error response based on status code
      String errorMessage;
      switch (response.statusCode) {
        case 401:
          errorMessage = 'Authentication failed. Please login again.';
          break;
        case 403:
          errorMessage = 'Access denied. You don\'t have permission.';
          break;
        case 404:
          errorMessage = 'Service not available. Please try again later.';
          break;
        case 500:
        case 502:
        case 503:
          errorMessage = 'Server error. Please try again later.';
          break;
        default:
          errorMessage = 'Network error. Please check your connection.';
      }

      return {'success': false, 'message': errorMessage, 'error_type': 'html_response', 'status_code': response.statusCode};
    }

    // Check if body is empty
    if (body.isEmpty) {
      debugPrint('⚠️ Empty response body for $operation');
      return {'success': false, 'message': 'Empty response from server', 'error_type': 'empty_response'};
    }

    // Try to parse as JSON
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        // Convert Map to Map<String, dynamic>
        return Map<String, dynamic>.from(decoded);
      } else {
        debugPrint('⚠️ Unexpected JSON type for $operation: ${decoded.runtimeType}');
        return {'success': false, 'message': 'Invalid response format', 'error_type': 'invalid_json_type'};
      }
    } catch (e) {
      debugPrint('⚠️ JSON parse error for $operation: $e');
      debugPrint('Response body preview: ${body.substring(0, body.length > 200 ? 200 : body.length)}');
      return {'success': false, 'message': 'Failed to parse server response', 'error_type': 'json_parse_error'};
    }
  }

  // Load and cache the token
  Future<void> _loadToken() async {
    if (_isTokenLoading) return;

    _isTokenLoading = true;
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      _cachedToken = await prefs.getString('token');

      // Fall back to AppData token if needed
      if (_cachedToken == null || _cachedToken!.isEmpty) {
        _cachedToken = AppData.userToken;
      }

      debugPrint('Token loaded: ${_cachedToken != null ? 'Success' : 'Not found'}');
    } catch (e) {
      debugPrint('Error loading token: $e');
      _cachedToken = AppData.userToken; // Fallback
    } finally {
      _isTokenLoading = false;
    }
  }

  // Get current headers - safe synchronous version
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};

    // Only add token if we have it
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }

    return headers;
  }

  // Wait for token and get headers - async version for ensuring token is loaded
  Future<Map<String, String>> _getHeadersAsync() async {
    // If token is not loaded yet, wait for it
    if (_cachedToken == null && !_isTokenLoading) {
      await _loadToken();
    } else if (_isTokenLoading) {
      // Wait for ongoing token loading to complete
      while (_isTokenLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    final headers = {'Content-Type': 'application/json'};

    // Add token if available
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }

    return headers;
  }

  // Initiate a call with async headers
  Future<Map<String, dynamic>> initiateCall({required String userId, required bool hasVideo}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/initiate'), headers: headers, body: jsonEncode({'userId': userId, 'hasVideo': hasVideo}));

      final responseData = _safeJsonDecode(response, 'initiateCall');
      debugPrint('Initiate call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        // Return the error response instead of throwing
        return {'success': false, 'callId': 'error', 'message': responseData['message'] ?? 'Failed to initiate call'};
      }
    } catch (e) {
      debugPrint('Error initiating call: $e');
      return {'success': false, 'callId': 'error', 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  // Accept an incoming call with async headers
  Future<Map<String, dynamic>> acceptCall({required String callId, required String callerId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/accept'), headers: headers, body: jsonEncode({'callId': callId, 'callerId': callerId}));

      final responseData = _safeJsonDecode(response, 'acceptCall');
      debugPrint('Accept call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to accept call'};
      }
    } catch (e) {
      debugPrint('Error accepting call: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  Future<Map<String, dynamic>> callRinging({required String callId, required String callerId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/ringing'), headers: headers, body: jsonEncode({'callId': callId, 'callerId': callerId}));

      final responseData = _safeJsonDecode(response, 'callRinging');
      debugPrint('Ringing call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to update ringing status'};
      }
    } catch (e) {
      debugPrint('Error updating ringing status: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  // Reject an incoming call with async headers
  Future<Map<String, dynamic>> rejectCall({required String callId, required String callerId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/reject'), headers: headers, body: jsonEncode({'callId': callId, 'callerId': callerId}));

      final responseData = _safeJsonDecode(response, 'rejectCall');
      debugPrint('Reject call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to reject call'};
      }
    } catch (e) {
      debugPrint('Error rejecting call: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  // Cancel an outgoing call (caller cancels before callee answers)
  Future<Map<String, dynamic>> cancelCall({required String callId, required String calleeId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/cancel'), headers: headers, body: jsonEncode({'callId': callId, 'calleeId': calleeId}));

      final responseData = _safeJsonDecode(response, 'cancelCall');
      debugPrint('Cancel call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        // If the cancel endpoint doesn't exist, try using end endpoint
        return await endCall(callId: callId);
      }
    } catch (e) {
      debugPrint('Error cancelling call: $e');
      // Fallback to end call
      return await endCall(callId: callId);
    }
  }

  // End an ongoing call with async headers
  Future<Map<String, dynamic>> endCall({required String callId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/end'), headers: headers, body: jsonEncode({'callId': callId}));

      final responseData = _safeJsonDecode(response, 'endCall');
      debugPrint('End call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to end call'};
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  // Send a busy signal with async headers
  Future<Map<String, dynamic>> sendBusySignal({required String callId, required String callerId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/busy'), headers: headers, body: jsonEncode({'callId': callId, 'callerId': callerId}));

      final responseData = _safeJsonDecode(response, 'sendBusySignal');
      debugPrint('Busy signal response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to send busy signal'};
      }
    } catch (e) {
      debugPrint('Error sending busy signal: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  // Mark a call as missed with async headers
  Future<Map<String, dynamic>> missCall({required String callId, required String callerId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/miss'), headers: headers, body: jsonEncode({'callId': callId, 'callerId': callerId}));
      final responseData = _safeJsonDecode(response, 'missCall');
      debugPrint('Miss call response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to mark call as missed'};
      }
    } catch (e) {
      debugPrint('Error marking call as missed: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  Future<Map<String, dynamic>> getCallStatus() async {
    try {
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/get-call-status'), headers: headers);

      final responseData = _safeJsonDecode(response, 'getCallStatus');
      if (response.statusCode == 200 && responseData['error_type'] == null) {
        return responseData;
      } else {
        debugPrint('Error getting call status: ${response.statusCode}');
        return {'is_active': false};
      }
    } catch (e) {
      debugPrint('Exception in getCallStatus: $e');
      return {'is_active': false};
    }
  }

  /// Check if a specific call is still active on the server
  /// Returns true if call is active, false otherwise
  Future<Map<String, dynamic>> checkCallActive({required String callId}) async {
    try {
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/check-active'), headers: headers, body: jsonEncode({'callId': callId}));

      final responseData = _safeJsonDecode(response, 'checkCallActive');
      debugPrint('Check call active response: status=${response.statusCode}');

      if (response.statusCode == 200) {
        // Be more generous with what we consider "active"
        // Include more statuses that indicate the call is still valid
        final status = responseData['status']?.toString().toLowerCase() ?? 'unknown';
        final isActive =
            responseData['is_active'] == true ||
            responseData['active'] == true ||
            status == 'active' ||
            status == 'ringing' ||
            status == 'accepted' ||
            status == 'connecting' ||
            status == 'connected' ||
            status == 'in_progress' ||
            status == 'in-progress' ||
            status == 'ongoing';
        return {'success': true, 'is_active': isActive, 'status': status, 'message': responseData['message']};
      } else {
        return {'success': false, 'is_active': false, 'status': 'unknown', 'message': responseData['message'] ?? 'Failed to check call status'};
      }
    } catch (e) {
      debugPrint('Error checking call active status: $e');
      return {
        'success': false,
        'is_active': true, // Assume active on error to not prematurely end calls
        'status': 'error',
        'message': 'Network error',
      };
    }
  }

  // Update call ringing status with async headers
  Future<Map<String, dynamic>> updateCallRingingStatus({required String callId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/calls/ringing'), headers: headers, body: jsonEncode({'callId': callId, 'status': 'ringing'}));

      final responseData = _safeJsonDecode(response, 'updateCallRingingStatus');
      debugPrint('Update call ringing status response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to update call ringing status'};
      }
    } catch (e) {
      debugPrint('Error updating call ringing status: $e');
      return {'success': false, 'message': 'Network error: ${e.toString().split(':').last.trim()}'};
    }
  }

  /// Generate Agora token for secure channel access
  Future<String> generateAgoraToken({
    required String channelId,
    required int uid,
    int expirationTime = 3600, // Default 1 hour
  }) async {
    try {
      final headers = await _getHeadersAsync();

      final response = await http.post(Uri.parse('$baseUrl/generate-agora-token'), headers: headers, body: jsonEncode({'channelId': channelId, 'uid': uid, 'expirationTime': expirationTime}));

      final responseData = _safeJsonDecode(response, 'generateAgoraToken');
      debugPrint('Generate Agora token response: status=${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        final token = responseData['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          debugPrint('✅ Agora token generated successfully (length: ${token.length})');
          return token;
        } else {
          debugPrint('⚠️ Empty token received from server');
          return '';
        }
      } else {
        final errorMsg = responseData['message'] ?? 'Failed to generate Agora token';
        debugPrint('❌ Token generation failed: $errorMsg');
        return '';
      }
    } catch (e) {
      debugPrint('❌ Error generating Agora token: $e');
      // Return empty string as fallback (allows for development without token server)
      return '';
    }
  }
}
