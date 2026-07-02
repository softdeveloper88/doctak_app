// ignore_for_file: must_be_immutable

part of 'chat_bloc.dart';

abstract class ChatState {}

class DataInitial extends ChatState {}

class PaginationInitialState extends ChatState {
  PaginationInitialState();
}

class PaginationLoadedState extends ChatState {}

class PaginationLoadingState extends ChatState {}

class PaginationErrorState extends ChatState {}

class DataError extends ChatState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class FileUploadingState extends ChatState {}

class FileUploadedState extends ChatState {}

/// Someone is typing (or stopped typing) in the current conversation.
class TypingState extends ChatState {
  final String userId;
  final bool isTyping;
  TypingState({required this.userId, required this.isTyping});
}

/// Online/offline status of a peer changed.
class PresenceUpdatedState extends ChatState {
  final String userId;
  final bool isOnline;
  PresenceUpdatedState({required this.userId, required this.isOnline});
}

