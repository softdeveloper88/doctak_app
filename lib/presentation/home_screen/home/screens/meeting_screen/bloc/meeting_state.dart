// meetings_state.dart
part of 'meeting_bloc.dart';

abstract class MeetingState extends Equatable {
  const MeetingState();

  @override
  List<Object> get props => [];
}

class MeetingsInitial extends MeetingState {}

class MeetingsLoading extends MeetingState {}

class MeetingsLoaded extends MeetingState {
  // final GetMeetingModel meetings;

  // const MeetingsLoaded(this.meetings);

  @override
  List<Object> get props => [];

}

class MeetingsError extends MeetingState {
  final String message;

  const MeetingsError(this.message);

  @override
  List<Object> get props => [message];
}