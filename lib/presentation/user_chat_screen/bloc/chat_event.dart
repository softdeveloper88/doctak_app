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
  List<Object?> get props => [value];
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
  List<Object?> get props => [value];
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
  ChatReadStatusEvent({this.userId, this.roomId});
  @override
  List<Object?> get props => [userId, Fontisto.room];
}

class LoadRoomMessageEvent extends ChatEvent {
  int? page;
  String? userId;
  String? roomId;
  bool? isFirstLoading;
  LoadRoomMessageEvent({this.page, this.userId, this.roomId, this.isFirstLoading = false});
  @override
  List<Object?> get props => [page, userId, roomId, isFirstLoading];
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
  CheckIfNeedMoreMessageDataEvent({required this.index, required this.userId, required this.roomId});
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
  SendMessageEvent({required this.userId, required this.roomId, required this.receiverId, required this.attachmentType, required this.file, required this.message});
  @override
  List<Object?> get props => [userId, roomId, receiverId, attachmentType, file, message];
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

// ======================== NEW CONVERSATION EVENTS ========================

class LoadConversationMessagesEvent extends ChatEvent {
  final int conversationId;
  final bool isFirstLoading;
  LoadConversationMessagesEvent({required this.conversationId, this.isFirstLoading = true});
  @override
  List<Object?> get props => [conversationId, isFirstLoading];
}

class SendConversationMessageEvent extends ChatEvent {
  final int conversationId;
  final String? message;
  final String? filePath;
  final String? attachmentType;
  final String? receiverId;
  SendConversationMessageEvent({
    required this.conversationId,
    this.message,
    this.filePath,
    this.attachmentType,
    this.receiverId,
  });
  @override
  List<Object?> get props => [conversationId, message, filePath, attachmentType];
}

class DeleteConversationMessageEvent extends ChatEvent {
  final int messageId;
  DeleteConversationMessageEvent({required this.messageId});
  @override
  List<Object?> get props => [messageId];
}

class MarkConversationReadEvent extends ChatEvent {
  final int conversationId;
  MarkConversationReadEvent({required this.conversationId});
  @override
  List<Object?> get props => [conversationId];
}

class LoadMoreMessagesEvent extends ChatEvent {
  final int conversationId;
  LoadMoreMessagesEvent({required this.conversationId});
  @override
  List<Object?> get props => [conversationId];
}

class NewMessageReceivedEvent extends ChatEvent {
  final ConversationMessage message;
  NewMessageReceivedEvent({required this.message});
  @override
  List<Object?> get props => [message.id];
}

// ======================== WEBSOCKET EVENTS ========================

class ConnectWebSocketEvent extends ChatEvent {
  final int conversationId;
  ConnectWebSocketEvent({required this.conversationId});
  @override
  List<Object?> get props => [conversationId];
}

class DisconnectWebSocketEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class SendTypingEvent extends ChatEvent {
  final bool isTyping;
  SendTypingEvent({required this.isTyping});
  @override
  List<Object?> get props => [isTyping];
}

class EditMessageEvent extends ChatEvent {
  final int messageId;
  final String body;
  EditMessageEvent({required this.messageId, required this.body});
  @override
  List<Object?> get props => [messageId, body];
}

class ToggleReactionEvent extends ChatEvent {
  final int messageId;
  final String emoji;
  ToggleReactionEvent({required this.messageId, required this.emoji});
  @override
  List<Object?> get props => [messageId, emoji];
}

// ─── Internal WS dispatch events (dispatched by the WS listener) ─────

class WsMessageCreatedEvent extends ChatEvent {
  final ConversationMessage message;
  WsMessageCreatedEvent({required this.message});
  @override
  List<Object?> get props => [message.id];
}

class WsMessageUpdatedEvent extends ChatEvent {
  final ConversationMessage message;
  WsMessageUpdatedEvent({required this.message});
  @override
  List<Object?> get props => [message.id];
}

class WsMessageDeletedEvent extends ChatEvent {
  final int messageId;
  final int conversationId;
  WsMessageDeletedEvent({required this.messageId, required this.conversationId});
  @override
  List<Object?> get props => [messageId, conversationId];
}

class WsReactionsUpdatedEvent extends ChatEvent {
  final int messageId;
  final List<MessageReaction> reactions;
  WsReactionsUpdatedEvent({required this.messageId, required this.reactions});
  @override
  List<Object?> get props => [messageId];
}

class WsTypingEvent extends ChatEvent {
  final String userId;
  final bool isTyping;
  final int conversationId;
  WsTypingEvent({required this.userId, required this.isTyping, required this.conversationId});
  @override
  List<Object?> get props => [userId, isTyping, conversationId];
}

class WsPresenceEvent extends ChatEvent {
  final String userId;
  final bool isOnline;
  WsPresenceEvent({required this.userId, required this.isOnline});
  @override
  List<Object?> get props => [userId, isOnline];
}

class WsDeliveredEvent extends ChatEvent {
  final int messageId;
  final String userId;
  WsDeliveredEvent({required this.messageId, required this.userId});
  @override
  List<Object?> get props => [messageId, userId];
}

class WsReadEvent extends ChatEvent {
  final int messageId;
  final String userId;
  WsReadEvent({required this.messageId, required this.userId});
  @override
  List<Object?> get props => [messageId, userId];
}

class ChatListMessageEvent extends ChatEvent {
  final int conversationId;
  final Map<String, dynamic> message;
  ChatListMessageEvent({required this.conversationId, required this.message});
  @override
  List<Object?> get props => [conversationId, message];
}

class ChatListTypingEvent extends ChatEvent {
  final int conversationId;
  final String userId;
  final bool isTyping;
  ChatListTypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}

class ChatListTypingRefreshEvent extends ChatEvent {
  ChatListTypingRefreshEvent();
  @override
  List<Object?> get props => [];
}

