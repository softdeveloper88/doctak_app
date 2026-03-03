part of 'guideline_agent_bloc.dart';

abstract class GuidelineAgentEvent extends Equatable {
  const GuidelineAgentEvent();

  @override
  List<Object?> get props => [];
}

/// Load sources, topics, sessions, and usage info.
class LoadGuidelineData extends GuidelineAgentEvent {}

/// Update selected guideline sources.
class SelectSources extends GuidelineAgentEvent {
  final List<String> sources;
  const SelectSources({required this.sources});

  @override
  List<Object?> get props => [sources];
}

/// Send a message to the Guideline Agent.
class SendGuidelineMessage extends GuidelineAgentEvent {
  final String message;
  const SendGuidelineMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Load messages from a previous conversation session.
class LoadSessionMessages extends GuidelineAgentEvent {
  final String sessionId;
  const LoadSessionMessages({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Delete a conversation session.
class DeleteConversation extends GuidelineAgentEvent {
  final String sessionId;
  const DeleteConversation({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Clear the current chat and start fresh.
class ClearCurrentChat extends GuidelineAgentEvent {}

/// Submit feedback for a specific message.
class SubmitMessageFeedback extends GuidelineAgentEvent {
  final int messageId;
  final String rating; // 'positive' | 'negative'
  const SubmitMessageFeedback({
    required this.messageId,
    required this.rating,
  });

  @override
  List<Object?> get props => [messageId, rating];
}

/// Start a brand new chat (reset current).
class StartNewChat extends GuidelineAgentEvent {}
