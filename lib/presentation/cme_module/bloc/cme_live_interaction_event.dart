import 'package:equatable/equatable.dart';

abstract class CmeLiveInteractionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadChatMessagesEvent extends CmeLiveInteractionEvent {
  final String eventId;
  CmeLoadChatMessagesEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeSendChatMessageEvent extends CmeLiveInteractionEvent {
  final String eventId;
  final String message;

  CmeSendChatMessageEvent({required this.eventId, required this.message});

  @override
  List<Object?> get props => [eventId, message];
}

class CmeLoadPollsEvent extends CmeLiveInteractionEvent {
  final String eventId;
  CmeLoadPollsEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeVotePollEvent extends CmeLiveInteractionEvent {
  final String eventId;
  final String pollId;
  final String optionId;

  CmeVotePollEvent({
    required this.eventId,
    required this.pollId,
    required this.optionId,
  });

  @override
  List<Object?> get props => [eventId, pollId, optionId];
}

class CmeRefreshChatEvent extends CmeLiveInteractionEvent {
  final String eventId;
  CmeRefreshChatEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeCreatePollEvent extends CmeLiveInteractionEvent {
  final String eventId;
  final String question;
  final List<String> options;

  CmeCreatePollEvent({
    required this.eventId,
    required this.question,
    required this.options,
  });

  @override
  List<Object?> get props => [eventId, question, options];
}

class CmeLoadParticipantsEvent extends CmeLiveInteractionEvent {
  final String eventId;
  CmeLoadParticipantsEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeJoinEventEvent extends CmeLiveInteractionEvent {
  final String eventId;
  CmeJoinEventEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeLeaveEventEvent extends CmeLiveInteractionEvent {
  final String eventId;
  CmeLeaveEventEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeTrackParticipationEvent extends CmeLiveInteractionEvent {
  final String eventId;
  final int duration;

  CmeTrackParticipationEvent({required this.eventId, required this.duration});

  @override
  List<Object?> get props => [eventId, duration];
}
