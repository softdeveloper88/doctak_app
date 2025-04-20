import 'package:doctak_app/meeting_module/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/participant.dart';
import 'participants_event.dart';
import 'participants_state.dart';

class ParticipantsBloc extends Bloc<ParticipantsEvent, ParticipantsState> {
  final ApiService _apiService;

  ParticipantsBloc({required ApiService apiService})
      : _apiService = apiService,
        super(ParticipantsInitial()) {
    on<LoadParticipantsEvent>(_onLoadParticipants);
    on<ParticipantJoinedEvent>(_onParticipantJoined);
    on<ParticipantLeftEvent>(_onParticipantLeft);
    on<ParticipantStatusChangedEvent>(_onParticipantStatusChanged);
    on<ParticipantSpeakingChangedEvent>(_onParticipantSpeakingChanged);
    on<PinParticipantEvent>(_onPinParticipant);
    on<AllowJoinRequestEvent>(_onAllowJoinRequest);
    on<RejectJoinRequestEvent>(_onRejectJoinRequest);
    on<ClearParticipantsEvent>(_onClearParticipants);
  }

  Future<void> _onLoadParticipants(
      LoadParticipantsEvent event,
      Emitter<ParticipantsState> emit,
      ) async {
    emit(ParticipantsLoading());
    try {
      final participants = await _apiService.getMeetingParticipants(event.meetingId);
      emit(ParticipantsLoaded(participants: participants));
    } catch (e) {
      emit(ParticipantsError('Failed to load participants: $e'));
    }
  }

  void _onParticipantJoined(
      ParticipantJoinedEvent event,
      Emitter<ParticipantsState> emit,
      ) {
    final currentState = state;
    if (currentState is ParticipantsLoaded) {
      // Check if participant already exists
      final existingIndex = currentState.participants
          .indexWhere((p) => p.userId == event.participant.userId);

      final updatedParticipants = List<Participant>.from(currentState.participants);

      if (existingIndex != -1) {
        // Update existing participant
        updatedParticipants[existingIndex] = event.participant;
      } else {
        // Add new participant
        updatedParticipants.add(event.participant);
      }

      emit(currentState.copyWith(participants: updatedParticipants));
    }
  }

  void _onParticipantLeft(
      ParticipantLeftEvent event,
      Emitter<ParticipantsState> emit,
      ) {
    final currentState = state;
    if (currentState is ParticipantsLoaded) {
      // Remove participant who left
      final updatedParticipants = currentState.participants
          .where((p) => p.userId != event.participantId)
          .toList();

      // If pinned participant left, unpin
      final pinnedParticipantId = currentState.pinnedParticipantId == event.participantId
          ? null
          : currentState.pinnedParticipantId;

      // If active speaker left, clear active speaker
      final activeSpeakerId = currentState.activeSpeakerId == event.participantId
          ? null
          : currentState.activeSpeakerId;

      emit(currentState.copyWith(
        participants: updatedParticipants,
        pinnedParticipantId: pinnedParticipantId,
        activeSpeakerId: activeSpeakerId,
      ));
    }
  }

  void _onParticipantStatusChanged(
      ParticipantStatusChangedEvent event,
      Emitter<ParticipantsState> emit,
      ) {
    final currentState = state;
    if (currentState is ParticipantsLoaded) {
      final updatedParticipants = currentState.participants.map((participant) {
        if (participant.userId == event.participantId) {
          // Create a new participant with updated status
          return _updateParticipantStatus(participant, event.action, event.status);
        }
        return participant;
      }).toList();

      emit(currentState.copyWith(participants: updatedParticipants));
    }
  }

