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
  List<Object?> get props => [value];
}

class ChangeCheckBoxEvent extends DropdownEvent {
  ChangeCheckBoxEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [value];
}

class SignUpButtonPressed extends DropdownEvent {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final String country;
  final String state;
  final String specialty;
  final String userType;
  final String deviceToken;

  SignUpButtonPressed({
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.state,
    required this.specialty,
    required this.userType,
    required this.deviceToken,
  });

  @override
  List<Object> get props => [username, password, firstName, lastName, country, state, specialty, userType, deviceToken];
}

class SocialButtonPressed extends DropdownEvent {
  final String token;
  final String firstName;
  final String lastName;
  final String phone;
  final String country;
  final String state;
  final String specialty;
  final String userType;
  final String deviceToken;

  SocialButtonPressed({
    required this.token,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.country,
    required this.state,
    required this.specialty,
    required this.userType,
    required this.deviceToken,
  });

  @override
  List<Object> get props => [token, firstName, lastName, phone, country, state, specialty, userType, deviceToken];
}

class CompleteButtonPressed extends DropdownEvent {
  final String country;
  final String state;
  final String specialty;

  CompleteButtonPressed({required this.country, required this.state, required this.specialty});

  @override
  List<Object> get props => [country, state, specialty];
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
