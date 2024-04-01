// // ignore_for_file: must_be_immutable
//
// part of 'login_bloc.dart';
//
// /// Abstract class for all events that can be dispatched from the
// ///Login widget.
// ///
// /// Events must be immutable and implement the [Equatable] interface.
// @immutable
// abstract class LoginEvent extends Equatable {}
//
// /// Event that is dispatched when the Login widget is first created.
// class LoginInitialEvent extends LoginEvent {
//   @override
//   List<Object?> get props => [];
// }
//
// ///Event that is dispatched when the user calls the https://nodedemo.dhiwise.co/device/auth/login API.
// class CreateLoginEvent extends LoginEvent {
//   // CreateLoginEvent();
//   // @override
//   // List<PostLoginDeviceAuthReq?> get props => [
//   //
//   // ];
//
//   CreateLoginEvent();
//   @override
//   List<Object> get props => [
//
//   ];
//
// }
//
// ///Event for changing password visibility
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