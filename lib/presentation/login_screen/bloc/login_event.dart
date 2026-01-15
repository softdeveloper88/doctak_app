import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {}
// const LoginEvent();

// @override
// List<Object> get props => [];
// }
class LoginInitialEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends LoginEvent {
  final bool value;
  ChangePasswordVisibilityEvent({required this.value});
  @override
  List<Object?> get props => [value];
}

class LoginButtonPressed extends LoginEvent {
  final String username;
  final String password;
  final bool rememberMe;
  final String deviceToken;

  LoginButtonPressed({required this.username, required this.password, required this.rememberMe, required this.deviceToken});

  @override
  List<Object> get props => [username, password, rememberMe, deviceToken];
}

class SocialLoginButtonPressed extends LoginEvent {
  final String email;
  final String firstName;
  final String lastName;
  final bool isSocialLogin;
  final String provider;
  final String token;
  final String deviceToken;

  SocialLoginButtonPressed({required this.email, required this.firstName, required this.lastName, required this.isSocialLogin, required this.provider, required this.token, required this.deviceToken});

  @override
  List<Object> get props => [email, firstName, lastName, isSocialLogin, provider, token, deviceToken];
}
