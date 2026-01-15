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
