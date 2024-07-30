import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/case_model/case_comments.dart';
import 'package:doctak_app/data/models/case_model/case_discuss_model.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import 'case_discussion_event.dart';
import 'case_discussion_state.dart';

class CaseDiscussionBloc
    extends Bloc<CaseDiscussionEvent, CaseDiscussionState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Data> caseDiscussList = [];
  CaseDiscussModel caseDiscussModel = CaseDiscussModel();
  CaseComments caseComments = CaseComments();
  final int nextPageTrigger = 1;
  List<XFile> imagefiles = [];

  CaseDiscussionBloc() : super(PaginationInitialState()) {
    on<CaseDiscussionLoadPageEvent>(_onGetJobs);
    on<GetCaseDiscussion>(_onGetJobs1);
    on<CaseCommentPageEvent>(_onGetCaseComment);
    on<CaseDiscussEvent>(_onCaseDiscussAction);
    on<AddCaseCommentEvent>(_onAddCaseComment);
    on<AddCaseDataEvent>(_addCaseData);
    on<SelectedFiles>(_SelectedFile);
    on<CaseDiscussionDetailPageEvent>(_onGetCaseDiscussionDetail);
    on<CaseDiscussionCheckIfNeedMoreDataEvent>((event, emit) async {
      // emit(PaginationLoadingState());
      if (event.index == caseDiscussList.length - nextPageTrigger) {
        add(CaseDiscussionLoadPageEvent(page: pageNumber));
      }
    });
  }

  _SelectedFile(SelectedFiles event, Emitter<CaseDiscussionState> emit) async {
    if (event.isRemove) {
      imagefiles.remove(event.pickedfiles);
      emit(PaginationLoadedState());
    } else {
      imagefiles.add(event.pickedfiles);
      // print(imagefiles);
      emit(PaginationLoadedState());
    }
    // emit(DataLoaded(searchPeopleData));
  }

  _onGetJobs(CaseDiscussionLoadPageEvent event,
      Emitter<CaseDiscussionState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    print('search text ${event.searchTerm}');
    print('country id ${event.countryId}');

    if (event.page == 1) {
      print('object clear');
      caseDiscussList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
      print(event.countryId);
      print(event.searchTerm);
    }
    // ProgressDialogUtils.showProgressDialog();
    try {
      var response = await postService.getCaseDiscussList(
          'Bearer ${AppData.userToken}',
          '${pageNumber}',
          event.countryId ?? "1",
          event.searchTerm ?? '');
      numberOfPage = response.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        caseDiscussList.addAll(response.data ?? []);
      }
      emit(PaginationLoadedState());

      // emit(DataLoaded(caseDiscussList));
    } catch (e) {
      print(e);
      // emit(PaginationLoadedState());

      emit(DataError('No Data Found'));
    }
  }

  _onGetCaseDiscussionDetail(CaseDiscussionDetailPageEvent event,
      Emitter<CaseDiscussionState> emit) async {
    emit(PaginationLoadingState());
    // try {
    var response = await postService.getJobsDetails(
        'Bearer ${AppData.userToken}', event.caseId.toString());
    // caseDiscussModel = response;
    emit(PaginationLoadedState());
    // emit(DataLoaded(caseDiscussList));
    // } catch (e) {
    //   print(e);
    //
    //   // emit(PaginationLoadedState());
    //
    //   emit(DataError('No Data Found'));
    // }
  }

  _onGetJobs1(
      GetCaseDiscussion event, Emitter<CaseDiscussionState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    try {
      var response = await postService.getJobsList(
          'Bearer ${AppData.userToken}',
          "1",
          event.countryId,
          event.searchTerm,
          'false');
      print("ddd${response.jobs?.data!.length}");
      caseDiscussList.clear();
      // caseDiscussList.addAll(response.jobs?.data ?? []);
      emit(PaginationLoadedState());
      // emit(DataLoaded(caseDiscussList));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);

      emit(DataError('No Data Found'));
    }
  }

  _addCaseData(
      AddCaseDataEvent event, Emitter<CaseDiscussionState> emit) async {
    ProgressDialogUtils.showProgressDialog();

    _uploadCasePost(event.title, event.description, event.keyword ?? '');
  }
  _onGetCaseComment(
      CaseCommentPageEvent event, Emitter<CaseDiscussionState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    emit(PaginationLoadingState());
    try {
      caseComments = await postService.getCaseDiscussCommentList(
          'Bearer ${AppData.userToken}', event.caseId ?? '');

      emit(PaginationLoadedState());
      // emit(DataLoaded(caseDiscussList));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);

      emit(DataError('No Data Found'));
    }
  }

  _onAddCaseComment(
      AddCaseCommentEvent event, Emitter<CaseDiscussionState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    try {
      var response = await postService.addCommentDiscussCase(
        'Bearer ${AppData.userToken}',
        event.caseId ?? '',
        event.comment ?? '',
      );
      caseComments.comments?.add(Comments(
        id: response.comment?.id.toString(),
        comment: response.comment?.comment,
        likes: 0,
        likedByUser: null,
        createdAt: response.comment?.createdAt,
        name: AppData.name,
        profilePic: AppData.profile_pic,
      ));

      emit(PaginationLoadedState());
      // emit(DataLoaded(caseDiscussList));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);

      emit(DataError('No Data Found'));
    }
  }

  _onCaseDiscussAction(
      CaseDiscussEvent event, Emitter<CaseDiscussionState> emit) async {
    // emit(PaginationInitialState());
    // ProgressDialogUtils.showProgressDialog();

    // emit(PaginationLoadingState());
    try {
      var response = await postService.discussCaseAction(
        'Bearer ${AppData.userToken}',
        event.caseId ?? '',
        event.type ?? '',
        event.actionType ?? '',
      );
      if(event.actionType=='delete'){
        caseComments.comments?.removeWhere((comment)=>comment.id.toString()==event.caseId);
      }
      else if(event.type=='case' && event.actionType=='like'){
       // var message= json.decode(response.data);
       // print(message['message']);
       //  var response = await postService.getCaseDiscussList(
       //      'Bearer ${AppData.userToken}',
       //      '${pageNumber}',
       //      '',
       //      '');
        // caseDiscussList.addAll(response.data ?? []);
    int index=caseDiscussList.indexWhere((caseDiscuss)=>caseDiscuss.caseId.toString()==event.caseId);
    // caseDiscussList.add(data);
    if(!response.data.toString().contains('unliked')) {
      caseDiscussList[index].likes = (caseDiscussList[index].likes ?? 0) + 1;
    }else{
      if( caseDiscussList[index].likes!>0) {
        caseDiscussList[index].likes = (caseDiscussList[index].likes ?? 0) - 1;
      }
    }
      }
      else if(event.type=='case_comment' && event.actionType=='likes'){
       var index= caseComments.comments?.indexWhere((item)=>item.id.toString()==event.caseId);
       (caseComments.comments![index??0].likes??0)+1;
         // caseComments.comments?[index??0]=Comments(likes:caseComments.comments?[index??0].likes??0+1,
         //     likedByUser: caseComments.comments?[index??0].likedByUser,dislikes:caseComments.comments?[index??0].dislikes,
         //     id:caseComments.comments?[index??0].id,
         //     comment: caseComments.comments?[index??0].comment,
         //     actionType:caseComments.comments?[index??0].actionType,
         //     createdAt:caseComments.comments?[index??0].createdAt ,
         //     name:caseComments.comments?[index??0].name ,
         //     profilePic: caseComments.comments?[index??0].profilePic);
      }
      else if(event.type=='case_comment' && event.actionType=='dislikes'){
       var index= caseComments.comments?.indexWhere((item)=>item.id.toString()==event.caseId);
       (caseComments.comments![index??0].dislikes??0)+1;

        // caseComments.comments?[index??0]=Comments(likes:caseComments.comments?[index??0].likes==0?0:caseComments.comments?[index??0].likes??0-1,
         //     likedByUser: caseComments.comments?[index??0].likedByUser,dislikes:caseComments.comments?[index??0].dislikes,
         //     id:caseComments.comments?[index??0].id,
         //     comment: caseComments.comments?[index??0].comment,
         //     actionType:caseComments.comments?[index??0].actionType,
         //     createdAt:caseComments.comments?[index??0].createdAt ,
         //     name:caseComments.comments?[index??0].name ,
         //     profilePic: caseComments.comments?[index??0].profilePic);
      }
      print(response.response.data);
      emit(PaginationLoadedState());
      // emit(DataLoaded(caseDiscussList));
    } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      print(e);

      emit(DataError('No Data Found'));
    }
  }

  Future<void> _uploadCasePost(
      String title, String description, String keyword) async {
    var uri = Uri.parse("${AppData.remoteUrl}/discuss-case");
    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['description'] = description
      ..fields['keyword'] = keyword
      ..headers['Authorization'] =
          'Bearer ${AppData.userToken}'; // Add token bearer header

    for (var xFile in imagefiles) {
      String filePath =
          xFile.path; // Use the path property to get the file path
      String mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      String fileField =
          mimeType.startsWith('image/') ? 'images[]' : 'videos[]';
      File file = File(filePath);

      if (await file.exists()) {
        List<int> bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            bytes,
            filename: basename(filePath),
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else {
        print('File does not exist at path: $filePath');
      }
    }

    ////////////
    try {
      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print(response.body);
      if (response.statusCode == 200) {
        ProgressDialogUtils.hideProgressDialog();
        showToast('Discuss case has been created');
        imagefiles.clear();
        emit(PaginationLoadedState());

        // selectedFiles.clear(); // Clear all selected files
        // _captionController.clear();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //       content: Text('Your post has been posted successfully')),
        // );
        // widget.onBackPressed();
        // Navigator.of(context)
        //     .push(MaterialPageRoute(builder: (BuildContext context) {
        //   return const FeedScreen();
        // }));
        // Clear the text in the text controller
        // showDialog(
        //   context: context,
        //   builder: (context) => AlertDialog(
        //     title: const Text("Upload Complete"),
        //     content: const Text("Your post has been uploaded successfully."),
        //     actions: <Widget>[
        //       TextButton(
        //         child: const Text("OK"),
        //         onPressed: () {
        //           Navigator.of(context).pop(); // Close the dialog
        //         },
        //       ),
        //     ],
        //   ),
        // );
      } else {
        showToast('Discuss case has been created');

        ProgressDialogUtils.hideProgressDialog();
        emit(PaginationLoadedState());
        print(response.body);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Failed to upload post')),
        // );
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: $e')),
      // );
    } finally {
      // setState(() {
      //   _isUploading = false;
      // });
    }
  }
}
