import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cme_events_event.dart';
import 'cme_events_state.dart';

class CmeEventsBloc extends Bloc<CmeEventsEvent, CmeEventsState> {
  int pageNumber = 1;
  int numberOfPage = 1;
  List<CmeEventData> eventsList = [];
  final int nextPageTrigger = 1;

  String? currentSearch;
  String? currentType;
  String? currentFormat;
  String? currentSpecialty;
  String? currentStatus;

  CmeEventsBloc() : super(CmeEventsInitialState()) {
    on<CmeLoadEventsEvent>(_onLoadEvents);
    on<CmeCheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == eventsList.length - nextPageTrigger) {
        add(CmeLoadEventsEvent(
          page: pageNumber,
          search: currentSearch,
          type: currentType,
          format: currentFormat,
          specialty: currentSpecialty,
          status: currentStatus,
        ));
      }
    });
    on<CmeLoadFiltersEvent>(_onLoadFilters);
  }

  Future<void> _onLoadEvents(
      CmeLoadEventsEvent event, Emitter<CmeEventsState> emit) async {
    if (event.page == null || event.page == 1) {
      eventsList.clear();
      pageNumber = 1;
      emit(CmeEventsLoadingState());
    }

    currentSearch = event.search;
    currentType = event.type;
    currentFormat = event.format;
    currentSpecialty = event.specialty;
    currentStatus = event.status;

    try {
      final response = await CmeApiService.getEvents(
        page: pageNumber,
        search: currentSearch,
        type: currentType,
        format: currentFormat,
        specialty: currentSpecialty,
        status: currentStatus,
      );

      numberOfPage = response.events?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        eventsList.addAll(response.events?.data ?? []);
      }
      emit(CmeEventsLoadedState());
    } catch (e) {
      if (eventsList.isEmpty) {
        emit(CmeEventsErrorState('$e'));
      } else {
        emit(CmeEventsLoadedState());
      }
    }
  }

  Future<void> _onLoadFilters(
      CmeLoadFiltersEvent event, Emitter<CmeEventsState> emit) async {
    try {
      final specialties = await CmeApiService.getSpecialties();
      final categories = await CmeApiService.getCategories();
      emit(CmeFiltersLoadedState(
        specialties: specialties,
        categories: categories,
      ));
    } catch (e) {
      // Silently fail — filters are non-critical
    }
  }
}
