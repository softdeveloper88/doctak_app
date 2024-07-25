import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:equatable/equatable.dart';

abstract class NotificationState {}

class DrugsDataInitial extends NotificationState {}

class DataError extends NotificationState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends NotificationState {
  PaginationInitialState();
}

class PaginationLoadedState extends NotificationState {}

class PaginationLoadingState extends NotificationState {}

class PaginationErrorState extends NotificationState {}
