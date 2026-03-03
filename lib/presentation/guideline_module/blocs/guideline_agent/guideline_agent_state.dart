part of 'guideline_agent_bloc.dart';

abstract class GuidelineAgentState extends Equatable {
  const GuidelineAgentState();

  @override
  List<Object?> get props => [];
}

class GuidelineAgentInitial extends GuidelineAgentState {}

class GuidelineAgentLoading extends GuidelineAgentState {}

class GuidelineAgentError extends GuidelineAgentState {
  final String message;
  const GuidelineAgentError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Main ready state — contains all data needed by the UI.
class GuidelineAgentReady extends GuidelineAgentState {
  final List<GuidelineSourceModel> sources;
  final List<String> selectedSources;
  final List<GuidelineSuggestedTopic> topics;
  final List<GuidelineChatSession> sessions;
  final GuidelineUsageInfo? usage;
  final List<GuidelineChatMessage> messages;
  final List<String> suggestions;

  const GuidelineAgentReady({
    required this.sources,
    required this.selectedSources,
    required this.topics,
    required this.sessions,
    this.usage,
    required this.messages,
    required this.suggestions,
  });

  @override
  List<Object?> get props =>
      [sources, selectedSources, topics, sessions, usage, messages, suggestions];
}

/// Sending a message — shows loading indicator.
class GuidelineMessageSending extends GuidelineAgentReady {
  const GuidelineMessageSending({
    required super.sources,
    required super.selectedSources,
    required super.topics,
    required super.sessions,
    super.usage,
    required super.messages,
    required super.suggestions,
  });
}

/// Message received from the agent — includes source citations.
class GuidelineMessageReceived extends GuidelineAgentReady {
  final List<Map<String, dynamic>> agentSources;

  const GuidelineMessageReceived({
    required super.sources,
    required super.selectedSources,
    required super.topics,
    required super.sessions,
    super.usage,
    required super.messages,
    required super.suggestions,
    this.agentSources = const [],
  });

  @override
  List<Object?> get props => [...super.props, agentSources];
}

/// Quota exceeded — needs upgrade.
class GuidelineQuotaExceeded extends GuidelineAgentReady {
  const GuidelineQuotaExceeded({
    required super.sources,
    required super.selectedSources,
    required super.topics,
    required super.sessions,
    super.usage,
    required super.messages,
    required super.suggestions,
  });
}

/// Error sending message.
class GuidelineMessageError extends GuidelineAgentReady {
  final String errorMessage;

  const GuidelineMessageError({
    required super.sources,
    required super.selectedSources,
    required super.topics,
    required super.sessions,
    super.usage,
    required super.messages,
    required super.suggestions,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [...super.props, errorMessage];
}
