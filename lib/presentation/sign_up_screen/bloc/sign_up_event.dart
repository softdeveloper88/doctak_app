// ignore_for_file: must_be_immutable

part of 'sign_up_bloc.dart';

/// Abstract class for all events that can be dispatched from the
///SignUp widget.
///
/// Events must be immutable and implement the [Equatable] interface.
// @immutable
// abstract class SignUpEvent {}

abstract class DropdownEvent {}

class LoadDropdownValues extends DropdownEvent {}

class TogglePasswordVisibility extends DropdownEvent {}
class SignUpData extends DropdownEvent {}
class ChangeDoctorRole extends DropdownEvent {}

class UpdateFirstDropdownValue extends DropdownEvent {
  final String newValue;
  UpdateFirstDropdownValue(this.newValue);
}

class UpdateSecondDropdownValues extends DropdownEvent {
  final String selectedFirstDropdownValue;
  UpdateSecondDropdownValues(this.selectedFirstDropdownValue);
}
class UpdateSpecialtyDropdownValue extends DropdownEvent {
  final String newValue;
  UpdateSpecialtyDropdownValue(this.newValue);
}
class UpdateUniversityDropdownValues extends DropdownEvent {
  final String selectedStateDropdownValue;
  UpdateUniversityDropdownValues(this.selectedStateDropdownValue);
}
/// Event that is dispatched when the SignUp widget is first created.
// class SignUpInitialEvent extends SignUpEvent {
//   @override
//   List<Object?> get props => [];
// }

// ///Event for changing password visibility
class ChangePasswordVisibilityEvent extends DropdownEvent {
  ChangePasswordVisibilityEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
}
//
// ///Event for changing checkbox
class ChangeCheckBoxEvent extends DropdownEvent {
  ChangeCheckBoxEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
}
class SignUpButtonPressed extends DropdownEvent {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final String userType;

  SignUpButtonPressed({required this.username, required this.password,required this.firstName,required this.lastName,required this.userType});

  @override
  List<Object> get props => [username, password,firstName,lastName,userType];
}
// class GetCountries extends SignUpEvent {
//   GetCountries();
//   @override
//   List<Object> get props => [];
// }
// class GetStates extends SignUpEvent {
//   String country;
//   GetStates(this.country);
//   @override
//   List<Object> get props => [country];
// }
