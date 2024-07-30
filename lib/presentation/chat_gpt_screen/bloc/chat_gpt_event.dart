import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class ChatGPTEvent extends Equatable {}

class LoadDataValues extends ChatGPTEvent {
  @override
  List<Object?> get props => [];
}

class IsStatus extends ChatGPTEvent {
  bool isWriting;
  IsStatus(this.isWriting);
  @override
  List<Object?> get props => [isWriting];
}

class GetPost extends ChatGPTEvent {
  final String sessionId;
  final String question;
  String? imageUrl;
  GetPost({required this.sessionId, required this.question,this.imageUrl});

  @override
  List<Object> get props => [sessionId, question,imageUrl??""];
}

class GetDrugAskEvent extends ChatGPTEvent {
  final String sessionId;
  final String question;

  GetDrugAskEvent({required this.sessionId, required this.question});

  @override
  List<Object> get props => [sessionId, question];
}

class GetMessages extends ChatGPTEvent {
  final String sessionId;

  GetMessages({required this.sessionId});
  @override
  List<Object> get props => [sessionId];
}

class GetNewChat extends ChatGPTEvent {
  GetNewChat();
  @override
  List<Object> get props => [];
}

class DeleteChatSession extends ChatGPTEvent {
  int sessionId;
  DeleteChatSession(this.sessionId);
  @override
  List<Object> get props => [sessionId];
}
