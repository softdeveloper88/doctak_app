abstract class CmeEventDetailState {}

class CmeEventDetailInitialState extends CmeEventDetailState {}

class CmeEventDetailLoadingState extends CmeEventDetailState {}

class CmeEventDetailLoadedState extends CmeEventDetailState {}

class CmeEventDetailErrorState extends CmeEventDetailState {
  final String errorMessage;
  CmeEventDetailErrorState(this.errorMessage);
}

class CmeRegistrationSuccessState extends CmeEventDetailState {
  final String message;
  CmeRegistrationSuccessState(this.message);
}

class CmeRegistrationErrorState extends CmeEventDetailState {
  final String message;
  CmeRegistrationErrorState(this.message);
}

class CmeJoinedEventState extends CmeEventDetailState {}

class CmeWaitlistJoinedState extends CmeEventDetailState {
  final String message;
  CmeWaitlistJoinedState(this.message);
}
