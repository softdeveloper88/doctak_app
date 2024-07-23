// ignore_for_file: must_be_immutable

abstract class GroupState {}

class DataInitial extends GroupState {}

class PaginationInitialState extends GroupState {
  PaginationInitialState();
}

class PaginationLoadedState extends GroupState {
  final List<String> specialtyDropdownValue;
  String selectedSpecialtyDropdownValue;
  PaginationLoadedState(
    this.specialtyDropdownValue,
    this.selectedSpecialtyDropdownValue,
  );
}
// class PaginationLoadedState extends GroupState {}

class PaginationLoadingState extends GroupState {}

class PaginationErrorState extends GroupState {}

class DataError extends GroupState {
  final String errorMessage;
  DataError(this.errorMessage);
}
