import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';

import '../../data/api/guideline_api.dart' as api;
import '../../data/models/guideline_chat_model.dart';
import '../../data/models/guideline_source_model.dart';

part 'guideline_agent_event.dart';
part 'guideline_agent_state.dart';

class GuidelineAgentBloc
    extends Bloc<GuidelineAgentEvent, GuidelineAgentState> {
  GuidelineAgentBloc() : super(GuidelineAgentInitial()) {
    on<LoadGuidelineData>(_onLoadData);
    on<SelectSources>(_onSelectSources);
    on<SendGuidelineMessage>(_onSendMessage);
    on<LoadSessionMessages>(_onLoadSessionMessages);
    on<DeleteConversation>(_onDeleteConversation);
    on<ClearCurrentChat>(_onClearCurrentChat);
    on<SubmitMessageFeedback>(_onSubmitFeedback);
    on<StartNewChat>(_onStartNewChat);
  }

  List<GuidelineSourceModel> _sources = [];
  List<GuidelineChatSession> _sessions = [];
  List<GuidelineChatMessage> _messages = [];
  List<GuidelineSuggestedTopic> _topics = [];
  List<String> _selectedSources = ['WHO'];
  List<String> _suggestions = [];
  GuidelineUsageInfo? _usage;
  String _currentSessionId = '';

  String get currentSessionId => _currentSessionId;
  List<String> get selectedSources => _selectedSources;

  Future<void> _onLoadData(
    LoadGuidelineData event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    emit(GuidelineAgentLoading());
    try {
      // Load sources, topics, sessions, and usage in parallel
      final results = await Future.wait([
        api.getGuidelineSources(),
        api.getSuggestedTopics(),
        api.getGuidelineSessions(),
        api.getGuidelineUsage(),
      ]);

      _sources = results[0] as List<GuidelineSourceModel>;
      _topics = results[1] as List<GuidelineSuggestedTopic>;
      _sessions = results[2] as List<GuidelineChatSession>;
      _usage = results[3] as GuidelineUsageInfo?;

      // Generate a new session ID
      _currentSessionId =
          '${AppData.logInUserId}-${DateTime.now().millisecondsSinceEpoch}';

      emit(GuidelineAgentReady(
        sources: _sources,
        selectedSources: _selectedSources,
        topics: _topics,
        sessions: _sessions,
        usage: _usage,
        messages: const [],
        suggestions: const [],
      ));
    } catch (e) {
      debugPrint('LoadGuidelineData error: $e');
      emit(GuidelineAgentError(message: 'Failed to load guideline data: $e'));
    }
  }

  void _onSelectSources(
    SelectSources event,
    Emitter<GuidelineAgentState> emit,
  ) {
    _selectedSources = event.sources;
    emit(GuidelineAgentReady(
      sources: _sources,
      selectedSources: _selectedSources,
      topics: _topics,
      sessions: _sessions,
      usage: _usage,
      messages: _messages,
      suggestions: _suggestions,
    ));
  }

  Future<void> _onSendMessage(
    SendGuidelineMessage event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    // Add user message to local list immediately
    final userMessage = GuidelineChatMessage(
      role: 'user',
      content: event.message,
      createdAt: DateTime.now(),
    );
    _messages = [..._messages, userMessage];

    emit(GuidelineMessageSending(
      sources: _sources,
      selectedSources: _selectedSources,
      topics: _topics,
      sessions: _sessions,
      usage: _usage,
      messages: _messages,
      suggestions: _suggestions,
    ));

    try {
      final result = await api.sendGuidelineMessage(
        query: event.message,
        sessionId: _currentSessionId,
        sources: _selectedSources,
      );

      if (result['success'] == true) {
        final data = result['data'] ?? {};
        final agentResponse = GuidelineAgentResponse.fromJson(data);

        // Add assistant message
        final assistantMessage = GuidelineChatMessage(
          role: 'assistant',
          content: agentResponse.response,
          createdAt: DateTime.now(),
        );
        _messages = [..._messages, assistantMessage];
        _suggestions = agentResponse.suggestions;

        // Update session ID from response
        if (agentResponse.sessionId.isNotEmpty) {
          _currentSessionId = agentResponse.sessionId;
        }

        // Update usage from response
        if (result['usage'] != null) {
          _usage = GuidelineUsageInfo.fromJson(result['usage']);
        }

        // Refresh sessions list
        try {
          _sessions = await api.getGuidelineSessions();
        } catch (_) {}

        emit(GuidelineMessageReceived(
          sources: _sources,
          selectedSources: _selectedSources,
          topics: _topics,
          sessions: _sessions,
          usage: _usage,
          messages: _messages,
          suggestions: _suggestions,
          agentSources: agentResponse.sources,
        ));
      } else if (result['limit_reached'] == true) {
        if (result['usage'] != null) {
          _usage = GuidelineUsageInfo.fromJson(result['usage']);
        }
        emit(GuidelineQuotaExceeded(
          sources: _sources,
          selectedSources: _selectedSources,
          topics: _topics,
          sessions: _sessions,
          usage: _usage,
          messages: _messages,
          suggestions: _suggestions,
        ));
      } else {
        emit(GuidelineMessageError(
          sources: _sources,
          selectedSources: _selectedSources,
          topics: _topics,
          sessions: _sessions,
          usage: _usage,
          messages: _messages,
          suggestions: _suggestions,
          errorMessage: result['message'] ?? 'Unknown error',
        ));
      }
    } catch (e) {
      debugPrint('SendGuidelineMessage error: $e');

      // Check for 429 quota error
      final isQuotaError = e.toString().contains('429');
      if (isQuotaError) {
        emit(GuidelineQuotaExceeded(
          sources: _sources,
          selectedSources: _selectedSources,
          topics: _topics,
          sessions: _sessions,
          usage: _usage,
          messages: _messages,
          suggestions: _suggestions,
        ));
      } else {
        emit(GuidelineMessageError(
          sources: _sources,
          selectedSources: _selectedSources,
          topics: _topics,
          sessions: _sessions,
          usage: _usage,
          messages: _messages,
          suggestions: _suggestions,
          errorMessage: 'Failed to get response. Please try again.',
        ));
      }
    }
  }

  Future<void> _onLoadSessionMessages(
    LoadSessionMessages event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    emit(GuidelineAgentLoading());
    try {
      _currentSessionId = event.sessionId;
      _messages = await api.getSessionMessages(event.sessionId);

      emit(GuidelineAgentReady(
        sources: _sources,
        selectedSources: _selectedSources,
        topics: _topics,
        sessions: _sessions,
        usage: _usage,
        messages: _messages,
        suggestions: _suggestions,
      ));
    } catch (e) {
      emit(GuidelineAgentError(message: 'Failed to load conversation: $e'));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    try {
      await api.deleteGuidelineSession(event.sessionId);
      _sessions =
          _sessions.where((s) => s.sessionId != event.sessionId).toList();

      // If deleting current session, reset chat
      if (event.sessionId == _currentSessionId) {
        _messages = [];
        _suggestions = [];
        _currentSessionId =
            '${AppData.logInUserId}-${DateTime.now().millisecondsSinceEpoch}';
      }

      emit(GuidelineAgentReady(
        sources: _sources,
        selectedSources: _selectedSources,
        topics: _topics,
        sessions: _sessions,
        usage: _usage,
        messages: _messages,
        suggestions: _suggestions,
      ));
    } catch (e) {
      debugPrint('DeleteConversation error: $e');
    }
  }

  Future<void> _onClearCurrentChat(
    ClearCurrentChat event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    try {
      await api.clearGuidelineSession(_currentSessionId);
    } catch (_) {}

    _messages = [];
    _suggestions = [];
    _currentSessionId =
        '${AppData.logInUserId}-${DateTime.now().millisecondsSinceEpoch}';

    emit(GuidelineAgentReady(
      sources: _sources,
      selectedSources: _selectedSources,
      topics: _topics,
      sessions: _sessions,
      usage: _usage,
      messages: const [],
      suggestions: const [],
    ));
  }

  Future<void> _onSubmitFeedback(
    SubmitMessageFeedback event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    try {
      await api.submitGuidelineFeedback(
        messageId: event.messageId,
        rating: event.rating,
      );
    } catch (e) {
      debugPrint('SubmitMessageFeedback error: $e');
    }
  }

  void _onStartNewChat(
    StartNewChat event,
    Emitter<GuidelineAgentState> emit,
  ) {
    _messages = [];
    _suggestions = [];
    _currentSessionId =
        '${AppData.logInUserId}-${DateTime.now().millisecondsSinceEpoch}';

    emit(GuidelineAgentReady(
      sources: _sources,
      selectedSources: _selectedSources,
      topics: _topics,
      sessions: _sessions,
      usage: _usage,
      messages: const [],
      suggestions: const [],
    ));
  }
}
