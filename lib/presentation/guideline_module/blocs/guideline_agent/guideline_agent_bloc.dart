import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';

import '../../data/api/guideline_api.dart' as api;
import '../../data/models/guideline_chat_model.dart';
import '../../data/models/guideline_source_model.dart';

part 'guideline_agent_event.dart';
part 'guideline_agent_state.dart';

/// Safe parser for the sources array returned by the API.
List<Map<String, dynamic>> _parseSources(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

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
    on<CancelGuidelineStream>(_onCancelStream);
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
  List<GuidelineSourceModel> get sources => _sources;

  Future<void> _onLoadData(
    LoadGuidelineData event,
    Emitter<GuidelineAgentState> emit,
  ) async {
    emit(GuidelineAgentLoading());
    try {
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

  /// Send message using the reliable non-streaming API endpoint —
  /// identical to what the website uses, so the formatted response
  /// (with "📚 Based on:" header and disclaimer) is always returned.
  Future<void> _onSendMessage(
    SendGuidelineMessage event,
    Emitter<GuidelineAgentState> emit,
  ) async {
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
      final responseData = await api.sendGuidelineMessage(
        query: event.message,
        sessionId: _currentSessionId,
        sources: _selectedSources,
      );

      // The non-streaming API returns the payload at the top level
      // ({"success": true, "response": "...", ...}). Some deployments nest it
      // under a 'data' key, so fall back to that for compatibility.
      final Map<String, dynamic> data = responseData['data'] is Map
          ? Map<String, dynamic>.from(responseData['data'] as Map)
          : responseData;

      final responseText = data['response']?.toString() ?? '';
      final agentSources = _parseSources(data['sources']);
      final suggestions = (data['suggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final sessionId = data['session_id'] as String?;

      if (sessionId != null && sessionId.isNotEmpty) {
        _currentSessionId = sessionId;
      }
      _suggestions = suggestions;

      // Refresh usage quota from response
      if (responseData['usage'] is Map) {
        _usage = GuidelineUsageInfo.fromJson(
          Map<String, dynamic>.from(responseData['usage'] as Map),
        );
      }

      final assistantMessage = GuidelineChatMessage(
        role: 'assistant',
        content: responseText,
        createdAt: DateTime.now(),
        sources: agentSources,
      );
      _messages = [..._messages, assistantMessage];

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
        agentSources: agentSources,
      ));
    } catch (e) {
      debugPrint('SendGuidelineMessage error: $e');
      final errorStr = e.toString();

      if (errorStr.contains('429') ||
          errorStr.contains('Too many requests') ||
          errorStr.contains('limit')) {
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

  /// Cancel is a no-op for non-streaming requests.
  void _onCancelStream(
    CancelGuidelineStream event,
    Emitter<GuidelineAgentState> emit,
  ) {
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
