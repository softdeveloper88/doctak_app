// ignore_for_file: must_be_immutable

part of 'home_bloc.dart';

abstract class HomeState {}

class DataInitial extends HomeState {}

class SearchPostPaginationInitialState extends HomeState {
  SearchPostPaginationInitialState();
}

class PostPaginationLoadedState extends HomeState {}

class PostPaginationLoadingState extends HomeState {}

class PostPaginationErrorState extends HomeState {}

class PostDataError extends HomeState {
  final String errorMessage;
  PostDataError(this.errorMessage);
}
