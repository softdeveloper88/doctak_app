import 'package:doctak_app/data/models/countries_model/countries_model.dart';

abstract class SplashState {}

class CountriesDataInitial extends SplashState {}

class CountriesDataLoaded extends SplashState {
  CountriesModel countriesModel;
  String countryFlag;
  String typeValue;
  String? searchTerms = '';

  CountriesDataLoaded({required this.countriesModel, required this.countryFlag, required this.typeValue, required this.searchTerms});
}

class CountriesDataLoaded1 extends SplashState {
  List<dynamic> countriesModelList;
  String countryName;
  String? searchTerms = '';
  CountriesDataLoaded1({required this.countriesModelList, required this.countryName, required this.searchTerms});
}

class CountriesDataError extends SplashState {
  final String errorMessage;
  CountriesDataError(this.errorMessage);
}
