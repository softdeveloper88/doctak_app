import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => [];
}

class CreateMeetingEvent extends MeetingEvent {
  final String? meetingTitle;

  const CreateMeetingEvent({this.meetingTitle});

  @override
  List<Object?> get props => [meetingTitle];
}

class JoinMeetingEvent extends MeetingEvent {
  final String meetingCode;

  const JoinMeetingEvent(this.meetingCode);

  @override
  List<Object> get props => [meetingCode];
}

class AskToJoinMeetingEvent extends MeetingEvent {
  final String meetingId;
  final String userId;

  const AskToJoinMeetingEvent(this.meetingId, this.userId);

  @override
  List<Object> get props => [meetingId, userId];
}

class LeaveMeetingEvent extends MeetingEvent {
  final String meetingId;

  const LeaveMeetingEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class EndMeetingEvent extends MeetingEvent {
  final String meetingId;

  const EndMeetingEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class GetMeetingDetailsEvent extends MeetingEvent {
  final String meetingId;

  const GetMeetingDetailsEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class ToggleMicrophoneEvent extends MeetingEvent {
  final bool enabled;

  const ToggleMicrophoneEvent(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ToggleCameraEvent extends MeetingEvent {
  final bool enabled;

  const ToggleCameraEvent(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ToggleScreenShareEvent extends MeetingEvent {
  final bool enabled;

  const ToggleScreenShareEvent(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ToggleHandRaiseEvent extends MeetingEvent {
  final bool raised;

  const ToggleHandRaiseEvent(this.raised);

  @override
  List<Object> get props => [raised];
}

class StartRecordingEvent extends MeetingEvent {
  final String meetingId;

  const StartRecordingEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class StopRecordingEvent extends MeetingEvent {
  final String meetingId;

  const StopRecordingEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class MakeAnnouncementEvent extends MeetingEvent {
  final String meetingId;
  final String message;

  const MakeAnnouncementEvent(this.meetingId, this.message);

  @override
  List<Object> get props => [meetingId, message];
}

class MuteAllParticipantsEvent extends MeetingEvent {
  final String meetingId;

  const MuteAllParticipantsEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class MeetingEndedEvent extends MeetingEvent {
  const MeetingEndedEvent();
}