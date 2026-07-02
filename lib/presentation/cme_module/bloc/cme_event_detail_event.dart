import 'package:equatable/equatable.dart';

abstract class CmeEventDetailEvent extends Equatable {}

class CmeLoadEventDetailEvent extends CmeEventDetailEvent {
  final String eventId;
  final bool silent;

  CmeLoadEventDetailEvent({required this.eventId, this.silent = false});

  @override
  List<Object?> get props => [eventId, silent];
}

class CmeRegisterEvent extends CmeEventDetailEvent {
  final String eventId;
  CmeRegisterEvent({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}

class CmeUnregisterEvent extends CmeEventDetailEvent {
  final String eventId;
  CmeUnregisterEvent({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}

class CmeJoinEventEvent extends CmeEventDetailEvent {
  final String eventId;
  CmeJoinEventEvent({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}

class CmeJoinWaitlistEvent extends CmeEventDetailEvent {
  final String eventId;
  CmeJoinWaitlistEvent({required this.eventId});
  @override
  List<Object?> get props => [eventId];
}
