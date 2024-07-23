import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:equatable/equatable.dart';

abstract class JobsState {}

class DrugsDataInitial extends JobsState {}

class DataError extends JobsState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends JobsState {
  PaginationInitialState();
}

class PaginationLoadedState extends JobsState {}

class PaginationLoadingState extends JobsState {}

class PaginationErrorState extends JobsState {}
