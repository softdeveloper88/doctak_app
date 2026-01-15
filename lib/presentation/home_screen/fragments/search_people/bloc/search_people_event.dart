import 'package:equatable/equatable.dart';

// abstract class SearchPeopleEvent extends Equatable{}
//
// class LoadDataValues extends SearchPeopleEvent {
//   @override
//   List<Object?> get props => [];
// }
//
// class GetPost extends SearchPeopleEvent {
//   final String page;
//
//   GetPost({required this.page});
//
//   @override
//   List<Object> get props => [page];
// }
abstract class SearchPeopleEvent extends Equatable {}

class LoadDataValues extends SearchPeopleEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends SearchPeopleEvent {
  final String page;
  final String searchTerm;

  GetPost({required this.page, required this.searchTerm});
  @override
  List<Object> get props => [page, searchTerm];
}

class SearchPeopleLoadPageEvent extends SearchPeopleEvent {
  int? page;
  final String? searchTerm;

  SearchPeopleLoadPageEvent({this.page, this.searchTerm});
  @override
  List<Object?> get props => [page, searchTerm];
}

class SearchFieldData extends SearchPeopleEvent {
  String searchValue;
  SearchFieldData(this.searchValue);
  @override
  List<Object?> get props => [searchValue];
}

class SetUserFollow extends SearchPeopleEvent {
  String userId;
  String follow;
  SetUserFollow(this.userId, this.follow);
  @override
  List<Object?> get props => [userId, follow];
}

class SearchPeopleCheckIfNeedMoreDataEvent extends SearchPeopleEvent {
  final int index;
  SearchPeopleCheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
