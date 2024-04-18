
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
  ChangePasswordVisibilityEvent({required this.value});
  bool value;
  @override
  List<Object?> get props => [
    value,
  ];
}
class LoginButtonPressed extends LoginEvent {
  final String username;
  final String password;

  LoginButtonPressed({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}
class SocialLoginButtonPressed extends LoginEvent {
  final String email;
  final String firstName;
  final String lastName;
  final bool isSocialLogin;
  final String provider;
  final String token;

  SocialLoginButtonPressed({required this.email, required this.firstName,required this.lastName,required this.isSocialLogin,required this.provider,required this.token});

  @override
  List<Object> get props => [email, firstName,lastName,isSocialLogin,provider,token];
}