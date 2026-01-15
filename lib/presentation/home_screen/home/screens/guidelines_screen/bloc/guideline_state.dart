abstract class GuidelineState {}

class DrugsDataInitial extends GuidelineState {}

class DataError extends GuidelineState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends GuidelineState {
  PaginationInitialState();
}

class PaginationLoadedState extends GuidelineState {}

class PaginationLoadingState extends GuidelineState {}

class PaginationErrorState extends GuidelineState {}
