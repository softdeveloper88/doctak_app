import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// ChatGPT API Service
/// Handles all ChatGPT AI related API calls
class ChatGptApiService {
  static final ChatGptApiService _instance = ChatGptApiService._internal();
  factory ChatGptApiService() => _instance;
  ChatGptApiService._internal();

  /// Helper function to get auth headers
  Map<String, String> _getAuthHeaders() {
    Map<String, String> headers = {};
    if (AppData.userToken != null) {
      headers['Authorization'] = 'Bearer ${AppData.userToken}';
    }
    return headers;
  }

  /// Helper function to determine MIME type from file path
  String _getMimeType(String filePath) {
    final filename = filePath.split('/').last.toLowerCase();
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (filename.endsWith('.png')) {
      return 'image/png';
    } else if (filename.endsWith('.gif')) {
      return 'image/gif';
    } else if (filename.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg'; // Default to jpeg for medical images
  }

  /// Ask question to ChatGPT with medical images (multipart file upload)
  /// [imagePath1] and [imagePath2] should be local file paths, not URLs
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithImages({
    required String sessionId,
    required String question,
    required String imageType,
    String? imagePath1,
    String? imagePath2,
  }) async {
    try {
      // Create the API URL
      final Uri url = Uri.parse('${AppData.remoteUrl2}/ask-question');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers.addAll(_getAuthHeaders());

      // Add text fields (matching PHP backend expectations)
      request.fields['id'] = sessionId;
      request.fields['question'] = question;
      if (imageType.isNotEmpty) {
        request.fields['image_type'] = imageType;
      }

      // Add image1 file if provided
      if (imagePath1 != null && imagePath1.isNotEmpty) {
        final file1 = File(imagePath1);
        if (await file1.exists()) {
          final fileStream1 = http.ByteStream(file1.openRead());
          final fileLength1 = await file1.length();
          final mimeType1 = _getMimeType(imagePath1);
          final filename1 = imagePath1.split('/').last;

          final multipartFile1 = http.MultipartFile(
            'image1', // Field name matching PHP: $request->hasFile('image1')
            fileStream1,
            fileLength1,
            filename: filename1,
            contentType: MediaType.parse(mimeType1),
          );
          request.files.add(multipartFile1);
        }
      }

      // Add image2 file if provided
      if (imagePath2 != null && imagePath2.isNotEmpty) {
        final file2 = File(imagePath2);
        if (await file2.exists()) {
          final fileStream2 = http.ByteStream(file2.openRead());
          final fileLength2 = await file2.length();
          final mimeType2 = _getMimeType(imagePath2);
          final filename2 = imagePath2.split('/').last;

          final multipartFile2 = http.MultipartFile(
            'image2', // Field name matching PHP: $request->hasFile('image2')
            fileStream2,
            fileLength2,
            filename: filename2,
            contentType: MediaType.parse(mimeType2),
          );
          request.files.add(multipartFile2);
        }
      }

      // Send the request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120), // Extended timeout for image processing
        onTimeout: () {
          throw ApiException(message: 'Request timed out', statusCode: 408);
        },
      );

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        return ApiResponse.success(
          ChatGptAskQuestionResponse.fromJson(jsonResponse),
        );
      } else {
        // Parse error message
        String errorMessage = 'Failed to ask question with images';
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage =
              errorJson['error']?['message'] ??
              errorJson['message'] ??
              errorMessage;
        } catch (_) {}
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to ask question with images: $e');
    }
  }

  /// Ask question to ChatGPT without images
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithoutImages({
    required String sessionId,
    required String question,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/ask-question',
          method: networkUtils.HttpMethod.POST,
          request: {'id': sessionId, 'question': question},
        ),
      );
      return ApiResponse.success(ChatGptAskQuestionResponse.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to ask question: $e');
    }
  }

  /// Get all ChatGPT sessions
  Future<ApiResponse<ChatGptSession>> getChatGptSessions() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/gptChat-session',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(ChatGptSession.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get ChatGPT sessions: $e');
    }
  }

  /// Get message history for a specific ChatGPT session
  Future<ApiResponse<ChatGptMessageHistory>> getChatGptMessages({
    required String sessionId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/gptChat-history/$sessionId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(ChatGptMessageHistory.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get ChatGPT messages: $e');
    }
  }

  /// Create a new ChatGPT session
  Future<ApiResponse<Map<String, dynamic>>> createNewChatSession() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/new-chat',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create new ChatGPT session: $e');
    }
  }

  /// Delete a ChatGPT session
  Future<ApiResponse<Map<String, dynamic>>> deleteChatGptSession({
    required String sessionId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/delete-chatgpt-session?session_id=$sessionId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete ChatGPT session: $e');
    }
  }

  /// Ask question about drugs/medications
  Future<ApiResponse<ChatGptAskQuestionResponse>> askDrugQuestion({
    required String sessionId,
    required String question,
    String? drugName,
    String? symptoms,
    String? patientAge,
    String? patientWeight,
  }) async {
    try {
      // Build enhanced question with medical context
      String enhancedQuestion = question;
      if (drugName != null) {
        enhancedQuestion += '\n\nDrug: $drugName';
      }
      if (symptoms != null) {
        enhancedQuestion += '\nSymptoms: $symptoms';
      }
      if (patientAge != null) {
        enhancedQuestion += '\nPatient Age: $patientAge';
      }
      if (patientWeight != null) {
        enhancedQuestion += '\nPatient Weight: $patientWeight';
      }

      return await askQuestionWithoutImages(
        sessionId: sessionId,
        question: enhancedQuestion,
      );
    } catch (e) {
      return ApiResponse.error('Failed to ask drug question: $e');
    }
  }

  /// Ask question about medical case discussion
  Future<ApiResponse<ChatGptAskQuestionResponse>> askCaseQuestion({
    required String sessionId,
    required String question,
    String? patientHistory,
    String? symptoms,
    String? diagnosis,
    String? treatment,
  }) async {
    try {
      // Build enhanced question with case context
      String enhancedQuestion = question;
      if (patientHistory != null) {
        enhancedQuestion += '\n\nPatient History: $patientHistory';
      }
      if (symptoms != null) {
        enhancedQuestion += '\nSymptoms: $symptoms';
      }
      if (diagnosis != null) {
        enhancedQuestion += '\nDiagnosis: $diagnosis';
      }
      if (treatment != null) {
        enhancedQuestion += '\nTreatment: $treatment';
      }

      return await askQuestionWithoutImages(
        sessionId: sessionId,
        question: enhancedQuestion,
      );
    } catch (e) {
      return ApiResponse.error('Failed to ask case question: $e');
    }
  }

  /// Get session statistics
  Future<ApiResponse<Map<String, dynamic>>> getSessionStats() async {
    try {
      final sessionsResponse = await getChatGptSessions();
      if (sessionsResponse.success && sessionsResponse.data != null) {
        final sessions = sessionsResponse.data!.sessions ?? [];
        return ApiResponse.success({
          'totalSessions': sessions.length,
          'activeSessions':
              sessions.length, // Sessions model doesn't have isActive property
          'recentSessions': sessions.take(5).toList(),
        });
      } else {
        return ApiResponse.error('Failed to get session stats');
      }
    } catch (e) {
      return ApiResponse.error('Failed to get session statistics: $e');
    }
  }

  // ================================== BACKWARD COMPATIBILITY ==================================

  /// Get GPT chat session (backward compatibility)
  Future<ApiResponse<ChatGptSession>> gptChatSession() async {
    return getChatGptSessions();
  }

  /// Get GPT chat messages (backward compatibility)
  Future<ApiResponse<ChatGptMessageHistory>> gptChatMessages({
    required String sessionId,
  }) async {
    return getChatGptMessages(sessionId: sessionId);
  }

  /// Ask question from GPT (backward compatibility)
  /// Note: imageUrl1/imageUrl2 should now be local file paths, not URLs
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionFromGpt({
    required String sessionId,
    required String question,
    required String imageType,
    String? imageUrl1,
    String? imageUrl2,
  }) async {
    return askQuestionWithImages(
      sessionId: sessionId,
      question: question,
      imageType: imageType,
      imagePath1: imageUrl1,
      imagePath2: imageUrl2,
    );
  }

  /// Ask question from GPT without image (backward compatibility)
  Future<ApiResponse<ChatGptAskQuestionResponse>>
  askQuestionFromGptWithoutImage({
    required String sessionId,
    required String question,
  }) async {
    return askQuestionWithoutImages(sessionId: sessionId, question: question);
  }
}
