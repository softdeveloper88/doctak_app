// ignore_for_file: must_be_immutable

part of 'sign_up_success_bloc.dart';

/// Abstract class for all events that can be dispatched from the
///SignUpSuccess widget.
///
/// Events must be immutable and implement the [Equatable] interface.
@immutable
abstract class SignUpSuccessEvent extends Equatable {}

/// Event that is dispatched when the SignUpSuccess widget is first created.
class SignUpSuccessInitialEvent extends SignUpSuccessEvent {
  @override
  List<Object?> get props => [];
}
