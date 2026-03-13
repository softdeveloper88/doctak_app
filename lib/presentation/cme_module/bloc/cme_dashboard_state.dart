abstract class CmeDashboardState {}

class CmeDashboardInitialState extends CmeDashboardState {}

class CmeDashboardLoadingState extends CmeDashboardState {}

class CmeDashboardLoadedState extends CmeDashboardState {}

class CmeDashboardErrorState extends CmeDashboardState {
  final String errorMessage;
  CmeDashboardErrorState(this.errorMessage);
}

class CmeMyEventsLoadingState extends CmeDashboardState {}

class CmeMyEventsLoadedState extends CmeDashboardState {}
