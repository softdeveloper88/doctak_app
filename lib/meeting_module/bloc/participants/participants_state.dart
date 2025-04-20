import 'package:equatable/equatable.dart';

import '../../models/participant.dart';

abstract class ParticipantsState extends Equatable {
  const ParticipantsState();

  @override
  List<Object?> get props => [];
}

class ParticipantsInitial extends ParticipantsState {}

class ParticipantsLoading extends ParticipantsState {}

class ParticipantsLoaded extends ParticipantsState {
  final List<Participant> participants;
  final String? pinnedParticipantId;
  final String? activeSpeakerId;

  const ParticipantsLoaded({
    required this.participants,
    this.pinnedParticipantId,
    this.activeSpeakerId,
  });

  ParticipantsLoaded copyWith({
    List<Participant>? participants,
    String? pinnedParticipantId,
    String? activeSpeakerId,
  }) {
    return ParticipantsLoaded(
      participants: participants ?? this.participants,
      pinnedParticipantId: pinnedParticipantId ?? this.pinnedParticipantId,
      activeSpeakerId: activeSpeakerId ?? this.activeSpeakerId,
    );
  }

  @override
  List<Object?> get props => [participants, pinnedParticipantId, activeSpeakerId];
}

class ParticipantsError extends ParticipantsState {
  final String message;

  const ParticipantsError(this.message);

  @override
  List<Object> get props => [message];
}

class JoinRequestAllowed extends ParticipantsState {
  final String userId;

  const JoinRequestAllowed(this.userId);

  @override
  List<Object> get props => [userId];
}

class JoinRequestRejected extends ParticipantsState {
  final String userId;

  const JoinRequestRejected(this.userId);

  @override
  List<Object> get props => [userId];
}