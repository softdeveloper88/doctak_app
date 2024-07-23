import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';

abstract class SearchState {}

class DrugsDataInitial extends SearchState {}

class DataError extends SearchState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends SearchState {
  PaginationInitialState();
}

class PaginationLoadedState extends SearchState {}

class PaginationLoadedState1 extends SearchState {
  List<Data> data;
  PaginationLoadedState1(this.data);
}

class PaginationLoadingState extends SearchState {}

class PaginationErrorState extends SearchState {}
