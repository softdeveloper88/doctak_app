abstract class CmeQuizState {}

class CmeQuizInitialState extends CmeQuizState {}

class CmeQuizLoadingState extends CmeQuizState {}

class CmeQuizLoadedState extends CmeQuizState {}

class CmeQuizAnswerSelectedState extends CmeQuizState {}

class CmeQuizSubmittingState extends CmeQuizState {}

class CmeQuizSubmittedState extends CmeQuizState {
  final String message;
  CmeQuizSubmittedState({this.message = 'Quiz submitted successfully'});
}

class CmeQuizResultsLoadedState extends CmeQuizState {}

class CmeQuizTimerUpdateState extends CmeQuizState {
  final int remainingSeconds;
  CmeQuizTimerUpdateState(this.remainingSeconds);
}

class CmeQuizTimerExpiredState extends CmeQuizState {}

class CmeQuizAutoSavedState extends CmeQuizState {}

class CmeQuizErrorState extends CmeQuizState {
  final String message;
  CmeQuizErrorState(this.message);
}
