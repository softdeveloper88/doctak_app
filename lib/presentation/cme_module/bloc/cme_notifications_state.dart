abstract class CmeNotificationsState {}

class CmeNotificationsInitialState extends CmeNotificationsState {}

class CmeNotificationsLoadingState extends CmeNotificationsState {}

class CmeNotificationsLoadedState extends CmeNotificationsState {}

class CmeNotificationsErrorState extends CmeNotificationsState {
  final String errorMessage;
  CmeNotificationsErrorState(this.errorMessage);
}
