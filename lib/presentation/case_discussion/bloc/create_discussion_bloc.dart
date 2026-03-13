// ============================================================================
// Create Discussion BLoC - v6 API
// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/case_discussion_repository.dart';
import '../models/case_discussion_models.dart';

// Events
abstract class CreateDiscussionEvent extends Equatable {
  const CreateDiscussionEvent();
  @override
  List<Object?> get props => [];
}

class CreateDiscussion extends CreateDiscussionEvent {
  final CreateCaseRequest request;
  const CreateDiscussion(this.request);
  @override
  List<Object> get props => [request];
}

class UpdateDiscussion extends CreateDiscussionEvent {
  final int caseId;
  final CreateCaseRequest request;
  const UpdateDiscussion(this.caseId, this.request);
  @override
  List<Object> get props => [caseId, request];
}

class ResetCreateDiscussion extends CreateDiscussionEvent {}

// States
abstract class CreateDiscussionState extends Equatable {
  const CreateDiscussionState();
  @override
  List<Object?> get props => [];
}

class CreateDiscussionInitial extends CreateDiscussionState {}

class CreateDiscussionLoading extends CreateDiscussionState {}

class CreateDiscussionSuccess extends CreateDiscussionState {
  final CaseDiscussion discussion;
  final bool isUpdate;
  const CreateDiscussionSuccess(this.discussion, {this.isUpdate = false});
  @override
  List<Object> get props => [discussion, isUpdate];
}

class CreateDiscussionError extends CreateDiscussionState {
  final String message;
  const CreateDiscussionError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class CreateDiscussionBloc
    extends Bloc<CreateDiscussionEvent, CreateDiscussionState> {
  final CaseDiscussionRepository repository;

  CreateDiscussionBloc({required this.repository})
      : super(CreateDiscussionInitial()) {
    on<CreateDiscussion>(_onCreateDiscussion);
    on<UpdateDiscussion>(_onUpdateDiscussion);
    on<ResetCreateDiscussion>(_onReset);
  }

  Future<void> _onCreateDiscussion(
      CreateDiscussion event, Emitter<CreateDiscussionState> emit) async {
    emit(CreateDiscussionLoading());
    try {
      final discussion =
          await repository.createCaseDiscussion(event.request);
      emit(CreateDiscussionSuccess(discussion, isUpdate: false));
    } catch (e) {
      emit(CreateDiscussionError(e.toString()));
    }
  }

  Future<void> _onUpdateDiscussion(
      UpdateDiscussion event, Emitter<CreateDiscussionState> emit) async {
    emit(CreateDiscussionLoading());
    try {
      final discussion = await repository.updateCaseDiscussion(
          event.caseId, event.request);
      emit(CreateDiscussionSuccess(discussion, isUpdate: true));
    } catch (e) {
      emit(CreateDiscussionError(e.toString()));
    }
  }

  void _onReset(
      ResetCreateDiscussion event, Emitter<CreateDiscussionState> emit) {
    emit(CreateDiscussionInitial());
  }
}
