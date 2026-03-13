// meetings_event.dart
part of 'meeting_bloc.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object> get props => [];
}

class CheckIfNeedMoreUserDataEvent extends MeetingEvent {
  final int index;
  final String query;

  const CheckIfNeedMoreUserDataEvent({required this.index, required this.query});

  @override
  List<Object> get props => [index, query];
}

class LoadSearchUserEvent extends MeetingEvent {
  int page;
  String keyword;
  LoadSearchUserEvent({required this.page, required this.keyword});
  @override
  List<Object> get props => [page, keyword];
}

class FetchMeetings extends MeetingEvent {}

class FetchMeetingHistory extends MeetingEvent {
  final String filter;
  final String search;

  const FetchMeetingHistory({this.filter = 'all', this.search = ''});

  @override
  List<Object> get props => [filter, search];
}

class LoadMoreMeetingHistory extends MeetingEvent {}

class CancelScheduledMeetingEvent extends MeetingEvent {
  final int meetingId;

  const CancelScheduledMeetingEvent({required this.meetingId});

  @override
  List<Object> get props => [meetingId];
}
