import 'package:equatable/equatable.dart';

abstract class CmeDashboardEvent extends Equatable {}

class CmeLoadDashboardEvent extends CmeDashboardEvent {
  @override
  List<Object?> get props => [];
}

class CmeLoadMyEventsEvent extends CmeDashboardEvent {
  final String tab; // 'registered', 'upcoming', 'attended', 'created'
  final int? page;
  final String? search;

  CmeLoadMyEventsEvent({required this.tab, this.page, this.search});

  @override
  List<Object?> get props => [tab, page, search];
}

class CmeMyEventsCheckMoreEvent extends CmeDashboardEvent {
  final int index;
  final String tab;

  CmeMyEventsCheckMoreEvent({required this.index, required this.tab});

  @override
  List<Object?> get props => [index, tab];
}
