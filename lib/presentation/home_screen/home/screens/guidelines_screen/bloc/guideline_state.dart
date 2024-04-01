import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:equatable/equatable.dart';


abstract class GuidelineState {}
class DrugsDataInitial extends GuidelineState {}

class DataError extends GuidelineState {
  final String errorMessage;
  DataError(this.errorMessage);
}
class PaginationInitialState extends GuidelineState {
  PaginationInitialState();
}
class PaginationLoadedState extends GuidelineState {}
class PaginationLoadingState extends GuidelineState {}

class PaginationErrorState extends GuidelineState {}

