abstract class CmeEventsState {}

class CmeEventsInitialState extends CmeEventsState {}

class CmeEventsLoadingState extends CmeEventsState {}

class CmeEventsLoadedState extends CmeEventsState {}

class CmeEventsErrorState extends CmeEventsState {
  final String errorMessage;
  CmeEventsErrorState(this.errorMessage);
}

class CmeFiltersLoadedState extends CmeEventsState {
  final List<String> specialties;
  final List<String> categories;

  CmeFiltersLoadedState({
    required this.specialties,
    required this.categories,
  });
}
