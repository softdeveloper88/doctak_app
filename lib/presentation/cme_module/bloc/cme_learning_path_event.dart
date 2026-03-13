import 'package:equatable/equatable.dart';

abstract class CmeLearningPathEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadLearningPathsEvent extends CmeLearningPathEvent {
  final int page;
  CmeLoadLearningPathsEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class CmeBrowseLearningPathsEvent extends CmeLearningPathEvent {
  final int page;
  CmeBrowseLearningPathsEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class CmeLoadMyEnrolledPathsEvent extends CmeLearningPathEvent {}

class CmeLoadMyCompletedPathsEvent extends CmeLearningPathEvent {}

class CmeLoadPathDetailEvent extends CmeLearningPathEvent {
  final String pathId;
  CmeLoadPathDetailEvent({required this.pathId});

  @override
  List<Object?> get props => [pathId];
}

class CmeEnrollInPathEvent extends CmeLearningPathEvent {
  final String pathId;
  CmeEnrollInPathEvent({required this.pathId});

  @override
  List<Object?> get props => [pathId];
}

class CmeUnenrollFromPathEvent extends CmeLearningPathEvent {
  final String enrollmentId;
  CmeUnenrollFromPathEvent({required this.enrollmentId});

  @override
  List<Object?> get props => [enrollmentId];
}

class CmePausePathEvent extends CmeLearningPathEvent {
  final String enrollmentId;
  CmePausePathEvent({required this.enrollmentId});

  @override
  List<Object?> get props => [enrollmentId];
}

class CmeResumePathEvent extends CmeLearningPathEvent {
  final String enrollmentId;
  CmeResumePathEvent({required this.enrollmentId});

  @override
  List<Object?> get props => [enrollmentId];
}

class CmeCheckIfNeedMorePathsEvent extends CmeLearningPathEvent {
  final int index;
  CmeCheckIfNeedMorePathsEvent({required this.index});

  @override
  List<Object?> get props => [index];
}
