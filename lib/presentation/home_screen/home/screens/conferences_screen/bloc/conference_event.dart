import 'package:equatable/equatable.dart';

abstract class ConferenceEvent extends Equatable {}

class LoadDataValues extends ConferenceEvent {
  @override
  List<Object?> get props => [];
}

class LoadPageEvent extends ConferenceEvent {
  final int? page;
  final String? countryName;
  final String? searchTerm;
  final String? month;

  LoadPageEvent({
    this.page,
    this.countryName,
    this.searchTerm,
    this.month,
  });

  @override
  List<Object?> get props => [page, countryName, searchTerm, month];
}

class LoadDropdownData extends ConferenceEvent {
  final String countryName;
  final String searchTerms;
  LoadDropdownData(this.countryName, this.searchTerms);
  @override
  List<Object?> get props => [countryName, searchTerms];
}

class CheckIfNeedMoreDataEvent extends ConferenceEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
