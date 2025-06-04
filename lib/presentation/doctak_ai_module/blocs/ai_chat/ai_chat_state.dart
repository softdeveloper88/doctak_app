part of 'ai_chat_bloc.dart';

abstract class AiChatState extends Equatable {
  const AiChatState();
  
  @override
  List<Object?> get props => [];
}

class AiChatInitial extends AiChatState {}

// Sessions list states
class SessionsLoading extends AiChatState {}

class SessionsLoaded extends AiChatState {
  final List<AiChatSessionModel> sessions;

  const SessionsLoaded({
    required this.sessions,
  });

  @override
  List<Object> get props => [sessions];
}

class SessionsLoadError extends AiChatState {
  final String message;
  final List<AiChatSessionModel>? sessions;

  const SessionsLoadError({
    required this.message,
    this.sessions,
  });

  @override
  List<Object?> get props => [message, sessions];
}

// Session creation states
class SessionCreating extends AiChatState {
  final List<AiChatSessionModel> sessions;

  const SessionCreating({
    required this.sessions,
  });

  @override
  List<Object> get props => [sessions];
}

class SessionCreated extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel newSession;

  const SessionCreated({
    required this.sessions,
    required this.newSession,
  });

  @override
  List<Object> get props => [sessions, newSession];
}

class SessionCreateError extends AiChatState {
  final String message;
  final List<AiChatSessionModel> sessions;

  const SessionCreateError({
    required this.message,
    required this.sessions,
  });

  @override
  List<Object> get props => [message, sessions];
}

// Session selection states
class SessionLoading extends AiChatState {
  final List<AiChatSessionModel> sessions;

  const SessionLoading({
    required this.sessions,
  });

  @override
  List<Object> get props => [sessions];
}

class SessionSelected extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel selectedSession;
  final List<AiChatMessageModel> messages;

  const SessionSelected({
    required this.sessions,
    required this.selectedSession,
    required this.messages,
  });

  @override
  List<Object> get props => [sessions, selectedSession, messages];
}

class SessionLoadError extends AiChatState {
  final String message;
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel? selectedSession;
  final List<AiChatMessageModel>? messages;

  const SessionLoadError({
    required this.message,
    required this.sessions,
    this.selectedSession,
    this.messages,
  });

  @override
  List<Object?> get props => [message, sessions, selectedSession, messages];
}

// Message sending states
class MessageSending extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel selectedSession;
  final List<AiChatMessageModel> messages;
  final bool isFirstMessage;

  const MessageSending({
    required this.sessions,
    required this.selectedSession,
    required this.messages,
    this.isFirstMessage = false,
  });

  @override
  List<Object> get props => [sessions, selectedSession, messages, isFirstMessage];
}

// Streaming response state
class MessageStreaming extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel selectedSession;
  final List<AiChatMessageModel> messages;
  final bool isFirstMessage;
  final String partialResponse;
  
  const MessageStreaming({
    required this.sessions,
    required this.selectedSession,
    required this.messages,
    this.isFirstMessage = false,
    required this.partialResponse,
  });
  
  @override
  List<Object> get props => [sessions, selectedSession, messages, isFirstMessage, partialResponse];
  
  // Create a new state with updated partial response
  MessageStreaming copyWithPartialResponse(String newPartialResponse) {
    return MessageStreaming(
      sessions: sessions,
      selectedSession: selectedSession,
      messages: messages,
      isFirstMessage: isFirstMessage,
      partialResponse: newPartialResponse,
    );
  }
}

class MessageSent extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel selectedSession;
  final List<AiChatMessageModel> messages;
  final AiChatMessageModel lastUserMessage;
  final AiChatMessageModel lastAiMessage;
  final List? sources;

  const MessageSent({
    required this.sessions,
    required this.selectedSession,
    required this.messages,
    required this.lastUserMessage,
    required this.lastAiMessage,
    this.sources,
  });

  @override
  List<Object?> get props => [
    sessions,
    selectedSession,
    messages,
    lastUserMessage,
    lastAiMessage,
    sources,
  ];
}

class MessageSendError extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel selectedSession;
  final List<AiChatMessageModel> messages;
  final String message;

  const MessageSendError({
    required this.sessions,
    required this.selectedSession,
    required this.messages,
    required this.message,
  });

  @override
  List<Object> get props => [sessions, selectedSession, messages, message];
}

// Session deletion states
class SessionDeleting extends AiChatState {
  final List<AiChatSessionModel> sessions;

  const SessionDeleting({
    required this.sessions,
  });

  @override
  List<Object> get props => [sessions];
}

class SessionDeleted extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel? nextSession;

  const SessionDeleted({
    required this.sessions,
    this.nextSession,
  });

  @override
  List<Object?> get props => [sessions, nextSession];
}

class SessionDeleteError extends AiChatState {
  final String message;
  final List<AiChatSessionModel> sessions;

  const SessionDeleteError({
    required this.message,
    required this.sessions,
  });

  @override
  List<Object> get props => [message, sessions];
}

// Session updating state
class SessionUpdating extends AiChatState {
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel? selectedSession;
  final List<AiChatMessageModel> messages;

  const SessionUpdating({
    required this.sessions,
    this.selectedSession,
    required this.messages,
  });

  @override
  List<Object?> get props => [sessions, selectedSession, messages];
}

// Session update error
class SessionUpdateError extends AiChatState {
  final String message;
  final List<AiChatSessionModel> sessions;

  const SessionUpdateError({
    required this.message,
    required this.sessions,
  });

  @override
  List<Object> get props => [message, sessions];
}

// Feedback error
class FeedbackError extends AiChatState {
  final String message;
  final List<AiChatSessionModel> sessions;
  final AiChatSessionModel selectedSession;
  final List<AiChatMessageModel> messages;

  const FeedbackError({
    required this.message,
    required this.sessions,
    required this.selectedSession,
    required this.messages,
  });

  @override
  List<Object> get props => [message, sessions, selectedSession, messages];
}
