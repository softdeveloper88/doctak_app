import 'package:doctak_app/data/models/search_user_tag_model/search_user_tag_model.dart';
import 'package:equatable/equatable.dart';

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