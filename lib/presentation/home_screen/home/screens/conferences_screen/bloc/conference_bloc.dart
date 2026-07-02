import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'conference_event.dart';
import 'conference_state.dart';

class ConferenceBloc extends Bloc<ConferenceEvent, ConferenceState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  int pageNumber = 1;
  int numberOfPage = 1;
  int totalCount = 0;
  List<Data> conferenceList = [];
  List<ConferenceMonthBucket> monthBuckets = [];
  String selectedCountry = 'all';
  String selectedSearch = '';
  String selectedMonth = '';
  final int nextPageTrigger = 1;

  ConferenceBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetJobs);
    on<LoadDropdownData>(_listCountryList);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == conferenceList.length - nextPageTrigger) {
        add(LoadPageEvent(
          page: pageNumber,
          countryName: selectedCountry,
          searchTerm: selectedSearch,
          month: selectedMonth,
        ));
      }
    });
  }

  Future<void> _onGetJobs(LoadPageEvent event, Emitter<ConferenceState> emit) async {
    final requestedPage = event.page ?? pageNumber;
    selectedCountry = event.countryName ?? selectedCountry;
    selectedSearch = event.searchTerm ?? selectedSearch;
    selectedMonth = event.month ?? selectedMonth;

    if (requestedPage == 1) {
      conferenceList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }

    try {
      final response = await apiManager.searchConferences(
        'Bearer ${AppData.userToken}',
        '$requestedPage',
        selectedCountry,
        selectedSearch,
        month: selectedMonth.isEmpty ? null : selectedMonth,
      );

      numberOfPage = response.conferences?.lastPage ?? 0;
      totalCount = response.conferences?.total ?? conferenceList.length;
      monthBuckets = response.monthBuckets;

      if (requestedPage == 1) {
        conferenceList = List<Data>.from(response.conferences?.data ?? []);
        pageNumber = conferenceList.isEmpty ? 1 : 2;
      } else if (requestedPage < numberOfPage + 1) {
        conferenceList.addAll(response.conferences?.data ?? []);
        pageNumber = requestedPage + 1;
      }

      emit(PaginationLoadedState());
    } catch (e) {
      emit(PaginationLoadedState());
    }
  }

  Future<void> _listCountryList(LoadDropdownData event, Emitter<ConferenceState> emit) async {
    try {
      final response = await apiManager.getConferenceCountries('Bearer ${AppData.userToken}');
      emit(CountriesDataLoaded(
        countriesModel: response.data['countries'],
        countryName: event.countryName,
        searchTerms: event.searchTerms,
      ));
    } catch (e) {
      emit(DataError('$e'));
    }
  }
}
