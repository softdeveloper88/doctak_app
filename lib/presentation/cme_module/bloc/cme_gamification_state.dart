abstract class CmeGamificationState {}

class CmeGamificationInitialState extends CmeGamificationState {}

class CmeGamificationLoadingState extends CmeGamificationState {}

class CmeGamificationLoadedState extends CmeGamificationState {}

class CmeGamificationErrorState extends CmeGamificationState {
  final String message;
  CmeGamificationErrorState(this.message);
}
