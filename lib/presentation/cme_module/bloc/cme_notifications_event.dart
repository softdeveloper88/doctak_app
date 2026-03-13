import 'package:equatable/equatable.dart';

abstract class CmeNotificationsEvent extends Equatable {}

class CmeLoadNotificationsEvent extends CmeNotificationsEvent {
  @override
  List<Object?> get props => [];
}

class CmeMarkNotificationReadEvent extends CmeNotificationsEvent {
  final String notificationId;
  CmeMarkNotificationReadEvent({required this.notificationId});
  @override
  List<Object?> get props => [notificationId];
}

class CmeMarkAllNotificationsReadEvent extends CmeNotificationsEvent {
  @override
  List<Object?> get props => [];
}
