import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class DrugsDataInitial extends NotificationState {}

class DataError extends NotificationState {
  final String errorMessage;
  const DataError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class PaginationInitialState extends NotificationState {
  const PaginationInitialState();
}

class PaginationLoadedState extends NotificationState {
  final int notificationCount;
  final int itemCount;
  final bool isLoadingMore;

  const PaginationLoadedState({
    this.notificationCount = 0,
    this.itemCount = 0,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [notificationCount, itemCount, isLoadingMore];
}

class PaginationLoadingState extends NotificationState {
  const PaginationLoadingState();
}

class PaginationErrorState extends NotificationState {
  const PaginationErrorState();
}
