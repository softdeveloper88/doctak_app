import 'package:doctak_app/data/models/news_model/news_model.dart';

abstract class SuggestionState {}

class NewsDataInitial extends SuggestionState {}

class DataError extends SuggestionState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends SuggestionState {
  PaginationInitialState();
}

class PaginationLoadedState extends SuggestionState {
  String response;
  PaginationLoadedState(this.response);
}

class PaginationLoadingState extends SuggestionState {}

class PaginationErrorState extends SuggestionState {}
