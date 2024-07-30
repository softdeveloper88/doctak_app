import 'dart:io';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/check_in_search_model/check_in_search_model.dart';
import 'package:doctak_app/data/models/search_user_tag_model/search_user_tag_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

import 'add_post_event.dart';
part 'add_post_state.dart';

class AddPostBloc extends Bloc<AddPostEvent, AddPostState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  List<UserData> searchPeopleData = [];
  List<PlaceData> placeList = [];
  List<UserData> selectedSearchPeopleData = [];

  final int nextPageTrigger = 1;
  String locationName = '';
  String latitude = '';
  String longitude = '';
  List<XFile> imagefiles = [];
  String? feeling = '';
  String backgroundColor = '';
  String title = '';

  AddPostBloc() : super(PaginationInitialState()) {
    on<LoadPageEvent>(_onGetUserInfo);
    on<SelectFriendEvent>(_selectedTagFriend);
    on<PlaceAddEvent>(_checkInSearch);
    on<SelectedFiles>(_SelectedFile);
    on<SelectedLocation>(_selectedLocation);
    on<AddPostDataEvent>(_addPostData);
    on<TextFieldEvent>(_addTitle);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == searchPeopleData.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
  }

  _checkInSearch(PlaceAddEvent event, Emitter<AddPostState> emit) async {
    if (event.page == 1) {
      searchPeopleData.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      CheckInSearchModel response = await postService.checkInSearch(
          'Bearer ${AppData.userToken}',
          '$pageNumber',
          event.name ?? '',
          event.latitude ?? '',
          event.longitude ?? '');
      placeList.clear();
      placeList.addAll(response.data ?? []);
      emit(PaginationLoadedState());
    } catch (e) {
      emit(DataError('No Data Found'));
    }
  }

  _onGetUserInfo(LoadPageEvent event, Emitter<AddPostState> emit) async {
    // emit(DrugsDataInitial());
    print('33 ${event.page}');
    if (event.page == 1) {
      searchPeopleData.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
      print(event.name);
    }
    // ProgressDialogUtils.showProgressDialog();
    // try {
    SearchUserTagModel response = await postService.searchTagFriend(
        'Bearer ${AppData.userToken}', '$pageNumber', event.name ?? '');
    numberOfPage = response.data!.lastPage ?? 0;
    if (pageNumber < numberOfPage + 1) {
      pageNumber = pageNumber + 1;
      searchPeopleData.addAll(response.data!.data ?? []);
    }
    // emit(PaginationLoadedState());
    emit(PaginationLoadedState());

    // emit(DataLoaded(searchPeopleData));
    // } catch (e) {
    //   print(e);
    //
    //   // emit(PaginationLoadedState());
    //
    //   emit(DataError('No Data Found'));
    // }
  }

  _selectedTagFriend(
      SelectFriendEvent event, Emitter<AddPostState> emit) async {
    try {
      if (event.isAdd ?? true) {
        var userInfo = selectedSearchPeopleData
            .where((element) => element.id == event.userData!.id!);
        if (userInfo.isEmpty) {
          selectedSearchPeopleData.add(event.userData!);
        }
      } else {
        selectedSearchPeopleData.remove(event.userData);
      }
      // emit(AddPostDataState(selectedSearchPeopleData,(state as AddPostDataState).name,(state as AddPostDataState).latitude,(state as AddPostDataState).longitude));

      // emit(PaginationLoadedState());
      emit(PaginationLoadedState());

      // emit(DataLoaded(searchPeopleData));
    } catch (e) {
      //   print(e);
      //
      // emit(PaginationLoadedState());
      //
      //   emit(DataError('No Data Found'));
    }
  }

  _selectedLocation(SelectedLocation event, Emitter<AddPostState> emit) async {
    // try {

    locationName = event.name ?? '';
    latitude = event.latitude ?? '';
    longitude = event.longitude ?? '';
    // emit(PaginationLoadedState());
    print(event.name);
    emit(PaginationLoadedState());
    // print('add${(state as PaginationLoadedState).selectTagFriend}');

    // emit(DataLoaded(searchPeopleData));
  }

  _SelectedFile(SelectedFiles event, Emitter<AddPostState> emit) async {
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

  _addPostData(AddPostDataEvent event, Emitter<AddPostState> emit) async {
    print('object $state');
    // if (state is PaginationLoadedState) {

    // emit(PaginationLoadedState(
    //     (state as PaginationLoadedState).selectTagFriend,
    //     (state as PaginationLoadedState).name,
    //     (state as PaginationLoadedState).latitude,
    //     (state as PaginationLoadedState).longitude));
    // List<MultipartFile> imageFiles = [];
    // imageFiles.add(
    //   await MultipartFile.fromFile('/data/user/0/com.kt.doctak/cache/7f8232ed-be18-4de3-ac18-86fdf0dc13ce1049105523341482043.jpg', filename: '7f8232ed-be18-4de3-ac18-86fdf0dc13ce1049105523341482043.png'),
    // );
    print(feeling);
    List<Map<String, String>> tagFriends = [];

    // Loop to add data
    for (var element in selectedSearchPeopleData) {
      tagFriends.add({'id': element.id.toString()});
    }
    ProgressDialogUtils.showProgressDialog();
    print(tagFriends.toString());

    _uploadPost(title, locationName, latitude, longitude, backgroundColor,
        tagFriends.toString(), feeling ?? '');
  }

  _addTitle(TextFieldEvent event, Emitter<AddPostState> emit) async {
    print('object $state');
    // if (state is PaginationLoadedState) {
    title = event.text;
    emit(PaginationLoadedState());
    // emit(PaginationLoadedState(
    //     (state as PaginationLoadedState).selectTagFriend,
    //     (state as PaginationLoadedState).name,
    //     (state as PaginationLoadedState).latitude,
    //     (state as PaginationLoadedState).longitude));
    // List<MultipartFile> imageFiles = [];
    // imageFiles.add(
    //   await MultipartFile.fromFile('/data/user/0/com.kt.doctak/cache/7f8232ed-be18-4de3-ac18-86fdf0dc13ce1049105523341482043.jpg', filename: '7f8232ed-be18-4de3-ac18-86fdf0dc13ce1049105523341482043.png'),
    // );
  }

  Future<void> _uploadPost(
      String title,
      String locationName,
      String lat,
      String lng,
      String backgroundColor,
      String tagging,
      String feeling) async {
    var uri = Uri.parse("${AppData.remoteUrl}/new_post");
    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['location_name'] = locationName
      ..fields['lat'] = latitude
      ..fields['lng'] = longitude
      ..fields['background_color'] = backgroundColor
      ..fields['tagging'] = tagging
      ..fields['feeling'] = feeling
      ..headers['Authorization'] =
          'Bearer ${AppData.userToken}'; // Add token bearer header

    print(
        '$title,$locationName,$latitude,$longitude,$backgroundColor,$tagging,$feeling');
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
      print('hiii${response.body}');
      if (response.statusCode == 200) {
        ProgressDialogUtils.hideProgressDialog();
        // emit(ResponseLoadedState(response.body));
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
        // ProgressDialogUtils.hideProgressDialog();
        // emit(ResponseLoadedState(response.body));

        print(response.statusCode);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Failed to upload post')),
        // );
      }
      emit(ResponseLoadedState(response.body));

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

// _setUserFollow(SetUserFollow event, Emitter<AddPostState> emit) async {
//   // emit(DrugsDataInitial());
//   // ProgressDialogUtils.showProgressDialog();
//   try {
//     emit(PaginationLoadedState());
//   } catch (e) {
//     print(e);
//
//     emit(DataError('No Data Found'));
//   }
// }
// _onGetUserInfo1(GetPost event, Emitter<AddPostState> emit) async {
//   // emit(PaginationInitialState());
//   // ProgressDialogUtils.showProgressDialog();
//
//   // emit(PaginationLoadingState());
//   try {
//     SearchUserTagModel response = await postService.getSearchPeople(
//       'Bearer ${AppData.userToken}',
//       "1",
//       '',
//     );
//     print("ddd${response.data!.length}");
//     searchPeopleData.clear();
//     searchPeopleData.addAll(response.data ?? []);
//     emit(PaginationLoadedState());
//     // emit(DataLoaded(searchPeopleData));
//   } catch (e) {
//     // ProgressDialogUtils.hideProgressDialog();
//     print(e);
//     emit(DataError('No Data Found'));
//   }
// }
}
