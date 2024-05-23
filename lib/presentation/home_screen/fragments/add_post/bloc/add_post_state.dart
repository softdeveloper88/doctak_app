part of 'add_post_bloc.dart';
abstract class AddPostState {}
class DrugsDataInitial extends AddPostState {}

class DataError extends AddPostState {
  final String errorMessage;
  DataError(this.errorMessage);
}
class PaginationInitialState extends AddPostState {
  PaginationInitialState();
}
class PaginationLoadedState extends AddPostState {
  PaginationLoadedState();

}
class ResponseLoadedState extends AddPostState {
  String message;
  ResponseLoadedState(this.message);

}
class PaginationLoadingState extends AddPostState {}
class PaginationErrorState extends AddPostState {}