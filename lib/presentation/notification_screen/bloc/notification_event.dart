import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {}

class LoadDataValues extends NotificationEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends NotificationEvent {
  final String page;
  final String countryId;
  final String searchTerm;

  GetPost({required this.page, required this.countryId, required this.searchTerm});
  @override
  List<Object> get props => [page, countryId, searchTerm];
}

class NotificationLoadPageEvent extends NotificationEvent {
  int? page;
  String? readStatus;
  NotificationLoadPageEvent({this.page, this.readStatus});
  @override
  List<Object?> get props => [page, readStatus];
}

class NotificationDetailPageEvent extends NotificationEvent {
  String? jobId;

  NotificationDetailPageEvent({this.jobId});
  @override
  List<Object?> get props => [jobId];
}

class NotificationCounter extends NotificationEvent {
  NotificationCounter();
  @override
  List<Object?> get props => [];
}

class ReadNotificationEvent extends NotificationEvent {
  String? notificationId;

  ReadNotificationEvent({this.notificationId});
  @override
  List<Object?> get props => [notificationId];
}

class AnnouncementDetailEvent extends NotificationEvent {
  int? announcementId;

  AnnouncementDetailEvent({this.announcementId});
  @override
  List<Object?> get props => [announcementId];
}

class AnnouncementEvent extends NotificationEvent {
  @override
  List<Object?> get props => [];
}

class NotificationCheckIfNeedMoreDataEvent extends NotificationEvent {
  final int index;
  NotificationCheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
