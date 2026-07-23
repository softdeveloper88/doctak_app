// ignore_for_file: must_be_immutable
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:equatable/equatable.dart';

/// Represents the state of Login in the application.
// part 'login_bloc.dart';

class LoginState extends Equatable {
  LoginState({this.isShowPassword = false});
  bool isShowPassword;
  @override
  List<Object?> get props => [isShowPassword];
  LoginState copyWith({bool? isShowPassword}) {
    return LoginState(isShowPassword: isShowPassword ?? this.isShowPassword);
  }
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {
  LoginLoading({super.isShowPassword});
}

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

class LoginRequiresTwoFactor extends LoginState {
  LoginRequiresTwoFactor({
    required this.pendingToken,
    required this.methods,
    this.maskedEmail,
    this.message,
    this.emailSent = true,
    required this.rememberMe,
    required this.deviceToken,
  });

  final String pendingToken;
  final Map<String, bool> methods;
  final String? maskedEmail;
  final String? message;
  final bool emailSent;
  final bool rememberMe;
  final String deviceToken;

  @override
  List<Object?> get props =>
      [pendingToken, methods, maskedEmail, message, emailSent, rememberMe, deviceToken];
}
