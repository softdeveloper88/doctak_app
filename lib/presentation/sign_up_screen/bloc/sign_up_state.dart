part of 'sign_up_bloc.dart';

abstract class DropdownState {}
class DropdownInitial extends DropdownState {}
class DropdownLoaded1 extends DropdownState {
  var response;
  DropdownLoaded1({required this.response});
}

class DropdownLoaded extends DropdownState {
  final List<String> firstDropdownValues;
  final String selectedFirstDropdownValue;
  final List<String> secondDropdownValues;
  final String selectedSecondDropdownValue;
  final List<String> specialtyDropdownValue;
  final String selectedSpecialtyDropdownValue;
  final List<String> universityDropdownValue;
  String? selectedUniversityDropdownValue;
  final bool isPasswordVisible;
   bool isDoctorRole;
  DropdownLoaded(
      this.firstDropdownValues,
      this.selectedFirstDropdownValue,
      this.secondDropdownValues,
      this.selectedSecondDropdownValue,
      this.specialtyDropdownValue,
      this.selectedSpecialtyDropdownValue,
      this.universityDropdownValue,
      this.selectedUniversityDropdownValue,
      this.isPasswordVisible,
      this.isDoctorRole
      );
}
class DataLoaded extends DropdownState {
  final bool isPasswordVisible;
   bool isDoctorRole;
  DataLoaded(
      this.isPasswordVisible,
      this.isDoctorRole
      );
}

class DropdownError extends DropdownState {
  final String errorMessage;
  DropdownError(this.errorMessage);
}


