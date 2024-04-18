// ignore_for_file: must_be_immutable
import 'package:equatable/equatable.dart';
/// Represents the state of Forgot in the application.
// part 'login_bloc.dart';

abstract class ForgotState  {}
class ForgotInitial extends ForgotState {}

class ForgotLoading extends ForgotState {}

class ForgotSuccess extends ForgotState {
  final String response;
  ForgotSuccess({required this.response});
}
class ForgotFailure extends ForgotState {
  final String error;
  ForgotFailure({required this.error});

}






