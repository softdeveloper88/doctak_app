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
// class PaginationLoadedState extends ProfileState {}

class PaginationLoadingState extends ProfileState {}

class PaginationErrorState extends ProfileState {}

class DataError extends ProfileState {
  final String errorMessage;
  DataError(this.errorMessage);
}
