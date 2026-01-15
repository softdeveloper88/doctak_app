import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
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
  final ApiServiceManager apiManager = ApiServiceManager();
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
    on<RestoreFilesEvent>((event, emit) => emit(PaginationLoadedState()));
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == searchPeopleData.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });

    // Attempt to load persisted selected files
    _loadPersistedFiles();
  }

  // Persist selected image file paths to cache to survive lifecycle events
  Future<File> _persistenceFile() async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/doctak_addpost_selected_files.json');
  }

  Future<void> _loadPersistedFiles() async {
    try {
      final file = await _persistenceFile();
      print('AddPostBloc: Checking persistence file at ${file.path}');
      if (await file.exists()) {
        print('AddPostBloc: Persistence file exists');
        final contents = await file.readAsString();
        print('AddPostBloc: Raw persisted contents: $contents');
        final List<dynamic> paths = json.decode(contents);
        imagefiles.clear();
        for (var p in paths) {
          try {
            final xf = XFile(p.toString());
            imagefiles.add(xf);
            print('AddPostBloc: Restored file path: ${xf.path}');
          } catch (ex) {
            print('AddPostBloc: Failed to restore path $p: $ex');
            // ignore invalid entries
          }
        }
        print('AddPostBloc: Total restored files: ${imagefiles.length}');
        if (imagefiles.isNotEmpty) add(RestoreFilesEvent());
      } else {
        print('AddPostBloc: Persistence file does not exist');
      }
    } catch (e) {
      print('AddPostBloc: Error loading persisted files: $e');
    }
  }

  Future<void> _persistFiles() async {
    try {
      final file = await _persistenceFile();
      final paths = imagefiles.map((e) => e.path).toList();
      print('AddPostBloc: Persisting ${paths.length} files to ${file.path}');
      print('AddPostBloc: Persist paths: $paths');
      await file.writeAsString(json.encode(paths));
    } catch (e) {
      print('AddPostBloc: Error persisting files: $e');
    }
  }

  /// Public API to force reloading persisted files (call on app resume)
  Future<void> restorePersistedFiles() async {
    await _loadPersistedFiles();
  }

  Future<void> _checkInSearch(PlaceAddEvent event, Emitter<AddPostState> emit) async {
    if (event.page == 1) {
      searchPeopleData.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      CheckInSearchModel response = await apiManager.checkInSearch('Bearer ${AppData.userToken}', '$pageNumber', event.name ?? '', event.latitude ?? '', event.longitude ?? '');
      placeList.clear();
      placeList.addAll(response.data ?? []);
      emit(PaginationLoadedState());
    } catch (e) {
      emit(DataError('No Data Found'));
    }
  }

  Future<void> _onGetUserInfo(LoadPageEvent event, Emitter<AddPostState> emit) async {
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
    SearchUserTagModel response = await apiManager.searchTagFriend('Bearer ${AppData.userToken}', '$pageNumber', event.name ?? '');
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

  Future<void> _selectedTagFriend(SelectFriendEvent event, Emitter<AddPostState> emit) async {
    try {
      if (event.isAdd ?? true) {
        var userInfo = selectedSearchPeopleData.where((element) => element.id == event.userData!.id!);
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

  Future<void> _selectedLocation(SelectedLocation event, Emitter<AddPostState> emit) async {
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

  Future<void> _SelectedFile(SelectedFiles event, Emitter<AddPostState> emit) async {
    if (event.isRemove) {
      print('AddPostBloc: Removing image ${event.pickedfiles.path}');
      // Try to remove the file object matching the path
      imagefiles.removeWhere((x) => x.path == event.pickedfiles.path);
      // Also attempt to delete the backing file if it exists in app cache
      try {
        final f = File(event.pickedfiles.path);
        if (await f.exists()) {
          await f.delete();
          print('AddPostBloc: Deleted persisted file at ${f.path}');
        }
      } catch (ex) {
        print('AddPostBloc: Failed to delete persisted file: $ex');
      }
      print('AddPostBloc: Now have ${imagefiles.length} images after removal');
      emit(PaginationLoadedState());
      print('AddPostBloc: Emitted PaginationLoadedState after removal');
      await _persistFiles();
    } else {
      print('AddPostBloc: Adding image ${event.pickedfiles.path}');
      try {
        // Copy the picked file into app temporary directory to ensure we have
        // a stable, readable path across lifecycle and limited storage access.
        final dir = await getTemporaryDirectory();
        final srcPath = event.pickedfiles.path;
        final name = basename(srcPath);
        final targetPath = '${dir.path}/doctak_addpost_${DateTime.now().millisecondsSinceEpoch}_$name';

        // Attempt direct file copy; if source isn't a regular file, fall back to bytes
        final srcFile = File(srcPath);
        if (await srcFile.exists()) {
          await srcFile.copy(targetPath);
          print('AddPostBloc: Copied file to $targetPath');
        } else {
          // Some platforms return URIs that aren't directly addressable as files.
          // Use XFile.readAsBytes() to obtain data and write to target.
          try {
            final bytes = await event.pickedfiles.readAsBytes();
            final targetFile = File(targetPath);
            await targetFile.writeAsBytes(bytes);
            print('AddPostBloc: Wrote bytes to $targetPath');
          } catch (ex) {
            print('AddPostBloc: Failed to copy picked file bytes: $ex');
          }
        }

        final newXf = XFile(targetPath);
        imagefiles.add(newXf);
        print('AddPostBloc: Now have ${imagefiles.length} images after addition');
        print('AddPostBloc: Emitting PaginationLoadedState');
        emit(PaginationLoadedState());
        print('AddPostBloc: PaginationLoadedState emitted successfully');
        await _persistFiles();
      } catch (e) {
        print('AddPostBloc: Error while handling picked file: $e');
      }
    }
  }

  Future<void> _addPostData(AddPostDataEvent event, Emitter<AddPostState> emit) async {
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

    await _uploadPost(title, locationName, latitude, longitude, backgroundColor, tagFriends.toString(), feeling ?? '', emit);
  }

  Future<void> _addTitle(TextFieldEvent event, Emitter<AddPostState> emit) async {
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

  Future<void> _uploadPost(String title, String locationName, String lat, String lng, String backgroundColor, String tagging, String feeling, Emitter<AddPostState> emit) async {
    var uri = Uri.parse("${AppData.remoteUrl}/new_post");
    var request = http.MultipartRequest('POST', uri)
      ..fields['title'] = title
      ..fields['location_name'] = locationName
      ..fields['lat'] = latitude
      ..fields['lng'] = longitude
      ..fields['background_color'] = backgroundColor
      ..fields['tagging'] = tagging
      ..fields['feeling'] = feeling
      ..headers['Authorization'] = 'Bearer ${AppData.userToken}'; // Add token bearer header

    print('$title,$locationName,$latitude,$longitude,$backgroundColor,$tagging,$feeling');
    for (var xFile in imagefiles) {
      String filePath = xFile.path; // Use the path property to get the file path
      String mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      String fileField = mimeType.startsWith('image/') ? 'images[]' : 'videos[]';

      File file = File(filePath);

      if (await file.exists()) {
        List<int> bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: basename(filePath), contentType: MediaType.parse(mimeType)));
      } else {
        print('File does not exist at path: $filePath');
      }
    }

    ////////////
    try {
      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('hiii${response.body}');

      // Always hide progress dialog after getting response (success or failure)
      ProgressDialogUtils.hideProgressDialog();

      if (response.statusCode == 200) {
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
        print(response.statusCode);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Failed to upload post')),
        // );
      }
      emit(ResponseLoadedState(response.body));
    } catch (e) {
      // Ensure dialog is hidden on exception too
      ProgressDialogUtils.hideProgressDialog();
      print('Error uploading post: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: $e')),
      // );
      emit(DataError('Error uploading post: $e'));
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
  //     SearchUserTagModel response = await apiManager.getSearchPeople(
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
