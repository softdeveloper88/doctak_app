abstract class CmeProfileState {}

class CmeProfileInitialState extends CmeProfileState {}

class CmeProfileLoadingState extends CmeProfileState {}

class CmeProfileLoadedState extends CmeProfileState {}

class CmeTranscriptLoadedState extends CmeProfileState {}

class CmeAchievementsLoadedState extends CmeProfileState {}

class CmeProfileErrorState extends CmeProfileState {
  final String message;
  CmeProfileErrorState(this.message);
}
