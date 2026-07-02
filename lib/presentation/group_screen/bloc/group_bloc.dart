import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/apiClient/services/group_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_about_model.dart';
import 'package:doctak_app/data/models/group_model/group_details_model.dart';
import 'package:doctak_app/data/models/group_model/group_list_model.dart';
import 'package:doctak_app/data/models/group_model/group_member_request_model.dart';
import 'package:doctak_app/data/models/group_model/group_post_model.dart';
import 'package:doctak_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'group_event.dart';
import 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  String? specialtyName;
  List<String>? specialtyList;
  String? name;
  List<Map<String, dynamic>> tags = [];
  List<Map<String, dynamic>> interest = [];
  List<Map<String, dynamic>> language = [];
  List<Map<String, dynamic>> selectSpecialtyList = [];
  String? location;
  String? description;
  String? memberLimit;
  String? addAdmin;
  String? status;
  String? postStatus;
  String? postPermission;
  String? whoCanPost;
  String? allowInSearch;
  String? visibility;
  String? joinRequest;
  String? customRules;
  String? coverPicture;
  String? profilePicture;
  GroupDetailsModel? groupDetailsModel;
  GroupAboutModel? groupAboutModel;
  GroupMemberRequestModel? groupMemberRequestModel;
  GroupPostModel? groupPostModelRequest;
  GroupMemberRequestModel? groupMemberModel;
  GroupPostModel? groupPostModel;
  GroupListModel? groupListModel;

  GroupBloc() : super(DataInitial()) {
    on<UpdateSpecialtyDropdownValue>(_updateSpecialtyDropdownValues);
    on<UpdateSpecialtyDropdownValue1>(_createGroup);
    on<GroupDetailsEvent>(_groupDetails);
    on<GroupMemberRequestEvent>(_groupMemberRequest);
    on<ListGroupsEvent>(_listGroups);
    on<GroupMembersEvent>(_groupMembers);
    on<GroupMemberRequestUpdateEvent>(_groupMemberRequestUpdate);
    on<GroupNotificationEvent>(_groupNotification);
    on<GroupPostRequestEvent>(_groupPostRequest);
  }

  void _safeEmit(Emitter<GroupState> emit, GroupState state) {
    if (!emit.isDone) emit(state);
  }

  Map<String, dynamic>? _unwrapApiMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return map;
  }

  Future<void> _updateSpecialtyDropdownValues(
    UpdateSpecialtyDropdownValue event,
    Emitter<GroupState> emit,
  ) async {
    try {
      final secondDropdownValues = await _onGetSpecialty();
      final values = secondDropdownValues ?? <String>[];
      _safeEmit(
        emit,
        PaginationLoadedState(values, values.isNotEmpty ? values.first : ''),
      );
    } catch (e) {
      _safeEmit(emit, DataError('Failed to load specialties: $e'));
    }
  }

  Future<void> _groupDetails(
    GroupDetailsEvent event,
    Emitter<GroupState> emit,
  ) async {
    final id = event.id.trim();
    if (id.isEmpty) {
      _safeEmit(emit, DataError('Group not found'));
      return;
    }

    _safeEmit(emit, PaginationLoadingState());
    try {
      final res = await GroupApiService().getGroupDetails(groupId: id);
      if (emit.isDone) return;
      if (!res.success || res.data == null) {
        _safeEmit(emit, DataError(res.message ?? 'Failed to load group'));
        return;
      }
      groupDetailsModel = res.data;
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to load group: $e'));
    }
  }

  Future<void> _groupNotification(
    GroupNotificationEvent event,
    Emitter<GroupState> emit,
  ) async {
    _safeEmit(emit, PaginationLoadingState());
    try {
      await apiManager.groupNotificationUpdate(
        'Bearer ${AppData.userToken}',
        event.type,
        event.groupNotificationPush,
        event.groupNotificationEmail,
      );
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to update notifications: $e'));
    }
  }

  Future<void> _groupMemberRequest(
    GroupMemberRequestEvent event,
    Emitter<GroupState> emit,
  ) async {
    _safeEmit(emit, PaginationLoadingState());
    try {
      final raw = await apiManager.groupMemberRequest('Bearer ${AppData.userToken}', event.id);
      if (emit.isDone) return;
      final data = _unwrapApiMap(raw);
      if (data != null) {
        try {
          groupMemberRequestModel = GroupMemberRequestModel.fromJson(data);
        } catch (e) {
          debugPrint('GroupBloc: invalid member request payload: $e');
        }
      }
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to load member requests: $e'));
    }
  }

  Future<void> _groupPostRequest(
    GroupPostRequestEvent event,
    Emitter<GroupState> emit,
  ) async {
    _safeEmit(emit, PaginationLoadingState());
    try {
      final raw = await apiManager.groupPostRequest(
        'Bearer ${AppData.userToken}',
        event.id,
        event.offset,
      );
      if (emit.isDone) return;
      final data = _unwrapApiMap(raw);
      if (data != null) {
        try {
          groupPostModelRequest = GroupPostModel.fromJson(data);
        } catch (e) {
          debugPrint('GroupBloc: invalid post request payload: $e');
        }
      }
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to load post requests: $e'));
    }
  }

  Future<void> _groupMembers(
    GroupMembersEvent event,
    Emitter<GroupState> emit,
  ) async {
    _safeEmit(emit, PaginationLoadingState());
    try {
      final raw = await apiManager.groupMembers(
        'Bearer ${AppData.userToken}',
        event.id,
        event.keyword,
      );
      if (emit.isDone) return;
      final data = _unwrapApiMap(raw);
      if (data != null) {
        try {
          groupMemberModel = GroupMemberRequestModel.fromJson(data);
        } catch (e) {
          debugPrint('GroupBloc: invalid members payload: $e');
        }
      }
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to load members: $e'));
    }
  }

  Future<void> _groupMemberRequestUpdate(
    GroupMemberRequestUpdateEvent event,
    Emitter<GroupState> emit,
  ) async {
    _safeEmit(emit, PaginationLoadingState());
    try {
      await apiManager.groupMemberRequestUpdate(
        'Bearer ${AppData.userToken}',
        event.id,
        event.groupId,
        event.status,
      );
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to update member request: $e'));
    }
  }

  Future<void> _listGroups(
    ListGroupsEvent event,
    Emitter<GroupState> emit,
  ) async {
    _safeEmit(emit, PaginationLoadingState());
    try {
      groupListModel = await apiManager.listGroup('Bearer ${AppData.userToken}', AppData.logInUserId);
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('Failed to load groups: $e'));
    }
  }

  Future<void> _createGroup(
    UpdateSpecialtyDropdownValue1 event,
    Emitter<GroupState> emit,
  ) async {
    try {
      final response = await apiManager.groupStore(
        'Bearer ${AppData.userToken}',
        name ?? '',
        selectSpecialtyList.toString(),
        tags.toString(),
        location ?? '',
        interest.toString(),
        language.toString(),
        description ?? '',
        memberLimit ?? '50',
        AppData.logInUserId,
        status ?? '1',
        postPermission ?? 'Open',
        allowInSearch ?? '1',
        visibility ?? '1',
        joinRequest ?? '1',
        customRules ?? 'No Rules Set',
        profilePicture ?? '',
        coverPicture ?? '',
      );
      globalMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.toString())),
      );
      _safeEmit(emit, PaginationLoadedState([], ''));
    } catch (e) {
      _safeEmit(emit, DataError('$e'));
      globalMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<List<String>?> _onGetSpecialty() async {
    try {
      final response = await apiManager.getSpecialty();
      if (response != null && response.isNotEmpty) {
        final list = <String>['Select Specialty'];
        for (final element in response) {
          if (element is Map && element['name'] != null) {
            list.add(element['name']!);
          }
        }
        return list;
      }
      return [];
    } catch (e) {
      return null;
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    debugPrint('GroupBloc error: $error');
    debugPrint('$stackTrace');
    super.onError(error, stackTrace);
  }
}
