import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nb_utils/nb_utils.dart';

import '../models/ai_chat_model/ai_chat_message_model.dart';
import '../models/ai_chat_model/ai_chat_session_model.dart';

// Base URL constant to avoid string concatenation issues
String get baseUrl => AppData.remoteUrl3;

// Timeout durations
const Duration defaultTimeout = Duration(seconds: 45);
const Duration extendedTimeout = Duration(seconds: 180); // Increased to 3 minutes for UltraThink

/// Check network connectivity
Future<void> _checkConnectivity() async {
  try {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    final bool isConnected = !connectivityResult.contains(ConnectivityResult.none);

    if (!isConnected) {
      throw ApiException(message: "Network is not available. Please check your connection.", statusCode: 0);
    }
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException(message: "Network check failed: $e", statusCode: 0);
  }
}

/// Helper function to get auth headers
Map<String, String> _getAuthHeaders({bool isJson = false}) {
  Map<String, String> headers = {};

  if (isJson) {
    headers['Content-Type'] = 'application/json';
  }

  if (AppData.userToken != null) {
    headers['Authorization'] = 'Bearer ${AppData.userToken}';
  }

  return headers;
}

/// Helper function to determine MIME type from file
String _getMimeType(File file) {
  final filename = file.path.split('/').last.toLowerCase();

  if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) {
    return 'image/jpeg';
  } else if (filename.endsWith('.png')) {
    return 'image/png';
  } else if (filename.endsWith('.pdf')) {
    return 'application/pdf';
  } else if (filename.endsWith('.doc') || filename.endsWith('.docx')) {
    return 'application/msword';
  }

  return 'application/octet-stream';
}

