import '../../../../../../../../data/models/conference_model/search_conference_model.dart';

abstract class ConferenceState {}

class ConferenceDataInitial extends ConferenceState {}

class CountriesDataLoaded extends ConferenceState {
  List<dynamic> countriesModel;
  String countryName;
  String? searchTerms = '';
  CountriesDataLoaded({required this.countriesModel, required this.countryName, required this.searchTerms});
}

class DataError extends ConferenceState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends ConferenceState {
  PaginationInitialState();
}

class PaginationLoadedState extends ConferenceState {}

class PaginationLoadedState1 extends ConferenceState {
  List<Data> data;
  PaginationLoadedState1(this.data);
}

class PaginationLoadingState extends ConferenceState {}

class PaginationErrorState extends ConferenceState {}
