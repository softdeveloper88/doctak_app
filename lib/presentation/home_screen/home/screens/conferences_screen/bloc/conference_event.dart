import 'package:equatable/equatable.dart';

abstract class ConferenceEvent extends Equatable{}

class LoadDataValues extends ConferenceEvent {
  @override
  List<Object?> get props => [];
}

// class GetConferences extends ConferenceEvent {
//   final String page;
//   final String countryName;
//   final String searchTerm;
//
//   GetConferences({required this.page,required this.countryName,required this.searchTerm,});
//   @override
//   List<Object> get props => [page,countryName,searchTerm];
// }

class LoadPageEvent extends ConferenceEvent {
 int? page;
 final String? countryName;
 final String? searchTerm;

 LoadPageEvent({this.page,this.countryName,this.searchTerm});
  @override
  List<Object?> get props => [page,countryName,searchTerm];
}
class LoadDropdownData extends ConferenceEvent {
final String countryName;
final String searchTerms;
LoadDropdownData(this.countryName,this.searchTerms);
@override
List<Object?> get props => [countryName,searchTerms];
}

class CheckIfNeedMoreDataEvent extends ConferenceEvent {
  final int index;
   CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