/// Get all chat sessions
Future<List<AiChatSessionModel>> getChatSessions() async {
  try {
    final rawResponse = await networkUtils.buildHttpResponse2('/chat/sessions', method: networkUtils.HttpMethod.GET);

    final response = await networkUtils.handleResponse(rawResponse);

    return (response['data'] as List).map((session) => AiChatSessionModel.fromJson(session)).toList();
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}

/// Create a new chat session
Future<AiChatSessionModel> createChatSession({String? name}) async {
  try {
    final Map<String, dynamic> request = {};
    if (name != null) request['name'] = name;

    final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse2('/chat/sessions', method: networkUtils.HttpMethod.POST, request: request));

    return AiChatSessionModel.fromJson(response['data']);
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}

/// Get a specific chat session with its messages
Future<Map<String, dynamic>> getChatSession(String sessionId) async {
  try {
    final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse2('/chat/sessions/$sessionId', method: networkUtils.HttpMethod.GET));

    final session = AiChatSessionModel.fromJson(response['data']['session']);
    final messages = (response['data']['messages'] as List).map((message) => AiChatMessageModel.fromJson(message)).toList();

    return {'session': session, 'messages': messages};
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}

/// Send a message to the AI assistant
Future<Map<String, dynamic>> sendMessage({
  required String sessionId,
  required String message,
  required String model,
  double temperature = 0.7,
  int maxTokens = 1024,
  bool webSearch = false,
  String? searchContextSize,
  String? userLocationCountry,
  String? userLocationCity,
  String? userLocationRegion,
  File? file,
}) async {
  // 1. Check network connectivity first
  await _checkConnectivity();

  // 2. Prepare model parameters (handle special models like UltraThink)
  final modelParams = _prepareModelParameters(model, temperature, maxTokens);

  // 3. Decide on request method based on presence of file
  if (file == null) {
    return _sendTextOnlyMessage(
      sessionId: sessionId,
      message: message,
      modelParams: modelParams,
      webSearch: webSearch,
      searchContextSize: searchContextSize,
      locationParams: {'country': userLocationCountry, 'city': userLocationCity, 'region': userLocationRegion},
    );
  } else {
    return _sendMessageWithFile(
      sessionId: sessionId,
      message: message,
      modelParams: modelParams,
      webSearch: webSearch,
      searchContextSize: searchContextSize,
      locationParams: {'country': userLocationCountry, 'city': userLocationCity, 'region': userLocationRegion},
      file: file,
    );
  }
}

/// Prepare model parameters based on model type
Map<String, dynamic> _prepareModelParameters(String model, double temperature, int maxTokens) {
  // GPT-4o uses higher token limit and different parameters
  if (model.toLowerCase() == "gpt-4o") {
    return {
      'model': "gpt-4o", // GPT-4o model
      'temperature': 0.5, // Lower temperature for more precise thinking
      'maxTokens': 4000, // Higher token limit for more detailed responses
      'timeout': extendedTimeout,
    };
  }

  return {'model': model, 'temperature': temperature, 'maxTokens': maxTokens, 'timeout': defaultTimeout};
}

/// Send text-only message (JSON POST request)
Future<Map<String, dynamic>> _sendTextOnlyMessage({
  required String sessionId,
  required String message,
  required Map<String, dynamic> modelParams,
  required bool webSearch,
  String? searchContextSize,
  required Map<String, String?> locationParams,
}) async {
  // Prepare request body
  final Map<String, dynamic> requestBody = {
    'session_id': sessionId,
    'message': message,
    'model': modelParams['model'],
    'temperature': modelParams['temperature'].toString(),
    'max_tokens': modelParams['maxTokens'].toString(),
    'web_search': webSearch ? '1' : '0',
  };

  // Add optional parameters if provided
  if (webSearch) {
    // Only include search context size if web search is enabled
    if (searchContextSize != null) {
      requestBody['search_context_size'] = searchContextSize;
    } else {
      // Default to medium if not specified
      requestBody['search_context_size'] = 'medium';
    }
  }

  // Only include location parameters if web search is enabled
  if (webSearch) {
    locationParams.forEach((key, value) {
      if (value != null) {
        requestBody['user_location_$key'] = value;
      }
    });
  }

  // Get auth headers with JSON content type
  final headers = _getAuthHeaders(isJson: true);

  // Create URL
  final Uri messageUrl = Uri.parse('$baseUrl/chat/messages');

  try {
    // Make the API call
    final stopwatch = Stopwatch()..start();
    final response = await http
        .post(messageUrl, headers: headers, body: json.encode(requestBody))
        .timeout(
          modelParams['timeout'] as Duration,
          onTimeout: () {
            throw TimeoutException("Request timed out after ${(modelParams['timeout'] as Duration).inSeconds} seconds");
          },
        );

    stopwatch.stop();

    // Process and return the response
    return _processApiResponse(response);
  } catch (e) {
    // If direct POST fails, try multipart as fallback
    return _sendMessageWithMultipart(sessionId: sessionId, message: message, modelParams: modelParams, webSearch: webSearch, searchContextSize: searchContextSize, locationParams: locationParams);
  }
}

/// Send message with file attachment (multipart request)
Future<Map<String, dynamic>> _sendMessageWithFile({
  required String sessionId,
  required String message,
  required Map<String, dynamic> modelParams,
  required bool webSearch,
  String? searchContextSize,
  required Map<String, String?> locationParams,
  required File file,
}) async {
  // Validate file
  if (!await _validateFile(file)) {
    throw ApiException(message: "The selected file is empty or inaccessible", statusCode: 400);
  }

  // Add file to multipart request
  return _sendMessageWithMultipart(
    sessionId: sessionId,
    message: message,
    modelParams: modelParams,
    webSearch: webSearch,
    searchContextSize: searchContextSize,
    locationParams: locationParams,
    file: file,
  );
}

/// Helper to validate file exists and has content
Future<bool> _validateFile(File file) async {
  try {
    return await file.exists() && await file.length() > 0;
  } catch (e) {
    return false;
  }
}

/// Send message using multipart request (works for both with and without file)
Future<Map<String, dynamic>> _sendMessageWithMultipart({
  required String sessionId,
  required String message,
  required Map<String, dynamic> modelParams,
  required bool webSearch,
  String? searchContextSize,
  required Map<String, String?> locationParams,
  File? file,
}) async {
  // Create multipart request
  final Uri messageUrl = Uri.parse('$baseUrl/chat/messages');
  var request = http.MultipartRequest('POST', messageUrl);

  // Add authorization header
  request.headers.addAll(_getAuthHeaders());

  // Add text fields
  request.fields['session_id'] = sessionId;
  request.fields['message'] = message;
  request.fields['model'] = modelParams['model'] as String;
  request.fields['temperature'] = (modelParams['temperature'] as double).toString();
  request.fields['max_tokens'] = (modelParams['maxTokens'] as int).toString();
  request.fields['web_search'] = webSearch ? '1' : '0';

  // Only include search parameters if web search is enabled
  if (webSearch) {
    if (searchContextSize != null) {
      request.fields['search_context_size'] = searchContextSize;
    } else {
      // Default to medium if not specified
      request.fields['search_context_size'] = 'medium';
    }

    // Only include location parameters with web search
    locationParams.forEach((key, value) {
      if (value != null) {
        request.fields['user_location_$key'] = value;
      }
    });
  }

  // Add file if provided
  if (file != null) {
    try {
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final mimeType = _getMimeType(file);
      final filename = file.path.split('/').last;

      final multipartFile = http.MultipartFile('file', fileStream, fileLength, filename: filename, contentType: MediaType.parse(mimeType));

      request.files.add(multipartFile);
    } catch (e) {
      // Continue without file if there's an error
      debugPrint("Error adding file to request: $e");
    }
  }

  try {
    // Send the request
    final streamedResponse = await request.send().timeout(
      modelParams['timeout'] as Duration,
      onTimeout: () {
        throw TimeoutException("Request timed out after ${(modelParams['timeout'] as Duration).inSeconds} seconds");
      },
    );

    final response = await http.Response.fromStream(streamedResponse);

    // Process and return the response
    return _processApiResponse(response);
  } catch (e) {
    if (e is TimeoutException) {
      throw ApiException(message: e.message ?? "Request timed out", statusCode: 408);
    } else {
      throw ApiException(message: "Network error: $e", statusCode: 0);
    }
  }
}

/// Process API response and handle errors
Future<Map<String, dynamic>> _processApiResponse(http.Response response) async {
  // Check for empty response
  if (response.body.isEmpty) {
    throw ApiException(message: "Server returned empty response", statusCode: response.statusCode);
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    // Parse response
    Map<String, dynamic> jsonResponse;
    try {
      jsonResponse = json.decode(response.body);
    } catch (e) {
      throw ApiException(message: "Failed to parse JSON response: $e", statusCode: response.statusCode);
    }

    // Validate response structure
    try {
      if (jsonResponse['data'] == null) {
        throw "Response missing 'data' field";
      }
      if (jsonResponse['data']['message'] == null) {
        throw "Response missing 'data.message' field";
      }

      // Get the message data
      final messageData = jsonResponse['data']['message'] as Map<String, dynamic>;
      final sources = jsonResponse['data']['sources'] as List?;

      // Debug log message structure
      debugPrint("⚠️⚠️⚠️ API LAYER - message data structure: $messageData");

      // Return the raw JSON data instead of a parsed model
      return {'message': messageData, 'sources': sources ?? []};
    } catch (e) {
      throw ApiException(message: "Invalid response format: $e", statusCode: response.statusCode);
    }
  } else {
    // Handle error response
    String errorMessage;
    try {
      final errorJson = json.decode(response.body);
      errorMessage = errorJson['error']?['message'] ?? 'Unknown error occurred';
    } catch (e) {
      errorMessage = 'Failed to parse error response: ${response.body}';
    }

    throw ApiException(message: errorMessage, statusCode: response.statusCode);
  }
}

/// Rename a chat session
Future<AiChatSessionModel> renameSession(String sessionId, String name) async {
  try {
    final response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse2(
        '/chat/sessions/$sessionId/rename',
        method: networkUtils.HttpMethod.POST,
        request: {
          'session_id': sessionId, // Include session_id in the request body as well
          'name': name,
        },
      ),
    );

    return AiChatSessionModel.fromJson(response['data']);
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}

/// Delete a chat session
Future<Map<String, dynamic>> deleteSession(String sessionId) async {
  try {
    final response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse2('/chat/sessions/$sessionId', method: networkUtils.HttpMethod.DELETE));

    AiChatSessionModel? nextSession;
    if (response['data']['next_session'] != null) {
      nextSession = AiChatSessionModel.fromJson(response['data']['next_session']);
    }

    return {'success': true, 'nextSession': nextSession};
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}

/// Submit feedback for a message
Future<AiChatMessageModel> submitFeedback(String messageId, String feedback) async {
  try {
    final response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse2('/chat/feedback', method: networkUtils.HttpMethod.POST, request: {'message_id': messageId, 'feedback': feedback}),
    );

    return AiChatMessageModel.fromJson(response['data']);
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}

/// Suggest a title for a chat session
Future<String> suggestTitle(String sessionId, String userMessage, String aiResponse) async {
  try {
    final response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse2('/chat/suggest-title', method: networkUtils.HttpMethod.POST, request: {'session_id': sessionId, 'user_message': userMessage, 'ai_response': aiResponse}),
    );

    return response['data']['title'];
  } on ApiException catch (e) {
    throw ApiException(message: e.message, statusCode: e.statusCode);
  }
}
