// ignore_for_file: must_be_immutable

part of 'comment_bloc.dart';

abstract class CommentEvent extends Equatable{}

class LoadDataValues extends CommentEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends CommentEvent {
  ChangePasswordVisibilityEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
    value,
  ];
}
class ChangeCheckBoxEvent extends CommentEvent {
  ChangeCheckBoxEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
    value,
  ];
}
class LoadPageEvent extends CommentEvent{
  int? postId;
  LoadPageEvent({this.postId});
  @override
  List<Object?> get props => [postId];
}
class PostCommentEvent extends CommentEvent{
  int? postId;
  String? comment;
  PostCommentEvent({this.postId,this.comment});
  @override
  List<Object?> get props => [postId,comment];
}


class CheckIfNeedMoreDataEvent extends CommentEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}

