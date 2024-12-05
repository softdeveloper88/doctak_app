// ignore_for_file: must_be_immutable

part of 'comment_bloc.dart';

abstract class CommentEvent extends Equatable {}

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

class LoadPageEvent extends CommentEvent {
  int? postId;
  int? page;
  LoadPageEvent({this.postId,this.page});
  @override
  List<Object?> get props => [postId,page];
}

class PostCommentEvent extends CommentEvent {
  int? postId;
  String? comment;
  PostCommentEvent({this.postId, this.comment});
  @override
  List<Object?> get props => [postId, comment];
}
class ReplyComment extends CommentEvent {
  String? postId;
  String? commentId;
  String? commentText;
  ReplyComment({this.commentId,this.postId,this.commentText});
  @override
  List<Object?> get props => [ commentId,postId,commentText];
}
class LikeReplyComment extends CommentEvent {
  String? commentId;
  LikeReplyComment({this.commentId});
  @override
  List<Object?> get props => [ commentId];
}
class FetchReplyComment extends CommentEvent {
  String? commentId;
  String? postId;
  FetchReplyComment({this.commentId,this.postId});
  @override
  List<Object?> get props => [ commentId,postId];
}


class DeleteCommentEvent extends CommentEvent {
  String? commentId;
  DeleteCommentEvent({
    this.commentId,
  });
  @override
  List<Object?> get props => [commentId];
}
class DeleteReplyCommentEvent extends CommentEvent {
  String? commentId;
  DeleteReplyCommentEvent({
    this.commentId,
  });
  @override
  List<Object?> get props => [commentId];

}
class UpdateReplyCommentEvent extends CommentEvent {
  String? commentId;
  String? content;
  UpdateReplyCommentEvent({
    this.commentId,
    this.content,
  });
  @override
  List<Object?> get props => [commentId,content];

}

class CheckIfNeedMoreDataEvent extends CommentEvent {
  final int index;
  final int postId;
  CheckIfNeedMoreDataEvent({required this.postId,required this.index});
  @override
  List<Object?> get props => [index];
}
