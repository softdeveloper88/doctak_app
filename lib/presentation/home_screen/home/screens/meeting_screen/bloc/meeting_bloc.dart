import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:equatable/equatable.dart';

part 'meeting_event.dart';
part 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final int nextPageTrigger = 1;
  GetMeetingModel? meetings;

  // search contacts
  int contactPageNumber = 1;
  int contactNumberOfPage = 1;
  List<SearchData> searchContactsList = [];
  MeetingBloc() : super(MeetingsInitial()) {
    on<FetchMeetings>(_onFetchMeetings);
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

      contactNumberOfPage = searchUserModel.pagination?.lastPage ?? 0;
      if (contactPageNumber < contactNumberOfPage + 1) {
        contactPageNumber = contactPageNumber + 1;
        searchContactsList.addAll(searchUserModel.data ?? []);
      }

      emit(MeetingsLoaded());

      // emit(DataLoaded(contactsList));
    } catch (e) {
      print(e);

      emit(MeetingsLoaded());

      // emit(DataError('An error occurred $e'));
    }
  }

  Future<void> _onFetchMeetings(FetchMeetings event, Emitter<MeetingState> emit) async {
    emit(MeetingsLoading());
    // try {
    meetings = await getMeetings();

    // print('meeting ${meetings}');

    emit(MeetingsLoaded());
    // } catch (e) {
    //
    //   emit(MeetingsError(e.toString()));
    // }
  }
}
