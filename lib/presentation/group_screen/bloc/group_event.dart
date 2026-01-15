// ignore_for_file: must_be_immutable
import 'package:equatable/equatable.dart';

abstract class GroupEvent extends Equatable {}

class UpdateSpecialtyDropdownValue extends GroupEvent {
  final String newValue;

  UpdateSpecialtyDropdownValue(this.newValue);

  @override
  // TODO: implement props
  List<Object?> get props => [newValue];
}

class UpdateSpecialtyDropdownValue1 extends GroupEvent {
  final String newValue;

  UpdateSpecialtyDropdownValue1(this.newValue);

  @override
  // TODO: implement props
  List<Object?> get props => [newValue];
}

class GroupDetailsEvent extends GroupEvent {
  final String id;

  GroupDetailsEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ListGroupsEvent extends GroupEvent {
  ListGroupsEvent();

  @override
  List<Object?> get props => [];
}

class GroupMemberRequestEvent extends GroupEvent {
  final String id;

  GroupMemberRequestEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class GroupMemberRequestUpdateEvent extends GroupEvent {
  final String id;
  final String groupId;
  final String status;

  GroupMemberRequestUpdateEvent(this.id, this.groupId, this.status);

  @override
  List<Object?> get props => [id, groupId, status];
}

class GroupMembersEvent extends GroupEvent {
  final String id;
  final String keyword;

  GroupMembersEvent(this.id, this.keyword);

  @override
  List<Object?> get props => [id, keyword];
}

class GroupPostRequestEvent extends GroupEvent {
  final String id;
  final String offset;

  GroupPostRequestEvent(this.id, this.offset);

  @override
  List<Object?> get props => [id, offset];
}

class GroupNotificationEvent extends GroupEvent {
  final String type;
  final String groupNotificationPush;
  final String groupNotificationEmail;

  GroupNotificationEvent(this.type, this.groupNotificationPush, this.groupNotificationEmail);

  @override
  List<Object?> get props => [type, groupNotificationPush, groupNotificationEmail];
}
