import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
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

  Future<void> _onLoadDetail(
      CmeLoadEventDetailEvent event, Emitter<CmeEventDetailState> emit) async {
    emit(CmeEventDetailLoadingState());
    try {
      eventData = await CmeApiService.getEventDetail(event.eventId);
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      emit(CmeEventDetailErrorState('$e'));
    }
  }

  Future<void> _onRegister(
      CmeRegisterEvent event, Emitter<CmeEventDetailState> emit) async {
    try {
      final result = await CmeApiService.registerForEvent(event.eventId);
      eventData?.isRegistered = true;
      eventData?.registrationStatus = 'registered';
      if (eventData?.currentParticipants != null) {
        eventData!.currentParticipants = eventData!.currentParticipants! + 1;
      }
      emit(CmeRegistrationSuccessState(
          result['message'] ?? 'Successfully registered'));
      emit(CmeEventDetailLoadedState());
    } catch (e) {
      emit(CmeRegistrationErrorState('$e'));
      emit(CmeEventDetailLoadedState());
    }
  }

  Future<void> _onUnregister(
      CmeUnregisterEvent event, Emitter<CmeEventDetailState> emit) async {
    try {
      await CmeApiService.unregisterFromEvent(event.eventId);
      eventData?.isRegistered = false;
      eventData?.registrationStatus = null;
      if (eventData?.currentParticipants != null &&
          eventData!.currentParticipants! > 0) {
        eventData!.currentParticipants = eventData!.currentParticipants! - 1;
      }
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
      await CmeApiService.joinEvent(event.eventId);
      eventData?.isAttending = true;
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
