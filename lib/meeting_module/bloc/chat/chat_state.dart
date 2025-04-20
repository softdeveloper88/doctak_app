import 'package:doctak_app/meeting_module/models/message.dart';
import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final int unreadCount;

  const ChatLoaded({
    required this.messages,
    this.unreadCount = 0,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    int? unreadCount,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object> get props => [messages, unreadCount];
}

class MessageSent extends ChatState {}

class AttachmentUploading extends ChatState {}

class AttachmentUploaded extends ChatState {
  final String attachmentUrl;

  const AttachmentUploaded(this.attachmentUrl);

  @override
  List<Object> get props => [attachmentUrl];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}