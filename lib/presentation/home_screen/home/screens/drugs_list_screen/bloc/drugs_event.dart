import 'package:equatable/equatable.dart';
abstract class DrugsEvent extends Equatable{}

class LoadDataValues extends DrugsEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends DrugsEvent {
  final String page;
  final String countryId;
  final String type;
  final String searchTerm;

  GetPost({required this.page,required this.countryId,required this.searchTerm,required this.type});
  @override
  List<Object> get props => [page,countryId,searchTerm,type];
}
class LoadPageEvent extends DrugsEvent {
 final int? page;
 final String? countryId;
 final String? type;
 final String? searchTerm;

 LoadPageEvent({this.page,this.countryId,this.type,this.searchTerm});
  @override
  List<Object?> get props => [page,countryId,type,searchTerm];
}

class CheckIfNeedMoreDataEvent extends DrugsEvent {
  final int index;
   CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
