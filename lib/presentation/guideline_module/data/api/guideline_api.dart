import 'dart:convert';

import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/guideline_chat_model.dart';
import '../models/guideline_source_model.dart';

/// Base URL for v6 API
String get _baseUrl => AppData.remoteUrlV6;

/// Auth headers helper
Map<String, String> _authHeaders({bool json = false}) {
  final headers = <String, String>{};
  if (json) headers['Content-Type'] = 'application/json';
  if (AppData.userToken != null && AppData.userToken!.isNotEmpty) {
    headers['Authorization'] = 'Bearer ${AppData.userToken}';
  }
  return headers;
}

// ─── Sources ──────────────────────────────────────────────────────────────

/// Fetch all active guideline sources
Future<List<GuidelineSourceModel>> getGuidelineSources() async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/sources',
      method: networkUtils.HttpMethod.GET,
    );
    final response = await networkUtils.handleResponse(rawResponse);
    final data = response['data'] as List? ?? [];
    return data.map((e) => GuidelineSourceModel.fromJson(e)).toList();
  } catch (e) {
    debugPrint('getGuidelineSources error: $e');
    rethrow;
  }
}

// ─── Suggested Topics ─────────────────────────────────────────────────────

/// Fetch suggested topics for the welcome screen
Future<List<GuidelineSuggestedTopic>> getSuggestedTopics() async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/suggested-topics',
      method: networkUtils.HttpMethod.GET,
    );
    final response = await networkUtils.handleResponse(rawResponse);
    final data = response['data'] as List? ?? [];
    return data.map((e) => GuidelineSuggestedTopic.fromJson(e)).toList();
  } catch (e) {
    debugPrint('getSuggestedTopics error: $e');
    rethrow;
  }
}

// ─── Sessions / Conversations ─────────────────────────────────────────────

/// Fetch user's chat sessions
Future<List<GuidelineChatSession>> getGuidelineSessions() async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/sessions',
      method: networkUtils.HttpMethod.GET,
    );
    final response = await networkUtils.handleResponse(rawResponse);
    final data = response['data'] as List? ?? [];
    return data.map((e) => GuidelineChatSession.fromJson(e)).toList();
  } catch (e) {
    debugPrint('getGuidelineSessions error: $e');
    rethrow;
  }
}

/// Fetch messages for a specific session
Future<List<GuidelineChatMessage>> getSessionMessages(String sessionId) async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/sessions/$sessionId/messages',
      method: networkUtils.HttpMethod.GET,
    );
    final response = await networkUtils.handleResponse(rawResponse);
    final data = response['data'] as List? ?? [];
    return data.map((e) => GuidelineChatMessage.fromJson(e)).toList();
  } catch (e) {
    debugPrint('getSessionMessages error: $e');
    rethrow;
  }
}

/// Delete a conversation session
Future<bool> deleteGuidelineSession(String sessionId) async {
  try {
    final url = Uri.parse('$_baseUrl/guidelines/sessions/$sessionId');
    final response = await http.delete(url, headers: _authHeaders())
        .timeout(const Duration(seconds: 30));
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('deleteGuidelineSession error: $e');
    return false;
  }
}

// ─── Send Message (AI Chat) ───────────────────────────────────────────────

/// Send a query to the Guideline Agent and get AI response
Future<Map<String, dynamic>> sendGuidelineMessage({
  required String query,
  required String sessionId,
  required List<String> sources,
}) async {
  try {
    final url = Uri.parse('$_baseUrl/guidelines/send-message');
    final headers = _authHeaders(json: true);
    final body = jsonEncode({
      'query': query,
      'session_id': sessionId,
      'sources': sources,
    });
    debugPrint('🔵 V6 API POST: $url');
    debugPrint('Request: $body');
    final raw = await http.post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 60));
    debugPrint('Response (v6 POST): ${url} ${raw.statusCode} ${raw.body}');
    final response = await networkUtils.handleResponse(raw);
    return response;
  } catch (e) {
    debugPrint('sendGuidelineMessage error: $e');
    rethrow;
  }
}

// ─── Feedback ─────────────────────────────────────────────────────────────

/// Submit feedback for a message
Future<bool> submitGuidelineFeedback({
  required int messageId,
  required String rating,
}) async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/feedback',
      method: networkUtils.HttpMethod.POST,
      request: {
        'message_id': messageId.toString(),
        'rating': rating,
      },
    );
    final response = await networkUtils.handleResponse(rawResponse);
    return response['success'] == true;
  } catch (e) {
    debugPrint('submitGuidelineFeedback error: $e');
    return false;
  }
}

// ─── Clear Session ────────────────────────────────────────────────────────

/// Clear session memory on server
Future<bool> clearGuidelineSession(String sessionId) async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/clear-session',
      method: networkUtils.HttpMethod.POST,
      request: {'session_id': sessionId},
    );
    final response = await networkUtils.handleResponse(rawResponse);
    return response['success'] == true;
  } catch (e) {
    debugPrint('clearGuidelineSession error: $e');
    return false;
  }
}

// ─── Usage / Quota ────────────────────────────────────────────────────────

/// Get current guideline AI usage/quota
Future<GuidelineUsageInfo?> getGuidelineUsage() async {
  try {
    final rawResponse = await networkUtils.buildHttpResponseV6(
      '/guidelines/usage',
      method: networkUtils.HttpMethod.GET,
    );
    final response = await networkUtils.handleResponse(rawResponse);
    if (response['usage'] != null) {
      return GuidelineUsageInfo.fromJson(response['usage']);
    }
    return null;
  } catch (e) {
    debugPrint('getGuidelineUsage error: $e');
    return null;
  }
}
