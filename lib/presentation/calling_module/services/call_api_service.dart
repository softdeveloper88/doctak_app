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

      debugPrint(
        'Token loaded: ${_cachedToken != null ? 'Success' : 'Not found'}',
      );
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
  Future<Map<String, dynamic>> initiateCall({
    required String userId,
    required bool hasVideo,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/initiate'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'hasVideo': hasVideo}),
      );

      final responseData = jsonDecode(response.body);
      print('Initiate call response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to initiate call');
      }
    } catch (e) {
      debugPrint('Error initiating call: $e');
      rethrow;
    }
  }

  // Accept an incoming call with async headers
  Future<Map<String, dynamic>> acceptCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/accept'),
        headers: headers,
        body: jsonEncode({'callId': callId, 'callerId': callerId}),
      );

      final responseData = jsonDecode(response.body);
      print('Accept call response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to accept call');
      }
    } catch (e) {
      debugPrint('Error accepting call: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> callRinging({
    required String callId,
    required String callerId,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/ringing'),
        headers: headers,
        body: jsonEncode({'callId': callId, 'callerId': callerId}),
      );

      final responseData = jsonDecode(response.body);
      print('Ringing call response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update ringing status',
        );
      }
    } catch (e) {
      debugPrint('Error updating ringing status: $e');
      rethrow;
    }
  }

  // Reject an incoming call with async headers
  Future<Map<String, dynamic>> rejectCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/reject'),
        headers: headers,
        body: jsonEncode({'callId': callId, 'callerId': callerId}),
      );

      final responseData = jsonDecode(response.body);
      print('Reject call response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to reject call');
      }
    } catch (e) {
      debugPrint('Error rejecting call: $e');
      rethrow;
    }
  }

  // End an ongoing call with async headers
  Future<Map<String, dynamic>> endCall({required String callId}) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/end'),
        headers: headers,
        body: jsonEncode({'callId': callId}),
      );

      final responseData = jsonDecode(response.body);
      print('End call response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to end call');
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  // Send a busy signal with async headers
  Future<Map<String, dynamic>> sendBusySignal({
    required String callId,
    required String callerId,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/busy'),
        headers: headers,
        body: jsonEncode({'callId': callId, 'callerId': callerId}),
      );

      final responseData = jsonDecode(response.body);
      print('Busy signal response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to send busy signal',
        );
      }
    } catch (e) {
      debugPrint('Error sending busy signal: $e');
      rethrow;
    }
  }

  // Mark a call as missed with async headers
  Future<Map<String, dynamic>> missCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/miss'),
        headers: headers,
        body: jsonEncode({'callId': callId, 'callerId': callerId}),
      );
      final responseData = jsonDecode(response.body);
      print('Miss call response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to mark call as missed',
        );
      }
    } catch (e) {
      debugPrint('Error marking call as missed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCallStatus() async {
    try {
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/get-call-status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          'Error getting call status: ${response.statusCode}, ${response.body}',
        );
        return {'is_active': false};
      }
    } catch (e) {
      print('Exception in getCallStatus: $e');
      return {'is_active': false};
    }
  }

  // Update call ringing status with async headers
  Future<Map<String, dynamic>> updateCallRingingStatus({
    required String callId,
  }) async {
    try {
      // Get headers with token
      final headers = await _getHeadersAsync();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/ringing'),
        headers: headers,
        body: jsonEncode({'callId': callId, 'status': 'ringing'}),
      );

      final responseData = jsonDecode(response.body);
      print('Update call ringing status response: ${response.body}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update call ringing status',
        );
      }
    } catch (e) {
      debugPrint('Error updating call ringing status: $e');
      rethrow;
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

      final response = await http.post(
        Uri.parse('$baseUrl/generate-agora-token'),
        headers: headers,
        body: jsonEncode({
          'channelId': channelId,
          'uid': uid,
          'expirationTime': expirationTime,
        }),
      );

      final responseData = jsonDecode(response.body);
      debugPrint('Generate Agora token response: ${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        final token = responseData['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          debugPrint(
            '✅ Agora token generated successfully (length: ${token.length})',
          );
          return token;
        } else {
          throw Exception('Empty token received from server');
        }
      } else {
        final errorMsg =
            responseData['message'] ?? 'Failed to generate Agora token';
        debugPrint('❌ Token generation failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Error generating Agora token: $e');
      // Return empty string as fallback (allows for development without token server)
      return '';
    }
  }
}
