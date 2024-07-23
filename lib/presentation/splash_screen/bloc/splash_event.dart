import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {}

class LoadDataValues extends SplashEvent {
  @override
  List<Object?> get props => [];
}

class LoadDropdownInitData extends SplashEvent {
  @override
  List<Object?> get props => [];
}

class LoadDropdownData1 extends SplashEvent {
  final String countryName;
  final String searchTerms;
  LoadDropdownData1(this.countryName, this.searchTerms);
  @override
  List<Object?> get props => [countryName, searchTerms];
}

class LoadDropdownData extends SplashEvent {
  // CountriesModel? countriesModel;
  String countryFlag;
  String typeValue;
  String searchTerms;
  String? isExpired = "New";
  LoadDropdownData(
      this.countryFlag, this.typeValue, this.searchTerms, this.isExpired);
  @override
  List<Object?> get props => [countryFlag, typeValue, searchTerms, isExpired];
}
