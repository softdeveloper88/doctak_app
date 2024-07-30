import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class CaseDiscussionState {}

class DrugsDataInitial extends CaseDiscussionState {}

class DataError extends CaseDiscussionState {
  final String errorMessage;
  DataError(this.errorMessage);
}

class PaginationInitialState extends CaseDiscussionState {
  PaginationInitialState();
}

class PaginationLoadedState extends CaseDiscussionState {}

class PaginationLoadingState extends CaseDiscussionState {}

class PaginationErrorState extends CaseDiscussionState {}
