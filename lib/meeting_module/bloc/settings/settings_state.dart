import 'package:doctak_app/meeting_module/models/meeting_settings.dart';
import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final MeetingSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object> get props => [settings];
}

class SettingsUpdating extends SettingsState {}

class SettingsUpdateSuccess extends SettingsState {
  final MeetingSettings settings;

  const SettingsUpdateSuccess(this.settings);

  @override
  List<Object> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}