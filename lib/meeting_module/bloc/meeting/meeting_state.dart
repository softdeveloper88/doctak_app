import 'package:equatable/equatable.dart';

import '../../models/meeting.dart';

abstract class MeetingState extends Equatable {
  const MeetingState();

  @override
  List<Object?> get props => [];
}

class MeetingInitial extends MeetingState {}

class MeetingLoading extends MeetingState {}

class MeetingCreated extends MeetingState {
  final Meeting meeting;

  const MeetingCreated(this.meeting);

  @override
  List<Object> get props => [meeting];
}

class MeetingJoined extends MeetingState {
  final Meeting meeting;

  const MeetingJoined(this.meeting);

  @override
  List<Object> get props => [meeting];
}

class MeetingJoinRequested extends MeetingState {}

class MeetingLeft extends MeetingState {}

class MeetingEnded extends MeetingState {}

class MeetingError extends MeetingState {
  final String message;

  const MeetingError(this.message);

  @override
  List<Object> get props => [message];
}

class MeetingDetailsLoaded extends MeetingState {
  final Meeting meeting;

  const MeetingDetailsLoaded(this.meeting);

  @override
  List<Object> get props => [meeting];
}

class MicrophoneToggled extends MeetingState {
  final bool enabled;

  const MicrophoneToggled(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class CameraToggled extends MeetingState {
  final bool enabled;

  const CameraToggled(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ScreenShareToggled extends MeetingState {
  final bool enabled;

  const ScreenShareToggled(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class HandRaiseToggled extends MeetingState {
  final bool raised;

  const HandRaiseToggled(this.raised);

  @override
  List<Object> get props => [raised];
}

class RecordingStarted extends MeetingState {}

class RecordingStopped extends MeetingState {}

class AnnouncementSent extends MeetingState {}

class AllParticipantsMuted extends MeetingState {}