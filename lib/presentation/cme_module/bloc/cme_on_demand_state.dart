abstract class CmeOnDemandState {}

class CmeOnDemandInitialState extends CmeOnDemandState {}

class CmeOnDemandLoadingState extends CmeOnDemandState {}

class CmeOnDemandLoadedState extends CmeOnDemandState {}

class CmeOnDemandDetailLoadedState extends CmeOnDemandState {}

class CmeOnDemandSectionCompletedState extends CmeOnDemandState {}

class CmeOnDemandErrorState extends CmeOnDemandState {
  final String message;
  CmeOnDemandErrorState(this.message);
}
