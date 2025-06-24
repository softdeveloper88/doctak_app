import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';

abstract class ChatGPTState {}

class DataInitial extends ChatGPTState {}

class DataLoading extends ChatGPTState {}

class DataLoaded extends ChatGPTState {
  ChatGptSession response;
  ChatGptMessageHistory response1;
  ChatGptAskQuestionResponse response2;

  DataLoaded(this.response, this.response1, this.response2);
}

class MessagesDataLoaded extends ChatGPTState {
  ChatGptMessageHistory response;

  MessagesDataLoaded(
    this.response,
  );
}

class QuestionResponseLoaded extends ChatGPTState {
  ChatGptAskQuestionResponse response;

  QuestionResponseLoaded(
    this.response,
  );
}

class DataError extends ChatGPTState {
  final String errorMessage;

  DataError(this.errorMessage);
}
