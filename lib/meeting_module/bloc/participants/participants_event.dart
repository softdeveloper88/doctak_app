import 'package:equatable/equatable.dart';

import '../../models/participant.dart';

abstract class ParticipantsEvent extends Equatable {
  const ParticipantsEvent();

  @override
  List<Object?> get props => [];
}

class LoadParticipantsEvent extends ParticipantsEvent {
  final String meetingId;

  const LoadParticipantsEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class ParticipantJoinedEvent extends ParticipantsEvent {
  final Participant participant;

  const ParticipantJoinedEvent(this.participant);

  @override
  List<Object> get props => [participant];
}

class ParticipantLeftEvent extends ParticipantsEvent {
  final String participantId;

  const ParticipantLeftEvent(this.participantId);

  @override
  List<Object> get props => [participantId];
}

class ParticipantStatusChangedEvent extends ParticipantsEvent {
  final String participantId;
  final String action;
  final bool status;

  const ParticipantStatusChangedEvent(
      this.participantId,
      this.action,
      this.status,
      );

  @override
  List<Object> get props => [participantId, action, status];
}

class ParticipantSpeakingChangedEvent extends ParticipantsEvent {
  final String participantId;
  final bool isSpeaking;

  const ParticipantSpeakingChangedEvent(
      this.participantId,
      this.isSpeaking,
      );

  @override
  List<Object> get props => [participantId, isSpeaking];
}

class PinParticipantEvent extends ParticipantsEvent {
  final String? participantId;  // null to unpin

  const PinParticipantEvent(this.participantId);

  @override
  List<Object?> get props => [participantId];
}

class AllowJoinRequestEvent extends ParticipantsEvent {
  final String meetingId;
  final String userId;

  const AllowJoinRequestEvent(this.meetingId, this.userId);

  @override
  List<Object> get props => [meetingId, userId];
}

class RejectJoinRequestEvent extends ParticipantsEvent {
  final String meetingId;
  final String userId;

  const RejectJoinRequestEvent(this.meetingId, this.userId);

  @override
  List<Object> get props => [meetingId, userId];
}

class ClearParticipantsEvent extends ParticipantsEvent {}