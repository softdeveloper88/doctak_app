part of 'comment_bloc.dart';

abstract class CommentState {}

class DataInitial extends CommentState {}

class PaginationInitialState extends CommentState {
  PaginationInitialState();
}

class PaginationLoadedState extends CommentState {}

class PaginationLoadingState extends CommentState {}

class PaginationErrorState extends CommentState {}

class DataError extends CommentState {
  final String errorMessage;
  DataError(this.errorMessage);
}
