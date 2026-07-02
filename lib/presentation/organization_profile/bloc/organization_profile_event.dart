import 'package:equatable/equatable.dart';

abstract class OrganizationProfileEvent extends Equatable {
  const OrganizationProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrganizationProfileEvent extends OrganizationProfileEvent {
  const LoadOrganizationProfileEvent({required this.identifier});

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}

class ToggleOrganizationFollowEvent extends OrganizationProfileEvent {
  const ToggleOrganizationFollowEvent();
}
