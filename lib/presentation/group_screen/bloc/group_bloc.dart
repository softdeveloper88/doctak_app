import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
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
  final ApiService postService = ApiService(Dio());
  String? specialtyName;
  List<String>? specialtyList;
  String? name;
  List<Map<String, dynamic>> tags = [];
  List<Map<String, dynamic>> interest = [];
  List<Map<String, dynamic>> language = [];
  List<Map<String, dynamic>> selectSpecialtyList=[];
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

  void _updateSpecialtyDropdownValues(
      UpdateSpecialtyDropdownValue event, Emitter<GroupState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues = await _onGetSpecialty();
    emit(PaginationLoadedState(
      secondDropdownValues ?? [],
      secondDropdownValues?.first ?? '',
    ));
  }

  void _groupDetails(
      GroupDetailsEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());
    groupDetailsModel = await postService.groupDetails( 'Bearer ${AppData.userToken}', event.id);
    groupAboutModel = await postService.groupAbout( 'Bearer ${AppData.userToken}', event.id);
    groupPostModel = await postService.groupPost( 'Bearer ${AppData.userToken}', event.id,'0');
    var response = await postService.groupNotificationUpdate( 'Bearer ${AppData.userToken}', 'get','','');
    print(response);
    print(AppData.logInUserId);
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }
  void _groupNotification(
      GroupNotificationEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());
    var response = await postService.groupNotificationUpdate( 'Bearer ${AppData.userToken}', event.type,event.groupNotificationPush,event.groupNotificationEmail);
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }

 void _groupMemberRequest(
      GroupMemberRequestEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());
    groupMemberRequestModel = await postService.groupMemberRequest( 'Bearer ${AppData.userToken}', event.id);
     print(groupMemberRequestModel?.toJson());
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }
  void _groupPostRequest(
      GroupPostRequestEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());
    groupPostModelRequest = await postService.groupPostRequest( 'Bearer ${AppData.userToken}', event.id,event.offset);
     print(groupPostModelRequest?.toJson());
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }
  void _groupMembers(
      GroupMembersEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());
    groupMemberModel = await postService.groupMembers( 'Bearer ${AppData.userToken}', event.id,event.keyword);
     print(groupMemberRequestModel?.toJson());
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }
  void _groupMemberRequestUpdate(
      GroupMemberRequestUpdateEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());
    print(    event.groupId);
    print(    event.id);
    print(    event.status);
    var response = await postService.groupMemberRequestUpdate( 'Bearer ${AppData.userToken}', event.id,event.groupId,event.status);
    print(response.data);
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }
  void _listGroups(
      ListGroupsEvent event, Emitter<GroupState> emit) async {

    emit(PaginationLoadingState());

     groupListModel = await postService.listGroup( 'Bearer ${AppData.userToken}', AppData.logInUserId);
    emit(PaginationLoadedState(
      [],
      '',
    ));
  }

  void _createGroup(
      UpdateSpecialtyDropdownValue1 event, Emitter<GroupState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    print(name.toString(),);
    print(selectSpecialtyList.toString(),);
    print(tags.toString(),);
    print(location.toString(),);
    print(interest.toString(),);
    print(language.toString(),);
    print(description.toString(),);
    print(memberLimit.toString(),);
    print(addAdmin.toString(),);
    print(status.toString(),);
    print(postPermission.toString(),);
    print(allowInSearch.toString(),);
    print(visibility.toString(),);
    print(joinRequest.toString(),);
    print(customRules.toString(),);
    print(coverPicture.toString(),);
    print(profilePicture.toString(),);
    try {
      final response = await postService.groupStore(
          'Bearer ${AppData.userToken}',
          name ?? '',
          selectSpecialtyList.toString(),
          tags.toString(),
          location ?? '',
          interest.toString(),
          language.toString(),
          description ?? "",
          memberLimit ?? '50',
          AppData.logInUserId,
          status ?? '1',
          postPermission ?? "Open",
          allowInSearch ?? "1",
          visibility ?? "1",
          joinRequest ?? '1',
          customRules ?? 'No Rules Set',
          profilePicture ?? '',
          coverPicture ?? "");
      globalMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(response.toString())));
      emit(PaginationLoadedState(
        [],
        '',
      ));
    }catch(e){
      emit(DataError('$e'));
      globalMessengerKey.currentState?.showSnackBar(SnackBar(content: Text("$e")));

    }

  }

  Future<List<String>?> _onGetSpecialty() async {
    // emit(DataLoading());
    try {
      final response = await postService.getSpecialty();
      if (response.data!.isNotEmpty) {
        // emit(DataSuccess(countriesModel: response));
        List<String> list = [];
        list.add('Select Specialty');
        response.data!.forEach((element) {
          list.add(element['name']!);
        });
        return list;
      } else {
        return [];
        // emit(DataFailure(error: 'Failed to load data'));
      }
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }
}
