abstract class CmeAnalyticsState {}

class CmeAnalyticsInitialState extends CmeAnalyticsState {}

class CmeAnalyticsLoadingState extends CmeAnalyticsState {}

class CmeAnalyticsLoadedState extends CmeAnalyticsState {}

class CmeAnalyticsExportedState extends CmeAnalyticsState {
  final String downloadUrl;
  CmeAnalyticsExportedState(this.downloadUrl);
}

class CmeAnalyticsErrorState extends CmeAnalyticsState {
  final String message;
  CmeAnalyticsErrorState(this.message);
}
