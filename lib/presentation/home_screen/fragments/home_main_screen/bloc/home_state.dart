// ignore_for_file: must_be_immutable

part of 'home_bloc.dart';

abstract class HomeState {}

class DataInitial extends HomeState {}

class SearchPostPaginationInitialState extends HomeState {
  SearchPostPaginationInitialState();
}

class PostPaginationLoadedState extends HomeState {
  final bool isFromCache;
  final bool isPaginationLoading; // True when loading next page (doesn't block UI)
  PostPaginationLoadedState({
    this.isFromCache = false,
    this.isPaginationLoading = false,
  });
}

class PostPaginationLoadingState extends HomeState {}

class PostPaginationErrorState extends HomeState {}

/// State when posts list is genuinely empty after API fetch
class PostsEmptyState extends HomeState {}

/// State when API failed but we have cached data to show (LinkedIn-style)
/// Shows cached posts with a retry banner at the bottom
class PostOfflineWithCacheState extends HomeState {
  final String errorMessage;
  PostOfflineWithCacheState({required this.errorMessage});
}

class PostDataError extends HomeState {
  final String errorMessage;
  PostDataError(this.errorMessage);
}
