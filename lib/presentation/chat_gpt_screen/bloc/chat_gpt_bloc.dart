import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chat_gpt_event.dart';
import 'chat_gpt_state.dart';

class ChatGPTBloc extends Bloc<ChatGPTEvent, ChatGPTState> {
  final ApiService postService = ApiService(Dio());
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
    emit(DataInitial());
    // ProgressDialogUtils.showProgressDialog();
    try {
      ChatGptSession response = await postService.gptChatSession(
        'Bearer ${AppData.userToken}',
      );
      ChatGptMessageHistory response1 = await postService.gptChatMessages(
          'Bearer ${AppData.userToken}',
          response.sessions!.first.id.toString());
      // if (response.==true) {
      //   ProgressDialogUtils.hideProgressDialog();
      // emit(MessagesDataLoaded(response1));
      // if (response.==true) {
      //   ProgressDialogUtils.hideProgressDialog();
      print('object $response');
      emit(DataLoaded(response, response1, ChatGptAskQuestionResponse()));
      // } else {
      //   ProgressDialogUtils.hideProgressDialog();
      //   emit(LoginFailure(error: 'Invalid credentials'));
      // }
    } catch (e) {
      emit(DataError('An error occurred$e'));
    }
  }

  _askQuestion(GetPost event, Emitter<ChatGPTState> emit) async {

    try {
      isWait=true;
      ChatGptAskQuestionResponse response;
      print('image1 ${event.imageUrl1}');
      print('screen ${event.imageType}');
      if(event.imageUrl1?.isNotEmpty??false) {
       response =
      await postService.askQuestionFromGpt(
          'Bearer ${AppData.userToken}', event.sessionId, event.question,
          event.imageType ?? "",event.imageUrl1 ?? "",event.imageUrl2 ?? "");
    }else{
        print(event.question);
       response =
      await postService.askQuestionFromGptWithoutImage(
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
      
      // Only apply typing animation for new messages, not for history
      if (isLoadingHistory) {
        // If loading history, don't apply typing animation
        isWait = false;
        emit(DataLoaded((state as DataLoaded).response, (state as DataLoaded).response1, response));
      } else {
        // Only apply typing animation for new messages
        emit(DataLoaded((state as DataLoaded).response, (state as DataLoaded).response1, response));
        for (int i = 0;
            i <= (state as DataLoaded).response2.content!.length;
            i++) {
          await Future.delayed(
              const Duration(milliseconds: 1)); // Delay to simulate typing speed
          int index = (state as DataLoaded).response1.messages?.indexWhere((msg) => msg.id == -1)??0;
          if (index != -1) {
            String typingText =
                (state as DataLoaded).response2.content!.substring(0, i);
            (state as DataLoaded).response1.messages![index] = Messages(
                id: -1,
                gptSessionId: event.sessionId,
                question: event.question,
                // imageUrl: event.imageUrl,
                response: typingText,
                createdAt: DateTime.now().toString(),
                updatedAt: DateTime.now().toString());
            if ((state as DataLoaded).response2.content!.length == i) {
              (state as DataLoaded).response1.messages![index] = Messages(
                  id: response.responseMessageId,
                  gptSessionId: event.sessionId,
                  question: event.question,
                  // imageUrl: event.imageUrl,
                  response: typingText,
                  createdAt: DateTime.now().toString(),
                  updatedAt: DateTime.now().toString());
            }
          }
          isWait=false;

          emit(DataLoaded((state as DataLoaded).response,
              (state as DataLoaded).response1, response));
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
    // emit(DataInitial());
    ProgressDialogUtils.showProgressDialog();
    try {
      // Set flag to indicate we're loading history
      isLoadingHistory = true;
      isWait = false;
      
      ChatGptMessageHistory response = await postService.gptChatMessages(
          'Bearer ${AppData.userToken}', event.sessionId);
      ProgressDialogUtils.hideProgressDialog();
      
      // Emit the loaded state with all messages at once (no typing animation)
      emit(DataLoaded((state as DataLoaded).response, response,
          (state as DataLoaded).response2));
      
      // Reset the flag after loading
      isLoadingHistory = false;
    } catch (e) {
      print(e);
      ProgressDialogUtils.hideProgressDialog();
      isLoadingHistory = false;
      emit(DataError('An error occurred$e'));
    }
  }

  _onGetNewChat(GetNewChat event, Emitter<ChatGPTState> emit) async {
    // emit(DataInitial());
    ProgressDialogUtils.showProgressDialog();
    try {
      emit(DataLoaded(ChatGptSession(), ChatGptMessageHistory(),ChatGptAskQuestionResponse()) );
      var response = await postService.newChat('Bearer ${AppData.userToken}');
      ChatGptMessageHistory response1 = await postService.gptChatMessages(
          'Bearer ${AppData.userToken}', response.response.data['session_id']);
      ChatGptSession responseSession = await postService.gptChatSession(
        'Bearer ${AppData.userToken}',
      );
      print(response.response.data['session_id']);
      ProgressDialogUtils.hideProgressDialog();
      print('data');
      emit(DataLoaded(responseSession, response1, (state as DataLoaded).response2));
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
      var response = await postService.deleteChatgptSession(
          'Bearer ${AppData.userToken}', event.sessionId.toString());
      print(response.response.data);
      ChatGptSession response1 = await postService.gptChatSession(
        'Bearer ${AppData.userToken}',
      );
      print('data');
      ProgressDialogUtils.hideProgressDialog();
      emit(DataLoaded(response1, (state as DataLoaded).response1,
          (state as DataLoaded).response2));
    } catch (e) {
      print(e);
      emit(DataError('An error occurred$e'));
    }
  }
}
