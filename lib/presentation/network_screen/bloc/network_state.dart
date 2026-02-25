part of 'network_bloc.dart';

abstract class NetworkState {
  const NetworkState();
}

class NetworkInitialState extends NetworkState {}

class NetworkLoadingState extends NetworkState {}

class NetworkLoadedState extends NetworkState {
  final List<dynamic> items;
  final int currentPage;
  final bool hasMore;
  const NetworkLoadedState({required this.items, this.currentPage = 1, this.hasMore = false});
}

class NetworkErrorState extends NetworkState {
  final String message;
  const NetworkErrorState(this.message);
}

class NetworkActionSuccessState extends NetworkState {
  final String message;
  const NetworkActionSuccessState(this.message);
}
