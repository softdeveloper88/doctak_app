import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ApiService _apiService;

  SettingsBloc({required ApiService apiService})
      : _apiService = apiService,
        super(SettingsInitial()) {
    on<LoadMeetingSettingsEvent>(_onLoadMeetingSettings);
    on<UpdateMeetingSettingsEvent>(_onUpdateMeetingSettings);
    on<SettingsUpdatedEvent>(_onSettingsUpdated);
    on<ClearSettingsEvent>(_onClearSettings);
  }

  Future<void> _onLoadMeetingSettings(
      LoadMeetingSettingsEvent event,
      Emitter<SettingsState> emit,
      ) async {
    emit(SettingsLoading());
    try {
      final settings = await _apiService.getMeetingSettings(event.meetingId);
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load meeting settings: $e'));
    }
  }

  Future<void> _onUpdateMeetingSettings(
      UpdateMeetingSettingsEvent event,
      Emitter<SettingsState> emit,
      ) async {
    emit(SettingsUpdating());
    try {
      await _apiService.updateMeetingSettings(event.meetingId, event.settings);
      final updatedSettings = await _apiService.getMeetingSettings(event.meetingId);
      emit(SettingsUpdateSuccess(updatedSettings));
    } catch (e) {
      emit(SettingsError('Failed to update meeting settings: $e'));
    }
  }

  void _onSettingsUpdated(
      SettingsUpdatedEvent event,
      Emitter<SettingsState> emit,
      ) {
    emit(SettingsLoaded(event.settings));
  }

  void _onClearSettings(
      ClearSettingsEvent event,
      Emitter<SettingsState> emit,
      ) {
    emit(SettingsInitial());
  }
}