import 'package:equatable/equatable.dart';

abstract class CmeEventsEvent extends Equatable {}

class CmeLoadEventsEvent extends CmeEventsEvent {
  final int? page;
  final String? search;
  final String? type;
  final String? format;
  final String? specialty;
  final String? status;

  CmeLoadEventsEvent({
    this.page,
    this.search,
    this.type,
    this.format,
    this.specialty,
    this.status,
  });

  @override
  List<Object?> get props => [page, search, type, format, specialty, status];
}

class CmeCheckIfNeedMoreDataEvent extends CmeEventsEvent {
  final int index;

  CmeCheckIfNeedMoreDataEvent({required this.index});

  @override
  List<Object?> get props => [index];
}

class CmeLoadFiltersEvent extends CmeEventsEvent {
  @override
  List<Object?> get props => [];
}
