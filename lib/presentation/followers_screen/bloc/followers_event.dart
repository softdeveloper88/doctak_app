part of 'followers_bloc.dart';

abstract class FollowersEvent extends Equatable {}

class LoadDataValues extends FollowersEvent {
  @override
  List<Object?> get props => [];
}

class FollowersLoadPageEvent extends FollowersEvent {
  int? page;
  final String? searchTerm;
  final String? userId;

  FollowersLoadPageEvent({this.page, this.searchTerm, this.userId});
  @override
  List<Object?> get props => [page, searchTerm, userId];
}

class SetUserFollow extends FollowersEvent {
  String userId;
  String follow;
  SetUserFollow(this.userId, this.follow);
  @override
  List<Object?> get props => [userId, follow];
}

class SearchPeopleCheckIfNeedMoreDataEvent extends FollowersEvent {
  final int index;
  SearchPeopleCheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
