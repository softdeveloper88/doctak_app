import 'package:doctak_app/meeting_module/models/message.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistory extends ChatEvent {
  final String meetingId;

  const LoadChatHistory(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class SendMessageEvent extends ChatEvent {
  final String meetingId;
  final String userId;
  final String message;
  final String? attachmentUrl;

  const SendMessageEvent({
    required this.meetingId,
    required this.userId,
    required this.message,
    this.attachmentUrl,
  });

  @override
  List<Object?> get props => [meetingId, userId, message, attachmentUrl];
}

class UploadAttachmentEvent extends ChatEvent {
  final String meetingId;
  final File file;

  const UploadAttachmentEvent({
    required this.meetingId,
    required this.file,
  });

  @override
  List<Object> get props => [meetingId, file];
}

class NewMessageReceivedEvent extends ChatEvent {
  final Message message;

  const NewMessageReceivedEvent(this.message);

  @override
  List<Object> get props => [message];
}

class ClearChatEvent extends ChatEvent {}