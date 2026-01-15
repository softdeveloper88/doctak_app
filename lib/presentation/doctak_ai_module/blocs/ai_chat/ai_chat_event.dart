part of 'ai_chat_bloc.dart';

abstract class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends AiChatEvent {}

class CreateSession extends AiChatEvent {
  final String? name;

  const CreateSession({this.name});

  @override
  List<Object?> get props => [name];
}

class SelectSession extends AiChatEvent {
  final String sessionId;

  const SelectSession({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class SendMessage extends AiChatEvent {
  final String message;
  final String model;
  final double temperature;
  final int maxTokens;
  final bool webSearch;
  final String? searchContextSize;
  final String? userLocationCountry;
  final String? userLocationCity;
  final String? userLocationRegion;
  final File? file;
  final bool suggestTitle;
  final bool useStreaming;

  const SendMessage({
    required this.message,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.webSearch = false,
    this.searchContextSize,
    this.userLocationCountry,
    this.userLocationCity,
    this.userLocationRegion,
    this.file,
    this.suggestTitle = true,
    this.useStreaming = true, // Default to streaming for better UX
  });

  @override
  List<Object?> get props => [message, model, temperature, maxTokens, webSearch, searchContextSize, userLocationCountry, userLocationCity, userLocationRegion, file, suggestTitle, useStreaming];
}

class StreamMessageReceived extends AiChatEvent {
  final String content;
  final bool isNewChunk; // Flag to indicate if this is a new chunk to append

  const StreamMessageReceived({
    required this.content,
    this.isNewChunk = true, // Default to true for backward compatibility
  });

  @override
  List<Object> get props => [content, isNewChunk];
}

class StreamMessageCompleted extends AiChatEvent {
  final String sessionId;
  final bool isFirstMessage;

  const StreamMessageCompleted({required this.sessionId, this.isFirstMessage = false});

  @override
  List<Object> get props => [sessionId, isFirstMessage];
}

class StreamMessageError extends AiChatEvent {
  final String errorMessage;

  const StreamMessageError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

class CancelStreamingMessage extends AiChatEvent {}

class DeleteSession extends AiChatEvent {
  final String sessionId;

  const DeleteSession({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class RenameSession extends AiChatEvent {
  final String sessionId;
  final String name;

  const RenameSession({required this.sessionId, required this.name});

  @override
  List<Object> get props => [sessionId, name];
}

class SubmitFeedback extends AiChatEvent {
  final String messageId;
  final String feedback; // 'positive' or 'negative'

  const SubmitFeedback({required this.messageId, required this.feedback});

  @override
  List<Object> get props => [messageId, feedback];
}

class ClearCurrentSession extends AiChatEvent {}
