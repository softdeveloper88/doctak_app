// ignore_for_file: must_be_immutable
part of 'likes_bloc.dart';

abstract class LikesEvent extends Equatable {}

class LoadDataValues extends LikesEvent {
  @override
  List<Object?> get props => [];
}

class LoadPageEvent extends LikesEvent {
  int? postId;
  LoadPageEvent({this.postId});
  @override
  List<Object?> get props => [postId];
}

class CheckIfNeedMoreDataEvent extends LikesEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
