part of 'likes_bloc.dart';

abstract class LikesState {}
class DataInitial extends LikesState {}

class PaginationInitialState extends LikesState {
  PaginationInitialState();
}
class PaginationLoadedState extends LikesState {}

class PaginationLoadingState extends LikesState {}

class PaginationErrorState extends LikesState {}

class DataError extends LikesState {
  final String errorMessage;
  DataError(this.errorMessage);
}


