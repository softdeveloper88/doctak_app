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
