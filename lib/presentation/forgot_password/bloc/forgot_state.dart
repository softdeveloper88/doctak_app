/// Represents the state of Forgot in the application.
library;

abstract class ForgotState {
  const ForgotState();
}

class ForgotInitial extends ForgotState {
  const ForgotInitial();
}

class ForgotLoading extends ForgotState {
  const ForgotLoading();
}

class ForgotSuccess extends ForgotState {
  final String response;
  final String message;

  const ForgotSuccess({
    required this.response,
    required this.message,
  });
}

class ForgotFailure extends ForgotState {
  final String error;

  const ForgotFailure({required this.error});
}
