import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_dashboard_model.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cme_dashboard_event.dart';
import 'cme_dashboard_state.dart';

class CmeDashboardBloc extends Bloc<CmeDashboardEvent, CmeDashboardState> {
  CmeDashboardResponse? dashboardData;

  // My Events pagination
  int pageNumber = 1;
  int numberOfPage = 1;
  List<CmeEventData> myEventsList = [];
  final int nextPageTrigger = 1;
  String currentTab = 'registered';
  String currentSearch = '';

  CmeDashboardBloc() : super(CmeDashboardInitialState()) {
    on<CmeLoadDashboardEvent>(_onLoadDashboard);
    on<CmeLoadMyEventsEvent>(_onLoadMyEvents);
    on<CmeMyEventsCheckMoreEvent>((event, emit) async {
      if (event.index == myEventsList.length - nextPageTrigger) {
        add(CmeLoadMyEventsEvent(tab: event.tab, page: pageNumber, search: currentSearch.isNotEmpty ? currentSearch : null));
      }
    });
  }

  Future<void> _onLoadDashboard(
      CmeLoadDashboardEvent event, Emitter<CmeDashboardState> emit) async {
    emit(CmeDashboardLoadingState());
    try {
      dashboardData = await CmeApiService.getDashboard();
      emit(CmeDashboardLoadedState());
    } catch (e) {
      emit(CmeDashboardErrorState('$e'));
    }
  }

  Future<void> _onLoadMyEvents(
      CmeLoadMyEventsEvent event, Emitter<CmeDashboardState> emit) async {
    final searchChanged = (event.search ?? '') != currentSearch;
    if (event.tab != currentTab || event.page == null || event.page == 1 || searchChanged) {
      myEventsList.clear();
      pageNumber = 1;
      currentTab = event.tab;
      currentSearch = event.search ?? '';
      emit(CmeMyEventsLoadingState());
    }

    try {
      CmeEventsResponse response;
      switch (event.tab) {
        case 'upcoming':
          response = await CmeApiService.getUpcomingEvents(page: pageNumber, search: currentSearch.isNotEmpty ? currentSearch : null);
          break;
        case 'attended':
          response = await CmeApiService.getAttendedEvents(page: pageNumber, search: currentSearch.isNotEmpty ? currentSearch : null);
          break;
        case 'created':
          response = await CmeApiService.getCreatedEvents(page: pageNumber, search: currentSearch.isNotEmpty ? currentSearch : null);
          break;
        default:
          response = await CmeApiService.getMyEvents(page: pageNumber, search: currentSearch.isNotEmpty ? currentSearch : null);
      }

      numberOfPage = response.events?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        myEventsList.addAll(response.events?.data ?? []);
      }
      emit(CmeMyEventsLoadedState());
    } catch (e) {
      if (myEventsList.isEmpty) {
        emit(CmeDashboardErrorState('$e'));
      } else {
        emit(CmeMyEventsLoadedState());
      }
    }
  }
}
