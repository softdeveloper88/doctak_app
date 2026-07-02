import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cme_event_detail_event.dart';
import 'cme_event_detail_state.dart';

class CmeEventDetailBloc
    extends Bloc<CmeEventDetailEvent, CmeEventDetailState> {
  CmeEventData? eventData;

  CmeEventDetailBloc() : super(CmeEventDetailInitialState()) {
    on<CmeLoadEventDetailEvent>(_onLoadDetail);
    on<CmeRegisterEvent>(_onRegister);
    on<CmeUnregisterEvent>(_onUnregister);
    on<CmeJoinEventEvent>(_onJoinEvent);
    on<CmeJoinWaitlistEvent>(_onJoinWaitlist);
  }

  Future<CmeEventData> _loadEvent(String eventId) async {
    try {
      return await CmeNodeApiService.getEventDetail(eventId);
    } catch (_) {
      return CmeApiService.getEventDetail(eventId);
    }
  }

  Future<void> _onLoadDetail(
      CmeLoadEventDetailEvent event, Emitter<CmeEventDetailState> emit) async {
    if (!event.silent || eventData == null) {
      emit(CmeEventDetailLoadingState());
    }
    try {
      eventData = await _loadEvent(event.eventId);
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      if (eventData != null && event.silent) {
        emit(CmeEventDetailLoadedState());
      } else {
        emit(CmeEventDetailErrorState('$e'));
      }
    }
  }

  Future<void> _onRegister(
      CmeRegisterEvent event, Emitter<CmeEventDetailState> emit) async {
    try {
      try {
        await CmeNodeApiService.registerEvent(event.eventId);
      } catch (_) {
        await CmeApiService.registerForEvent(event.eventId);
      }
      eventData = await _loadEvent(event.eventId);
      emit(CmeRegistrationSuccessState('Successfully registered'));
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      emit(CmeRegistrationErrorState('$e'));
      emit(CmeEventDetailLoadedState());
    }
  }

  Future<void> _onUnregister(
      CmeUnregisterEvent event, Emitter<CmeEventDetailState> emit) async {
    try {
      try {
        await CmeNodeApiService.cancelRegistration(event.eventId);
      } catch (_) {
        await CmeApiService.unregisterFromEvent(event.eventId);
      }
      eventData = await _loadEvent(event.eventId);
      emit(CmeRegistrationSuccessState('Successfully unregistered'));
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      emit(CmeRegistrationErrorState('$e'));
      emit(CmeEventDetailLoadedState());
    }
  }

  Future<void> _onJoinEvent(
      CmeJoinEventEvent event, Emitter<CmeEventDetailState> emit) async {
    try {
      try {
        await CmeNodeApiService.joinLiveEvent(event.eventId);
      } catch (_) {
        await CmeApiService.joinEvent(event.eventId);
      }
      eventData = await _loadEvent(event.eventId);
      emit(CmeJoinedEventState());
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      emit(CmeRegistrationErrorState('$e'));
      emit(CmeEventDetailLoadedState());
    }
  }

  Future<void> _onJoinWaitlist(
      CmeJoinWaitlistEvent event, Emitter<CmeEventDetailState> emit) async {
    try {
      final result = await CmeApiService.joinWaitlist(event.eventId);
      emit(CmeWaitlistJoinedState(
          result['message'] ?? 'Added to waitlist'));
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      emit(CmeRegistrationErrorState('$e'));
      emit(CmeEventDetailLoadedState());
    }
  }
}
