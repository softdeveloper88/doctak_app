import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';

abstract class DrugsState {}

class DrugsDataInitial extends DrugsState {}

class DataError extends DrugsState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends DrugsState {
  PaginationInitialState();
}

class PaginationLoadedState extends DrugsState {}

class PaginationLoadedState1 extends DrugsState {
  List<Data> data;
  PaginationLoadedState1(this.data);
}

class PaginationLoadingState extends DrugsState {}

class PaginationErrorState extends DrugsState {}
