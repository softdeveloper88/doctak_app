// ignore_for_file: must_be_immutable
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:equatable/equatable.dart';
/// Represents the state of Login in the application.
// part 'login_bloc.dart';

class LoginState extends Equatable {
  LoginState({ this.isShowPassword = true,});
  bool isShowPassword;
  @override
  List<Object?> get props => [
    isShowPassword,
  ];
  LoginState copyWith({
    bool? isShowPassword,
  }) {
    return LoginState(
      isShowPassword: isShowPassword ?? this.isShowPassword,
    );
  }
}
class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String isEmailVerified;
  LoginSuccess({required this.isEmailVerified});

  @override
  List<Object> get props => [isEmailVerified];
}
class SocialLoginSuccess extends LoginState {
  final PostLoginDeviceAuthResp response;
  SocialLoginSuccess({required this.response});

  @override
  List<Object> get props => [response];
}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}






