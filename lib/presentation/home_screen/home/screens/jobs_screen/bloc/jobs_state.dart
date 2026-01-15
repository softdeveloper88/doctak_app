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
