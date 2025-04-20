import 'package:doctak_app/meeting_module/models/meeting_settings.dart';
import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMeetingSettingsEvent extends SettingsEvent {
  final String meetingId;

  const LoadMeetingSettingsEvent(this.meetingId);

  @override
  List<Object> get props => [meetingId];
}

class UpdateMeetingSettingsEvent extends SettingsEvent {
  final String meetingId;
  final Map<String, dynamic> settings;

  const UpdateMeetingSettingsEvent({
    required this.meetingId,
    required this.settings,
  });

  @override
  List<Object> get props => [meetingId, settings];
}

class SettingsUpdatedEvent extends SettingsEvent {
  final MeetingSettings settings;

  const SettingsUpdatedEvent(this.settings);

  @override
  List<Object> get props => [settings];
}

class ClearSettingsEvent extends SettingsEvent {}