  Participant _updateParticipantStatus(Participant participant, String action, bool status) {
    switch (action) {
      case 'mic':
        return Participant(
          id: participant.id,
          userId: participant.userId,
          meetingId: participant.meetingId,
          firstName: participant.firstName,
          lastName: participant.lastName,
          profilePic: participant.profilePic,
          isAllowed: participant.isAllowed,
          isMicOn: status,
          isVideoOn: participant.isVideoOn,
          isMeetingLeaved: participant.isMeetingLeaved,
          isScreenShared: participant.isScreenShared,
          isHandUp: participant.isHandUp,
          isHost: participant.isHost,
          isSpeaking: participant.isSpeaking,
        );
      case 'cam':
        return Participant(
          id: participant.id,
          userId: participant.userId,
          meetingId: participant.meetingId,
          firstName: participant.firstName,
          lastName: participant.lastName,
          profilePic: participant.profilePic,
          isAllowed: participant.isAllowed,
          isMicOn: participant.isMicOn,
          isVideoOn: status,
          isMeetingLeaved: participant.isMeetingLeaved,
          isScreenShared: participant.isScreenShared,
          isHandUp: participant.isHandUp,
          isHost: participant.isHost,
          isSpeaking: participant.isSpeaking,
        );
      case 'screen':
        return Participant(
          id: participant.id,
          userId: participant.userId,
          meetingId: participant.meetingId,
          firstName: participant.firstName,
          lastName: participant.lastName,
          profilePic: participant.profilePic,
          isAllowed: participant.isAllowed,
          isMicOn: participant.isMicOn,
          isVideoOn: participant.isVideoOn,
          isMeetingLeaved: participant.isMeetingLeaved,
          isScreenShared: status,
          isHandUp: participant.isHandUp,
          isHost: participant.isHost,
          isSpeaking: participant.isSpeaking,
        );
      case 'hands':
        return Participant(
          id: participant.id,
          userId: participant.userId,
          meetingId: participant.meetingId,
          firstName: participant.firstName,
          lastName: participant.lastName,
          profilePic: participant.profilePic,
          isAllowed: participant.isAllowed,
          isMicOn: participant.isMicOn,
          isVideoOn: participant.isVideoOn,
          isMeetingLeaved: participant.isMeetingLeaved,
          isScreenShared: participant.isScreenShared,
          isHandUp: status,
          isHost: participant.isHost,
          isSpeaking: participant.isSpeaking,
        );
      default:
        return participant;
    }
  }

  void _onParticipantSpeakingChanged(
      ParticipantSpeakingChangedEvent event,
      Emitter<ParticipantsState> emit,
      ) {
    final currentState = state;
    if (currentState is ParticipantsLoaded) {
      final updatedParticipants = currentState.participants.map((participant) {
        if (participant.userId == event.participantId) {
          return Participant(
            id: participant.id,
            userId: participant.userId,
            meetingId: participant.meetingId,
            firstName: participant.firstName,
            lastName: participant.lastName,
            profilePic: participant.profilePic,
            isAllowed: participant.isAllowed,
            isMicOn: participant.isMicOn,
            isVideoOn: participant.isVideoOn,
            isMeetingLeaved: participant.isMeetingLeaved,
            isScreenShared: participant.isScreenShared,
            isHandUp: participant.isHandUp,
            isHost: participant.isHost,
            isSpeaking: event.isSpeaking,
          );
        }
        return participant;
      }).toList();

      // Update active speaker if speaking
      String? activeSpeakerId = currentState.activeSpeakerId;
      if (event.isSpeaking) {
        activeSpeakerId = event.participantId;
      } else if (activeSpeakerId == event.participantId) {
        // Clear active speaker if this participant was the active speaker
        activeSpeakerId = null;
      }

      emit(currentState.copyWith(
        participants: updatedParticipants,
        activeSpeakerId: activeSpeakerId,
      ));
    }
  }

  void _onPinParticipant(
      PinParticipantEvent event,
      Emitter<ParticipantsState> emit,
      ) {
    final currentState = state;
    if (currentState is ParticipantsLoaded) {
      emit(currentState.copyWith(pinnedParticipantId: event.participantId));
    }
  }

  Future<void> _onAllowJoinRequest(
      AllowJoinRequestEvent event,
      Emitter<ParticipantsState> emit,
      ) async {
    try {
      await _apiService.allowJoinRequest(event.meetingId, event.userId);
      emit(JoinRequestAllowed(event.userId));

      // Reload participants to get the updated list
      add(LoadParticipantsEvent(event.meetingId));
    } catch (e) {
      emit(ParticipantsError('Failed to allow join request: $e'));
    }
  }

  Future<void> _onRejectJoinRequest(
      RejectJoinRequestEvent event,
      Emitter<ParticipantsState> emit,
      ) async {
    try {
      await _apiService.rejectJoinRequest(event.meetingId, event.userId);
      emit(JoinRequestRejected(event.userId));
    } catch (e) {
      emit(ParticipantsError('Failed to reject join request: $e'));
    }
  }

  void _onClearParticipants(
      ClearParticipantsEvent event,
      Emitter<ParticipantsState> emit,
      ) {
    emit(ParticipantsInitial());
  }
}