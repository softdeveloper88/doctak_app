import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
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

  ChatGPTBloc() : super(DataInitial()) {
    on<LoadDataValues>(_onGetPosts);
    on<GetPost>(_askQuestion);
    on<DeleteChatSession>(_onDeleteChatSession);
    on<GetMessages>(_onGetSessionMessagesList);
    on<GetNewChat>(_onGetNewChat);
  }
  _onGetPosts(LoadDataValues event, Emitter<ChatGPTState> emit) async {
    // emit(DataInitial());
    // try {
      // Load session list first
      ChatGptSession response = await apiManager.gptChatSession(
        'Bearer ${AppData.userToken}',
      );
      
      // Load messages for the first session if available
      ChatGptMessageHistory response1;
      if (response.sessions?.isNotEmpty == true) {
        response1 = await apiManager.gptChatMessages(
            'Bearer ${AppData.userToken}',
            response.sessions!.first.id.toString());
      } else {
        // If no sessions exist, create empty message history
        response1 = ChatGptMessageHistory();
      }
      
      print('Sessions loaded: ${response.sessions?.length ?? 0}');
      emit(DataLoaded(response, response1, ChatGptAskQuestionResponse()));
    // } catch (e) {
    //   print('Error loading initial data: $e');
    //   emit(DataError('Failed to load chat data: $e'));
    // }
  }

  _askQuestion(GetPost event, Emitter<ChatGPTState> emit) async {

    try {
      isWait=true;
      ChatGptAskQuestionResponse response;
      print('image1 ${event.imageUrl1}');
      print('screen ${event.imageType}');
      if(event.imageUrl1?.isNotEmpty??false) {
       response =
      await apiManager.askQuestionFromGpt(
          'Bearer ${AppData.userToken}', event.sessionId, event.question,
          event.imageType ?? "",event.imageUrl1 ?? "",event.imageUrl2 ?? "");
    }else{
        print(event.question);
       response =
      await apiManager.askQuestionFromGptWithoutImage(
          'Bearer ${AppData.userToken}', event.sessionId, event.question
         );
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
      
      // Only apply typing animation for new messages, not for history
      if (isLoadingHistory) {
        // If loading history, don't apply typing animation
        isWait = false;
        emit(DataLoaded(currentState.response, currentState.response1, response));
      } else {
        // Only apply typing animation for new messages
        emit(DataLoaded(currentState.response, currentState.response1, response));
        for (int i = 0;
            i <= response.content!.length;
            i++) {
          await Future.delayed(
              const Duration(milliseconds: 1)); // Delay to simulate typing speed
          
          // Check if state is still DataLoaded during animation
          if (state is! DataLoaded) break;
          
          final animationState = state as DataLoaded;
          int index = animationState.response1.messages?.indexWhere((msg) => msg.id == -1) ?? 0;
          if (index != -1) {
            String typingText = response.content!.substring(0, i);
            animationState.response1.messages![index] = Messages(
                id: -1,
                gptSessionId: event.sessionId,
                question: event.question,
                // imageUrl: event.imageUrl,
                response: typingText,
                createdAt: DateTime.now().toString(),
                updatedAt: DateTime.now().toString());
            if (response.content!.length == i) {
              animationState.response1.messages![index] = Messages(
                  id: response.responseMessageId,
                  gptSessionId: event.sessionId,
                  question: event.question,
                  // imageUrl: event.imageUrl,
                  response: typingText,
                  createdAt: DateTime.now().toString(),
                  updatedAt: DateTime.now().toString());
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
      emit(DataError(e.toString()));
    }
  }

  _onGetSessionMessagesList(
      GetMessages event, Emitter<ChatGPTState> emit) async {
    // Prevent concurrent loading operations
    if (state is DataLoading) {
      print('Already loading messages, ignoring request');
      return;
    }
    
    // Capture session data BEFORE emitting DataLoading
    ChatGptSession sessionData;
    ChatGptAskQuestionResponse questionResponse;
    
    if (state is DataLoaded) {
      final currentState = state as DataLoaded;
      sessionData = currentState.response;
      questionResponse = currentState.response2;
    } else {
      // Load session data first if we don't have it
      print('State is ${state.runtimeType}, loading session data first...');
      sessionData = await apiManager.gptChatSession('Bearer ${AppData.userToken}');
      questionResponse = ChatGptAskQuestionResponse();
    }
    
    // Emit loading state after capturing existing data
    emit(DataLoading());
    
    ProgressDialogUtils.showProgressDialog();
    try {
      // Set flag to indicate we're loading history
      isLoadingHistory = true;
      isWait = false;
      
      // Load messages for the specific session
      ChatGptMessageHistory response = await apiManager.gptChatMessages(
          'Bearer ${AppData.userToken}', event.sessionId);
      ProgressDialogUtils.hideProgressDialog();
      
      // Emit the loaded state with all messages at once (no typing animation)
      emit(DataLoaded(sessionData, response, questionResponse));
      
      // Reset the flag after loading
      isLoadingHistory = false;
    } catch (e) {
      print('Error loading session messages: $e');
      ProgressDialogUtils.hideProgressDialog();
      isLoadingHistory = false;
      emit(DataError('Failed to load messages: $e'));
    }
  }

  _onGetNewChat(GetNewChat event, Emitter<ChatGPTState> emit) async {
    // emit(DataInitial());
    ProgressDialogUtils.showProgressDialog();
    try {
      emit(DataLoaded(ChatGptSession(), ChatGptMessageHistory(),ChatGptAskQuestionResponse()) );
      var response = await apiManager.newChat('Bearer ${AppData.userToken}');
      ChatGptMessageHistory response1 = await apiManager.gptChatMessages(
          'Bearer ${AppData.userToken}', response.response.data['session_id']);
      ChatGptSession responseSession = await apiManager.gptChatSession(
        'Bearer ${AppData.userToken}',
      );
      print(response.response.data['session_id']);
      ProgressDialogUtils.hideProgressDialog();
      print('data');
      // Check if current state is DataLoaded, otherwise use empty response
      final response2 = (state is DataLoaded) 
          ? (state as DataLoaded).response2 
          : ChatGptAskQuestionResponse();
      emit(DataLoaded(responseSession, response1, response2));
    } catch (e) {
      print(e);
      ProgressDialogUtils.hideProgressDialog();

      emit(DataError('$e'));
    }
  }

  _onDeleteChatSession(
      DeleteChatSession event, Emitter<ChatGPTState> emit) async {
    // emit(DataInitial());
    ProgressDialogUtils.showProgressDialog();
    try {
      var response = await apiManager.deleteChatgptSession(
          'Bearer ${AppData.userToken}', event.sessionId.toString());
      print(response.response.data);
      ChatGptSession response1 = await apiManager.gptChatSession(
        'Bearer ${AppData.userToken}',
      );
      print('data');
      ProgressDialogUtils.hideProgressDialog();
      // Check if current state is DataLoaded, otherwise use empty responses
      final messageHistory = (state is DataLoaded) 
          ? (state as DataLoaded).response1 
          : ChatGptMessageHistory();
      final questionResponse = (state is DataLoaded) 
          ? (state as DataLoaded).response2 
          : ChatGptAskQuestionResponse();
      emit(DataLoaded(response1, messageHistory, questionResponse));
    } catch (e) {
      print(e);
      emit(DataError('An error occurred$e'));
    }
  }
}
