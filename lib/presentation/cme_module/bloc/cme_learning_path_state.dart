abstract class CmeLearningPathState {}

class CmeLearningPathInitialState extends CmeLearningPathState {}

class CmeLearningPathLoadingState extends CmeLearningPathState {}

class CmeLearningPathLoadedState extends CmeLearningPathState {}

class CmeLearningPathDetailLoadedState extends CmeLearningPathState {}

class CmeLearningPathEnrolledState extends CmeLearningPathState {
  final String message;
  CmeLearningPathEnrolledState({this.message = 'Enrolled successfully'});
}

class CmeLearningPathUnenrolledState extends CmeLearningPathState {
  final String message;
  CmeLearningPathUnenrolledState({this.message = 'Unenrolled successfully'});
}

class CmeLearningPathPausedState extends CmeLearningPathState {}

class CmeLearningPathResumedState extends CmeLearningPathState {}

class CmeLearningPathErrorState extends CmeLearningPathState {
  final String message;
  CmeLearningPathErrorState(this.message);
}
