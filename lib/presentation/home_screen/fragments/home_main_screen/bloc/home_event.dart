// ignore_for_file: must_be_immutable

part of 'home_bloc.dart';


abstract class HomeEvent extends Equatable{}

class LoadDataValues extends HomeEvent {
  @override
  List<Object?> get props => [];
}


class ChangePasswordVisibilityEvent extends HomeEvent {
  ChangePasswordVisibilityEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
}
class PostLikeEvent extends HomeEvent{
  int? postId;
  PostLikeEvent({this.postId});
  @override
  List<Object?> get props => [postId];
}
class PostUserLikeEvent extends HomeEvent{
  int? postId;
  PostUserLikeEvent({this.postId});
  @override
  List<Object?> get props => [postId];
}
class DeletePostEvent extends HomeEvent{
  int? postId;
  DeletePostEvent({this.postId});
  @override
  List<Object?> get props => [postId];
}
class ChangeCheckBoxEvent extends HomeEvent {
  ChangeCheckBoxEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
}
class PostLoadPageEvent extends HomeEvent{
  int? page;
PostLoadPageEvent({this.page});
@override
List<Object?> get props => [page];
}
class LoadSearchPageEvent extends HomeEvent{
  int? page;
  String? search;
LoadSearchPageEvent({this.page,this.search});
@override
List<Object?> get props => [page,search];
}

class PostCheckIfNeedMoreDataEvent extends HomeEvent {
  final int index;
  PostCheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
class AdsSettingEvent extends HomeEvent {

  AdsSettingEvent();
  @override
  List<Object?> get props => [];
}

