import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CallApiService {
  // Base URL of your backend API
  final String baseUrl;

  // Authentication token
  final String? authToken;

  CallApiService({
    required this.baseUrl,
    this.authToken,
  });

  // Create headers with authentication
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  // Initiate a call
  Future<Map<String, dynamic>> initiateCall({
    required String userId,
    required bool hasVideo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/initiate'),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'hasVideo': hasVideo,
        }),
      );

      final responseData = jsonDecode(response.body);

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

  // Accept an incoming call
  Future<Map<String, dynamic>> acceptCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/accept'),
        headers: _headers,
        body: jsonEncode({
          'callId': callId,
          'callerId': callerId,
        }),
      );

      final responseData = jsonDecode(response.body);

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

  // Reject an incoming call
  Future<Map<String, dynamic>> rejectCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/reject'),
        headers: _headers,
        body: jsonEncode({
          'callId': callId,
          'callerId': callerId,
        }),
      );

      final responseData = jsonDecode(response.body);

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

  // End an ongoing call
  Future<Map<String, dynamic>> endCall({
    required String callId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/end'),
        headers: _headers,
        body: jsonEncode({
          'callId': callId,
        }),
      );

      final responseData = jsonDecode(response.body);

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

  // Send a busy signal
  Future<Map<String, dynamic>> sendBusySignal({
    required String callId,
    required String callerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/busy'),
        headers: _headers,
        body: jsonEncode({
          'callId': callId,
          'callerId': callerId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to send busy signal');
      }
    } catch (e) {
      debugPrint('Error sending busy signal: $e');
      rethrow;
    }
  }

  // Mark a call as missed
  Future<Map<String, dynamic>> missCall({
    required String callId,
    required String callerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/miss'),
        headers: _headers,
        body: jsonEncode({
          'callId': callId,
          'callerId': callerId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to mark call as missed');
      }
    } catch (e) {
      debugPrint('Error marking call as missed: $e');
      rethrow;
    }
  }

  // Get Agora token for a call
  Future<Map<String, dynamic>> getCallToken({
    required String callId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/token'),
        headers: _headers,
        body: jsonEncode({
          'callId': callId,
          'userId': userId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get call token');
      }
    } catch (e) {
      debugPrint('Error getting call token: $e');
      rethrow;
    }
  }

  // Register device token for push notifications
  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String deviceType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/device-tokens/register'),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'device_type': deviceType,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to register device token');
      }
    } catch (e) {
      debugPrint('Error registering device token: $e');
      rethrow;
    }
  }

  // Update user call status
  Future<Map<String, dynamic>> updateCallStatus({
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/calls/status'),
        headers: _headers,
        body: jsonEncode({
          'status': status,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update call status');
      }
    } catch (e) {
      debugPrint('Error updating call status: $e');
      rethrow;
    }
  }
}