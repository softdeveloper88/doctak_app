part of 'sign_up_bloc.dart';

abstract class DropdownState {}

class DropdownInitial extends DropdownState {}

class SocialLoginSuccess extends DropdownState {
  SocialLoginSuccess();
}

class DataLoaded extends DropdownState {
  final bool isPasswordVisible;
  bool isDoctorRole;
  bool isSubmit;
  Map<String, dynamic> response;
  DataLoaded(this.isPasswordVisible, this.isDoctorRole, this.isSubmit, this.response);
}

class DataCompleteLoaded extends DropdownState {
  Map<String, dynamic> response;
  DataCompleteLoaded(this.response);
}

class DropdownError extends DropdownState {
  final String errorMessage;
  DropdownError(this.errorMessage);
}
