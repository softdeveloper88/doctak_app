import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// ChatGPT API Service
/// Handles all ChatGPT AI related API calls
class ChatGptApiService {
  static final ChatGptApiService _instance = ChatGptApiService._internal();
  factory ChatGptApiService() => _instance;
  ChatGptApiService._internal();

  /// Ask question to ChatGPT with medical images
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithImages({
    required String sessionId,
    required String question,
    required String imageType,
    String? imageUrl1,
    String? imageUrl2,
  }) async {
    try {
      final request = {
        'id': sessionId,
        'question': question,
        'image_type': imageType,
      };
      
      if (imageUrl1 != null) request['image1'] = imageUrl1;
      if (imageUrl2 != null) request['image2'] = imageUrl2;

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/ask-question',
          method: networkUtils.HttpMethod.POST,
          request: request,
        ),
      );
      return ApiResponse.success(ChatGptAskQuestionResponse.fromJson(response));
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
          request: {
            'id': sessionId,
            'question': question,
          },
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
          'activeSessions': sessions.length, // Sessions model doesn't have isActive property
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
      imageUrl1: imageUrl1,
      imageUrl2: imageUrl2,
    );
  }

  /// Ask question from GPT without image (backward compatibility)
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionFromGptWithoutImage({
    required String sessionId,
    required String question,
  }) async {
    return askQuestionWithoutImages(sessionId: sessionId, question: question);
  }
}