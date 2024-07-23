import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:equatable/equatable.dart';

abstract class SearchPeopleState {}

class DrugsDataInitial extends SearchPeopleState {}

class SearchPeopleDataError extends SearchPeopleState {
  final String errorMessage;
  SearchPeopleDataError(this.errorMessage);
}

class SearchPeoplePaginationInitialState extends SearchPeopleState {
  SearchPeoplePaginationInitialState();
}

class SearchPeoplePaginationLoadedState extends SearchPeopleState {}

class SearchPeoplePaginationLoadingState extends SearchPeopleState {}

class SearchPeoplePaginationErrorState extends SearchPeopleState {}
