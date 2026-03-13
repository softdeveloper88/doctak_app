import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_history_model.dart';
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:equatable/equatable.dart';

part 'meeting_event.dart';
part 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final int nextPageTrigger = 1;
  GetMeetingModel? meetings;

  // Meeting history
  List<MeetingHistoryItem> historyList = [];
  int historyPage = 1;
  int historyLastPage = 1;
  String historyFilter = 'all';
  String historySearch = '';
  bool isHistoryLoading = false;

  // search contacts
  int contactPageNumber = 1;
  int contactNumberOfPage = 1;
  List<SearchData> searchContactsList = [];
  MeetingBloc() : super(MeetingsInitial()) {
    on<FetchMeetings>(_onFetchMeetings);
    on<FetchMeetingHistory>(_onFetchMeetingHistory);
    on<LoadMoreMeetingHistory>(_onLoadMoreMeetingHistory);
    on<CancelScheduledMeetingEvent>(_onCancelScheduledMeeting);
    on<LoadSearchUserEvent>(onGetSearchContacts);
    on<CheckIfNeedMoreUserDataEvent>((event, emit) async {
      if (event.index == searchContactsList.length - nextPageTrigger) {
        add(LoadSearchUserEvent(page: contactPageNumber, keyword: event.query));
      }
    });
  }
  Future<void> onGetSearchContacts(LoadSearchUserEvent event, Emitter<MeetingState> emit) async {
    if (event.page == 1) {
      searchContactsList.clear();
      contactPageNumber = 1;
      emit(MeetingsLoading());
    }
    try {
      SearchUserModel searchUserModel = await searchUserForMeeting(event.keyword);
      if (isClosed) return;

      contactNumberOfPage = searchUserModel.pagination?.lastPage ?? 0;
      if (contactPageNumber < contactNumberOfPage + 1) {
        contactPageNumber = contactPageNumber + 1;
        searchContactsList.addAll(searchUserModel.data ?? []);
      }

      emit(MeetingsLoaded());
    } catch (e) {
      if (isClosed) return;
      emit(MeetingsLoaded());
    }
  }

  Future<void> _onFetchMeetings(FetchMeetings event, Emitter<MeetingState> emit) async {
    emit(MeetingsLoading());
    try {
      meetings = await getMeetings();
      if (isClosed) return;
      emit(MeetingsLoaded());
    } catch (e) {
      if (isClosed) return;
      emit(MeetingsError(e.toString()));
    }
  }

  Future<void> _onFetchMeetingHistory(FetchMeetingHistory event, Emitter<MeetingState> emit) async {
    historyFilter = event.filter;
    historySearch = event.search;
    historyPage = 1;
    historyList.clear();
    isHistoryLoading = true;
    emit(MeetingHistoryLoading());
    try {
      final response = await getMeetingHistory(
        filter: historyFilter,
        search: historySearch,
        page: historyPage,
      );
      if (isClosed) return;
      historyList = response.data;
      historyLastPage = response.pagination.lastPage;
      isHistoryLoading = false;
      emit(MeetingHistoryLoaded());
    } catch (e) {
      if (isClosed) return;
      isHistoryLoading = false;
      emit(MeetingHistoryError(e.toString()));
    }
  }

  Future<void> _onLoadMoreMeetingHistory(LoadMoreMeetingHistory event, Emitter<MeetingState> emit) async {
    if (historyPage >= historyLastPage || isHistoryLoading) return;
    historyPage++;
    isHistoryLoading = true;
    emit(MeetingHistoryLoadingMore());
    try {
      final response = await getMeetingHistory(
        filter: historyFilter,
        search: historySearch,
        page: historyPage,
      );
      if (isClosed) return;
      historyList.addAll(response.data);
      historyLastPage = response.pagination.lastPage;
      isHistoryLoading = false;
      emit(MeetingHistoryLoaded());
    } catch (e) {
      if (isClosed) return;
      isHistoryLoading = false;
      historyPage--;
      emit(MeetingHistoryLoaded());
    }
  }

  Future<void> _onCancelScheduledMeeting(CancelScheduledMeetingEvent event, Emitter<MeetingState> emit) async {
    try {
      await cancelScheduledMeeting(event.meetingId);
      if (isClosed) return;
      // Refresh scheduled meetings
      add(FetchMeetings());
    } catch (e) {
      if (isClosed) return;
      emit(MeetingsError(e.toString()));
    }
  }
}
