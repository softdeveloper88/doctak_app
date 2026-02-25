import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chat_gpt_event.dart';
import 'chat_gpt_state.dart';

class ChatGPTBloc extends Bloc<ChatGPTEvent, ChatGPTState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int newChatSessionId = 0;
  bool isWait = false;
  bool isLoadingHistory = false;
  /// Non-null when the last _askQuestion failed. The screen reads this, shows
  /// a SnackBar, then clears it. This avoids emitting DataError (which would
  /// replace the chat UI with an error page).
  String? lastError;

  ChatGPTBloc() : super(DataInitial()) {
    on<LoadDataValues>(_onGetPosts);
    on<GetPost>(_askQuestion);
    on<DeleteChatSession>(_onDeleteChatSession);
    on<GetMessages>(_onGetSessionMessagesList);
    on<GetNewChat>(_onGetNewChat);
  }
  Future<void> _onGetPosts(LoadDataValues event, Emitter<ChatGPTState> emit) async {
    // Single API call — the backend's sessions endpoint already guarantees
    // newSessionId points to a truly empty session (whereDoesntHave('messages')).
    ChatGptSession response = await apiManager.gptChatSession('Bearer ${AppData.userToken}');
    newChatSessionId = response.newSessionId ?? 0;

    // Start with empty message history — user sees the analysis-card screen
    ChatGptMessageHistory response1 = ChatGptMessageHistory();

    print('Sessions loaded: ${response.sessions?.length ?? 0}');
    print('newSessionId: ${response.newSessionId}');
    emit(DataLoaded(response, response1, ChatGptAskQuestionResponse()));
  }

  Future<void> _askQuestion(GetPost event, Emitter<ChatGPTState> emit) async {
    try {
      isWait = true;
      ChatGptAskQuestionResponse response;
      print('image1 ${event.imageUrl1}');
      print('screen ${event.imageType}');
      if (event.imageUrl1?.isNotEmpty ?? false) {
        response = await apiManager.askQuestionFromGpt('Bearer ${AppData.userToken}', event.sessionId, event.question, event.imageType ?? "", event.imageUrl1 ?? "", event.imageUrl2 ?? "");
      } else {
        print(event.question);
        response = await apiManager.askQuestionFromGptWithoutImage('Bearer ${AppData.userToken}', event.sessionId, event.question);
      }

      // Validate response
      if (response.content == null || response.content!.isEmpty) {
        throw Exception('Received empty response from AI');
      }
      // var myMessage = Messages(anly
      //     id: -1,
      //     gptSessionId: event.sessionId,
      //     question: event.question,
      //     response: '...',
      //     createdAt: DateTime.now().toString(),
      //     updatedAt: DateTime.now().toString());
      // (state as DataLoaded).response1.messages!.add(myMessage);
      // emit(DataLoaded(ChatGptSession(), ChatGptMessageHistory(), response));

      // Check if current state is DataLoaded before proceeding
      if (state is! DataLoaded) {
        print('Error: Cannot ask question, current state is not DataLoaded: ${state.runtimeType}');
        emit(DataError('Chat session not properly loaded'));
        return;
      }

      final currentState = state as DataLoaded;

      // Update quota usage in real-time from the AI response
      if (response.usage != null) {
        currentState.response.usage = response.usage;
      }

      // Only apply typing animation for new messages, not for history
      if (isLoadingHistory) {
        // If loading history, don't apply typing animation
        isWait = false;
        emit(DataLoaded(currentState.response, currentState.response1, response));
      } else {
        // Only apply typing animation for new messages
        emit(DataLoaded(currentState.response, currentState.response1, response));
        for (int i = 0; i <= response.content!.length; i++) {
          await Future.delayed(const Duration(milliseconds: 1)); // Delay to simulate typing speed

          // Check if state is still DataLoaded during animation
          if (state is! DataLoaded) break;

          final animationState = state as DataLoaded;
          int index = animationState.response1.messages?.indexWhere((msg) => msg.id == -1) ?? 0;
          if (index != -1) {
            String typingText = response.content!.substring(0, i);
            // Convert CitationSource list → Map list for Messages model
            final List<Map<String, dynamic>>? sourceMaps =
                response.sources?.map((s) => <String, dynamic>{'url': s.url, 'title': s.title}).toList();
            animationState.response1.messages![index] = Messages(
              id: -1,
              gptSessionId: event.sessionId,
              question: event.question,
              response: typingText,
              createdAt: DateTime.now().toString(),
              updatedAt: DateTime.now().toString(),
            );
            if (response.content!.length == i) {
              // Final message: include sources for Apple Guideline 1.4.1 compliance
              animationState.response1.messages![index] = Messages(
                id: response.responseMessageId,
                gptSessionId: event.sessionId,
                question: event.question,
                response: typingText,
                createdAt: DateTime.now().toString(),
                updatedAt: DateTime.now().toString(),
                sources: sourceMaps,
              );
            }
          }
          isWait = false;

          // Check again before emitting
          if (state is DataLoaded) {
            final emitState = state as DataLoaded;
            emit(DataLoaded(emitState.response, emitState.response1, response));
          }
          // });
          // scrollToBottom();
        }
      }

      // emit(QuestionResponseLoaded(response));
    } catch (e) {
      print("eee$e");
      isWait = false;
      // Extract meaningful error message
      String errorMessage = "Failed to get response from AI";
      if (e.toString().contains("Exception:")) {
        errorMessage = e.toString().replaceAll("Exception:", "").trim();
      } else if (e.toString().contains("error")) {
        errorMessage = e.toString();
      }

      // Stay in DataLoaded state so the chat UI remains visible.
      // Set lastError for the screen to show via SnackBar.
      if (state is DataLoaded) {
        final currentState = state as DataLoaded;
        currentState.response1.messages?.removeWhere((msg) => msg.id == -1);
        lastError = errorMessage;
        emit(DataLoaded(currentState.response, currentState.response1, currentState.response2));
      } else {
        emit(DataError(errorMessage));
      }
    }
  }

  Future<void> _onGetSessionMessagesList(GetMessages event, Emitter<ChatGPTState> emit) async {
    // Prevent concurrent loading operations
    if (isLoadingHistory) {
      print('Already loading messages, ignoring request');
      return;
    }

    // Capture session data without emitting DataLoading (avoids UI flicker/rebuild)
    ChatGptSession sessionData;
    ChatGptAskQuestionResponse questionResponse;

    if (state is DataLoaded) {
      final currentState = state as DataLoaded;
      sessionData = currentState.response;
      questionResponse = currentState.response2;
    } else {
      print('State is ${state.runtimeType}, loading session data first...');
      sessionData = await apiManager.gptChatSession('Bearer ${AppData.userToken}');
      questionResponse = ChatGptAskQuestionResponse();
    }

    // Don't emit DataLoading — keep existing UI visible to avoid page refresh
    ProgressDialogUtils.showProgressDialog();
    try {
      isLoadingHistory = true;
      isWait = false;

      ChatGptMessageHistory response = await apiManager.gptChatMessages('Bearer ${AppData.userToken}', event.sessionId);
      ProgressDialogUtils.hideProgressDialog();

      emit(DataLoaded(sessionData, response, questionResponse));
      isLoadingHistory = false;
    } catch (e) {
      print('Error loading session messages: $e');
      ProgressDialogUtils.hideProgressDialog();
      isLoadingHistory = false;
      // Don't emit DataError for history load failures — stay in current state
      if (state is DataLoaded) {
        final cs = state as DataLoaded;
        emit(DataLoaded(cs.response, cs.response1, cs.response2));
      } else {
        emit(DataError('Failed to load messages: $e'));
      }
    }
  }

  Future<void> _onGetNewChat(GetNewChat event, Emitter<ChatGPTState> emit) async {
    ProgressDialogUtils.showProgressDialog();
    try {
      // Don't emit empty DataLoaded first — causes flicker
      var response = await apiManager.newChat('Bearer ${AppData.userToken}');
      final dynamic rawSessionId = response.response.data['session_id'] ?? response.response.data['newSessionId'];
      final String sessionIdStr = rawSessionId.toString();
      newChatSessionId = int.tryParse(sessionIdStr) ?? 0;
      ChatGptMessageHistory response1 = await apiManager.gptChatMessages('Bearer ${AppData.userToken}', sessionIdStr);
      ChatGptSession responseSession = await apiManager.gptChatSession('Bearer ${AppData.userToken}');
      print('New chat session created with id: $sessionIdStr');
      ProgressDialogUtils.hideProgressDialog();
      print('data');
      // Check if current state is DataLoaded, otherwise use empty response
      final response2 = (state is DataLoaded) ? (state as DataLoaded).response2 : ChatGptAskQuestionResponse();
      emit(DataLoaded(responseSession, response1, response2));
    } catch (e) {
      print(e);
      ProgressDialogUtils.hideProgressDialog();

      emit(DataError('$e'));
    }
  }

  Future<void> _onDeleteChatSession(DeleteChatSession event, Emitter<ChatGPTState> emit) async {
    // emit(DataInitial());
    ProgressDialogUtils.showProgressDialog();
    try {
      var response = await apiManager.deleteChatgptSession('Bearer ${AppData.userToken}', event.sessionId.toString());
      print(response.response.data);
      ChatGptSession response1 = await apiManager.gptChatSession('Bearer ${AppData.userToken}');
      print('data');
      ProgressDialogUtils.hideProgressDialog();
      // Check if current state is DataLoaded, otherwise use empty responses
      final messageHistory = (state is DataLoaded) ? (state as DataLoaded).response1 : ChatGptMessageHistory();
      final questionResponse = (state is DataLoaded) ? (state as DataLoaded).response2 : ChatGptAskQuestionResponse();
      emit(DataLoaded(response1, messageHistory, questionResponse));
    } catch (e) {
      print(e);
      emit(DataError('An error occurred$e'));
    }
  }
}
