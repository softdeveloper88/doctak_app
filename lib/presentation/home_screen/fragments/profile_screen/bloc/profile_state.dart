// ignore_for_file: must_be_immutable

import 'package:doctak_app/data/models/countries_model/countries_model.dart';

abstract class ProfileState {}

class DataInitial extends ProfileState {}

class PaginationInitialState extends ProfileState {
  PaginationInitialState();
}

class PaginationLoadedState extends ProfileState {
  List<Countries> firstDropdownValues = [];
  final String selectedFirstDropdownValue;
  List<String> secondDropdownValues = [];
  final String selectedSecondDropdownValue;
  final List<String> specialtyDropdownValue;
  String selectedSpecialtyDropdownValue;
  final List<String> universityDropdownValue;
  String? selectedUniversityDropdownValue;

  PaginationLoadedState(
    this.firstDropdownValues,
    this.selectedFirstDropdownValue,
    this.secondDropdownValues,
    this.selectedSecondDropdownValue,
    this.specialtyDropdownValue,
    this.selectedSpecialtyDropdownValue,
    this.universityDropdownValue,
    this.selectedUniversityDropdownValue,
  );
}

/// State emitted after v5 full profile loads or a CRUD operation completes
class FullProfileLoadedState extends ProfileState {
  List<Countries> firstDropdownValues;
  String selectedFirstDropdownValue;
  List<String> secondDropdownValues;
  String selectedSecondDropdownValue;
  List<String> specialtyDropdownValue;
  String selectedSpecialtyDropdownValue;

  FullProfileLoadedState({
    this.firstDropdownValues = const [],
    this.selectedFirstDropdownValue = '',
    this.secondDropdownValues = const [],
    this.selectedSecondDropdownValue = '',
    this.specialtyDropdownValue = const [],
    this.selectedSpecialtyDropdownValue = '',
  });
}

/// Emitted while a CRUD operation is in progress
class ProfileOperationInProgress extends ProfileState {}

/// Emitted after a CRUD operation succeeds
class ProfileOperationSuccess extends ProfileState {
  final String message;
  ProfileOperationSuccess(this.message);
}

/// Emitted after a CRUD operation fails
class ProfileOperationError extends ProfileState {
  final String message;
  ProfileOperationError(this.message);
}
// class PaginationLoadedState extends ProfileState {}

class PaginationLoadingState extends ProfileState {}

class PaginationErrorState extends ProfileState {}

class DataError extends ProfileState {
  final String errorMessage;
  DataError(this.errorMessage);
}

/// Helper class to extract dropdown data from either loaded state
class ProfileDropdownData {
  final List<Countries> firstDropdownValues;
  final String selectedFirstDropdownValue;
  final List<String> secondDropdownValues;
  final String selectedSecondDropdownValue;
  final List<String> specialtyDropdownValue;
  final String selectedSpecialtyDropdownValue;

  ProfileDropdownData({
    this.firstDropdownValues = const [],
    this.selectedFirstDropdownValue = '',
    this.secondDropdownValues = const [],
    this.selectedSecondDropdownValue = '',
    this.specialtyDropdownValue = const [],
    this.selectedSpecialtyDropdownValue = '',
  });
}
