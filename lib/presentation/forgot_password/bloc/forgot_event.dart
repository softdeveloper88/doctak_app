import 'package:equatable/equatable.dart';

abstract class ForgotEvent extends Equatable {}

class ForgotInitialEvent extends ForgotEvent {
  @override
  List<Object?> get props => [];
}

class ForgotPasswordEvent extends ForgotEvent {
  final String username;

  ForgotPasswordEvent({
    required this.username,
  });

  @override
  List<Object> get props => [
        username,
      ];
}
