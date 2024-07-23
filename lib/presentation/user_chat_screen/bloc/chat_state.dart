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
