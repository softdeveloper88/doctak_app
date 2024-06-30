part of 'followers_bloc.dart';
abstract class FollowersState {}
class FollowersDataInitial extends FollowersState {}

class FollowersDataError extends FollowersState {
  final String errorMessage;
  FollowersDataError(this.errorMessage);
}
class FollowersPaginationInitialState extends FollowersState {
  FollowersPaginationInitialState();
}
class FollowersPaginationLoadedState extends FollowersState {}
class FollowersPaginationLoadingState extends FollowersState {}

class FollowersPaginationErrorState extends FollowersState {}

