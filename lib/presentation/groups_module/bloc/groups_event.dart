import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:equatable/equatable.dart';

abstract class GroupsEvent extends Equatable {
  const GroupsEvent();

  @override
  List<Object?> get props => [];
}

class GroupsBrowseRequested extends GroupsEvent {
  final bool refresh;
  final String? keyword;

  const GroupsBrowseRequested({this.refresh = false, this.keyword});

  @override
  List<Object?> get props => [refresh, keyword];
}

class GroupsBrowseLoadMore extends GroupsEvent {
  const GroupsBrowseLoadMore();
}

class GroupsMineRequested extends GroupsEvent {
  final bool refresh;
  final String scope;

  const GroupsMineRequested({this.refresh = false, this.scope = 'joined'});

  @override
  List<Object?> get props => [refresh, scope];
}

class GroupsCreatedRequested extends GroupsEvent {
  final bool refresh;

  const GroupsCreatedRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class GroupsInvitationsRequested extends GroupsEvent {
  final bool refresh;

  const GroupsInvitationsRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class GroupsSuggestionsRequested extends GroupsEvent {
  const GroupsSuggestionsRequested();
}

class GroupJoinRequested extends GroupsEvent {
  final GroupSummaryModel group;

  const GroupJoinRequested(this.group);

  @override
  List<Object?> get props => [group.routeId];
}

class GroupInvitationRespondRequested extends GroupsEvent {
  final String invitationId;
  final bool accept;
  final GroupSummaryModel? group;

  const GroupInvitationRespondRequested({
    required this.invitationId,
    required this.accept,
    this.group,
  });

  @override
  List<Object?> get props => [invitationId, accept];
}

class GroupsSearchChanged extends GroupsEvent {
  final String keyword;

  const GroupsSearchChanged(this.keyword);

  @override
  List<Object?> get props => [keyword];
}
