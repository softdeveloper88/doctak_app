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
  @override
  List<Object> get props => [];
}

class MeetingsError extends MeetingState {
  final String message;

  const MeetingsError(this.message);

  @override
  List<Object> get props => [message];
}

class MeetingHistoryLoading extends MeetingState {}

class MeetingHistoryLoaded extends MeetingState {}

class MeetingHistoryLoadingMore extends MeetingState {}

class MeetingHistoryError extends MeetingState {
  final String message;

  const MeetingHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
