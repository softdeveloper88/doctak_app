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

  const CreateDiscussionSuccess(this.discussion);

  @override
  List<Object> get props => [discussion];
}

class CreateDiscussionError extends CreateDiscussionState {
  final String message;

  const CreateDiscussionError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class CreateDiscussionBloc extends Bloc<CreateDiscussionEvent, CreateDiscussionState> {
  final CaseDiscussionRepository repository;

  CreateDiscussionBloc({required this.repository}) : super(CreateDiscussionInitial()) {
    on<CreateDiscussion>(_onCreateDiscussion);
    on<ResetCreateDiscussion>(_onResetCreateDiscussion);
  }

  Future<void> _onCreateDiscussion(
    CreateDiscussion event,
    Emitter<CreateDiscussionState> emit,
  ) async {
    emit(CreateDiscussionLoading());

    try {
      print('=== Creating Case Discussion ===');
      print('Title: ${event.request.title}');
      print('Description: ${event.request.description}');
      print('Tags: ${event.request.tags}');
      // print('Specialty ID: ${event.request.specialtyId}');
      print('Attached File: ${event.request.attachedFiles}');
      
      final discussion = await repository.createCaseDiscussion(event.request);
      
      print('✅ Case discussion created successfully: ${discussion.id}');
      emit(CreateDiscussionSuccess(discussion));
    } catch (e, stackTrace) {
      print('❌ Error creating case discussion: $e');
      print('Stack trace: $stackTrace');
      emit(CreateDiscussionError(e.toString()));
    }
  }

  void _onResetCreateDiscussion(
    ResetCreateDiscussion event,
    Emitter<CreateDiscussionState> emit,
  ) {
    emit(CreateDiscussionInitial());
  }
}