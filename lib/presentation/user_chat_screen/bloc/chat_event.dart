// ignore_for_file: must_be_immutable

part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {}

class LoadDataValues extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends ChatEvent {
  ChangePasswordVisibilityEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
}

class PostLikeEvent extends ChatEvent {
  int? postId;
  PostLikeEvent({this.postId});
  @override
  List<Object?> get props => [postId];
}

class ChangeCheckBoxEvent extends ChatEvent {
  ChangeCheckBoxEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
}

class LoadPageEvent extends ChatEvent {
  int? page;
  LoadPageEvent({this.page});
  @override
  List<Object?> get props => [page];
}

class LoadContactsEvent extends ChatEvent {
  int? page;
  String? keyword;
  LoadContactsEvent({this.page, this.keyword});
  @override
  List<Object?> get props => [page, keyword];
}
class ChatReadStatusEvent extends ChatEvent {
  String? userId;
  String? roomId;
  ChatReadStatusEvent({this.userId,this.roomId});
  @override
  List<Object?> get props => [userId,Fontisto.room];
}

class LoadRoomMessageEvent extends ChatEvent {
  int? page;
  String? userId;
  String? roomId;
  bool? isFirstLoading;
  LoadRoomMessageEvent({this.page, this.userId, this.roomId,this.isFirstLoading=false});
  @override
  List<Object?> get props => [page, userId, roomId,isFirstLoading];
}

class CheckIfNeedMoreDataEvent extends ChatEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}

class CheckIfNeedMoreContactDataEvent extends ChatEvent {
  final int index;
  CheckIfNeedMoreContactDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}

class CheckIfNeedMoreMessageDataEvent extends ChatEvent {
  final int index;
  String userId;
  String roomId;
  CheckIfNeedMoreMessageDataEvent(
      {required this.index, required this.userId, required this.roomId});
  @override
  List<Object?> get props => [index, userId, roomId];
}

class SendMessageEvent extends ChatEvent {
  String? userId;
  String? roomId;
  String? receiverId;
  String? attachmentType;
  String? file;
  String? message;
  SendMessageEvent(
      {required this.userId,
      required this.roomId,
      required this.receiverId,
      required this.attachmentType,
      required this.file,
      required this.message});
  @override
  List<Object?> get props =>
      [userId, roomId, receiverId, attachmentType, file, message];
}

class DeleteMessageEvent extends ChatEvent {
  String? id;

  DeleteMessageEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class SelectedFiles extends ChatEvent {
  XFile pickedfiles;
  bool isRemove;
  SelectedFiles({required this.pickedfiles, required this.isRemove});
  @override
  List<Object?> get props => [pickedfiles, isRemove];
}
