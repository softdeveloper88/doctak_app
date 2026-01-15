abstract class SearchPeopleState {}

class DrugsDataInitial extends SearchPeopleState {}

class SearchPeopleDataError extends SearchPeopleState {
  final String errorMessage;
  SearchPeopleDataError(this.errorMessage);
}

class SearchPeoplePaginationInitialState extends SearchPeopleState {
  SearchPeoplePaginationInitialState();
}

class SearchPeoplePaginationLoadedState extends SearchPeopleState {}

class SearchPeoplePaginationLoadingState extends SearchPeopleState {}

class SearchPeoplePaginationErrorState extends SearchPeopleState {}
