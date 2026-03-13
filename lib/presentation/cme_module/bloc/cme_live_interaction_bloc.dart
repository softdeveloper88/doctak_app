import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_chat_poll_model.dart';
import 'cme_live_interaction_event.dart';
import 'cme_live_interaction_state.dart';

class CmeLiveInteractionBloc
    extends Bloc<CmeLiveInteractionEvent, CmeLiveInteractionState> {
  List<CmeChatMessage> chatMessages = [];
  List<CmePollData> polls = [];
  List<Map<String, dynamic>> participants = [];
  int totalParticipants = 0;
  Timer? _chatRefreshTimer;
  Timer? _participationTimer;
  int _sessionSeconds = 0;

  CmeLiveInteractionBloc() : super(CmeLiveInteractionInitialState()) {
    on<CmeLoadChatMessagesEvent>(_onLoadChat);
    on<CmeSendChatMessageEvent>(_onSendMessage);
    on<CmeLoadPollsEvent>(_onLoadPolls);
    on<CmeVotePollEvent>(_onVotePoll);
    on<CmeRefreshChatEvent>(_onRefreshChat);
    on<CmeCreatePollEvent>(_onCreatePoll);
    on<CmeLoadParticipantsEvent>(_onLoadParticipants);
    on<CmeJoinEventEvent>(_onJoinEvent);
    on<CmeLeaveEventEvent>(_onLeaveEvent);
    on<CmeTrackParticipationEvent>(_onTrackParticipation);
  }

  int get sessionSeconds => _sessionSeconds;

  void startSessionTimer() {
    _participationTimer?.cancel();
    _sessionSeconds = 0;
    _participationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionSeconds++;
    });
  }

  void stopSessionTimer() {
    _participationTimer?.cancel();
  }

  Future<void> _onLoadChat(
      CmeLoadChatMessagesEvent event, Emitter<CmeLiveInteractionState> emit) async {
    emit(CmeChatLoadingState());
    try {
      final data = await CmeApiService.getChatMessages(event.eventId);
      chatMessages =
          data.map((m) => CmeChatMessage.fromJson(m)).toList();
      emit(CmeChatLoadedState());

      // Start polling for new messages every 5 seconds
      _startChatPolling(event.eventId);
    } catch (e) {
      emit(CmeLiveInteractionErrorState(e.toString()));
    }
  }

  Future<void> _onSendMessage(
      CmeSendChatMessageEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      final data =
          await CmeApiService.sendChatMessage(event.eventId, event.message);
      if (data['message'] != null && data['message'] is Map) {
        chatMessages.add(CmeChatMessage.fromJson(data['message']));
      }
      emit(CmeChatMessageSentState());
    } catch (e) {
      emit(CmeLiveInteractionErrorState(e.toString()));
    }
  }

  Future<void> _onLoadPolls(
      CmeLoadPollsEvent event, Emitter<CmeLiveInteractionState> emit) async {
    emit(CmePollsLoadingState());
    try {
      final data = await CmeApiService.getPolls(event.eventId);
      polls = data.map((p) => CmePollData.fromJson(p)).toList();
      emit(CmePollsLoadedState());
    } catch (e) {
      emit(CmeLiveInteractionErrorState(e.toString()));
    }
  }

  Future<void> _onVotePoll(
      CmeVotePollEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      final data = await CmeApiService.votePoll(
        event.eventId,
        event.pollId,
        {'answer': event.optionId},
      );
      // Refresh polls after voting
      add(CmeLoadPollsEvent(eventId: event.eventId));
      emit(CmePollVotedState(
        message: data['message']?.toString() ?? 'Vote recorded',
      ));
    } catch (e) {
      emit(CmeLiveInteractionErrorState(e.toString()));
    }
  }

  Future<void> _onCreatePoll(
      CmeCreatePollEvent event, Emitter<CmeLiveInteractionState> emit) async {
    emit(CmePollCreatingState());
    try {
      await CmeApiService.createPoll(
        event.eventId,
        event.question,
        event.options,
      );
      // Refresh polls list
      add(CmeLoadPollsEvent(eventId: event.eventId));
      emit(CmePollCreatedState());
    } catch (e) {
      emit(CmeLiveInteractionErrorState(e.toString()));
    }
  }

  Future<void> _onLoadParticipants(
      CmeLoadParticipantsEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      final data = await CmeApiService.getParticipants(event.eventId);
      participants = List<Map<String, dynamic>>.from(data['participants'] ?? []);
      totalParticipants = data['total_participants'] ?? 0;
      emit(CmeParticipantsLoadedState());
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _onJoinEvent(
      CmeJoinEventEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      await CmeApiService.joinEvent(event.eventId);
      startSessionTimer();
      emit(CmeEventJoinedState());
    } catch (_) {}
  }

  Future<void> _onLeaveEvent(
      CmeLeaveEventEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      stopSessionTimer();
      if (_sessionSeconds > 0) {
        await CmeApiService.trackParticipation(
          event.eventId,
          duration: _sessionSeconds,
        );
      }
      await CmeApiService.leaveEvent(event.eventId);
      emit(CmeEventLeftState());
    } catch (_) {}
  }

  Future<void> _onTrackParticipation(
      CmeTrackParticipationEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      await CmeApiService.trackParticipation(
        event.eventId,
        duration: event.duration,
      );
    } catch (_) {}
  }

  Future<void> _onRefreshChat(
      CmeRefreshChatEvent event, Emitter<CmeLiveInteractionState> emit) async {
    try {
      final data = await CmeApiService.getChatMessages(event.eventId);
      chatMessages =
          data.map((m) => CmeChatMessage.fromJson(m)).toList();
      emit(CmeChatLoadedState());
    } catch (_) {
      // Silent fail for refresh
    }
  }

  void _startChatPolling(String eventId) {
    _chatRefreshTimer?.cancel();
    _chatRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(CmeRefreshChatEvent(eventId: eventId));
    });
  }

  void stopChatPolling() {
    _chatRefreshTimer?.cancel();
  }

  @override
  Future<void> close() {
    _chatRefreshTimer?.cancel();
    _participationTimer?.cancel();
    return super.close();
  }
}
