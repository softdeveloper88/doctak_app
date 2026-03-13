import 'package:equatable/equatable.dart';

abstract class CmeOnDemandEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadOnDemandModulesEvent extends CmeOnDemandEvent {
  final String eventId;
  CmeLoadOnDemandModulesEvent({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

class CmeLoadOnDemandModuleDetailEvent extends CmeOnDemandEvent {
  final String moduleId;
  CmeLoadOnDemandModuleDetailEvent({required this.moduleId});

  @override
  List<Object?> get props => [moduleId];
}

class CmeCompleteSectionEvent extends CmeOnDemandEvent {
  final String moduleId;
  final String sectionId;
  CmeCompleteSectionEvent({required this.moduleId, required this.sectionId});

  @override
  List<Object?> get props => [moduleId, sectionId];
}

class CmeBackToModulesEvent extends CmeOnDemandEvent {}
