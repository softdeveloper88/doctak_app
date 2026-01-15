import 'dart:io';
import 'dart:typed_data';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

class FileUploadOption extends StatefulWidget {
  ChatBloc searchPeopleBloc;

  FileUploadOption(this.searchPeopleBloc, {super.key});

  @override
  State<FileUploadOption> createState() => _FileUploadOptionState();
}

class _FileUploadOptionState extends State<FileUploadOption> {
  // List<String> list = ['images/socialv/posts/post_one.png', 'images/socialv/posts/post_two.png', 'images/socialv/posts/post_three.png', 'images/socialv/postImage.png'];
  late VideoPlayerController _controller;

  final ImagePicker imgpicker = ImagePicker();
  List<XFile> imagefiles = [];
  Future<void> openImages() async {
    try {
      // Use pickMultipleMedia with requestFullMetadata: false for limited access support
      var pickedfiles = await imgpicker.pickMultipleMedia(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        requestFullMetadata: false, // Critical for limited access
      );

      if (pickedfiles.isNotEmpty) {
        for (var element in pickedfiles) {
          imagefiles.add(element);
          widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: element, isRemove: false));
        }
        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint("No image selected");
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> openVideo() async {
    try {
      var pickedfiles = await imgpicker.pickVideo(source: ImageSource.camera);
      //you can use ImageCourse.camera for Camera capture
      if (pickedfiles != null) {
        // pickedfiles.forEach((element) {
        imagefiles.add(pickedfiles);
        widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
        // });
        // setState(() {
        // });
      } else {
        print(translation(context).msg_no_image_selected);
      }
    } catch (e) {
      print("${translation(context).msg_error_picking_file} $e");
    }
  }

  Future<void> openCamera() async {
    try {
      var pickedfiles = await imgpicker.pickImage(source: ImageSource.camera);
      //you can use ImageCourse.camera for Camera capture
      if (pickedfiles != null) {
        // pickedfiles.forEach((element) {
        imagefiles.add(pickedfiles);
        widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
        // });
        // setState(() {
        // });
      } else {
        print(translation(context).msg_no_image_selected);
      }
    } catch (e) {
      print("${translation(context).msg_error_picking_file} $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: svGetScaffoldColor(),
        borderRadius: radiusOnly(topRight: SVAppContainerRadius, topLeft: SVAppContainerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    openImages();
                  },
                  child: Container(
                    height: 62,
                    width: 52,
                    color: context.cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Image.asset('images/socialv/icons/ic_CameraPost.png', height: 22, width: 22, fit: BoxFit.cover),
                  ),
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is PaginationLoadedState) {
                      return Wrap(
                        children: widget.searchPeopleBloc.imagefiles.map((imageone) {
                          return Stack(
                            children: [
                              Card(
                                child: SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: buildMediaItem(File(imageone.path)),
                                  // child: Image.file(File(imageone.path,),fit: BoxFit.fill,),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {});
                                    imagefiles.remove(imageone);
                                    widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: imageone, isRemove: true));
                                  },
                                  child: const Icon(Icons.remove_circle_outlined, color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                // HorizontalList(
                //   itemCount: list.length,
                //   itemBuilder: (context, index) {
                //     return Image.asset(list[index], height: 62, width: 52, fit: BoxFit.cover);
                //   },
                // )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  openVideo();
                },
                child: Image.asset('images/socialv/icons/ic_Video.png', height: 32, width: 32, fit: BoxFit.cover),
              ),
              GestureDetector(
                onTap: () {
                  openCamera();
                },
                child: Image.asset('images/socialv/icons/ic_CameraPost.png', height: 32, width: 32, fit: BoxFit.cover),
              ),
              // Image.asset('images/socialv/icons/ic_Voice.png', height: 32, width: 32, fit: BoxFit.cover),
              GestureDetector(
                onTap: () {
                  checkInPlaceBottomSheet(context, widget.searchPeopleBloc);
                },
                child: Image.asset('images/socialv/icons/ic_Location.png', height: 32, width: 32, fit: BoxFit.cover),
              ),
              Image.asset('images/socialv/icons/ic_Paper.png', height: 32, width: 32, fit: BoxFit.cover),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMediaItem(File file) {
    final path = file.path;

    if (path.startsWith('content://') ||
        !(path.toLowerCase().endsWith('.jpg') ||
            path.toLowerCase().endsWith('.jpeg') ||
            path.toLowerCase().endsWith('.png') ||
            path.toLowerCase().endsWith('.webp') ||
            path.toLowerCase().endsWith('.gif') ||
            path.toLowerCase().endsWith('.heic'))) {
      return FutureBuilder<List<int>>(
        future: XFile(path).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(color: Colors.grey[200]);
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            );
          }
          return Image.memory(Uint8List.fromList(snapshot.data!), fit: BoxFit.cover);
        },
      );
    }

    if (path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.webp') ||
        path.toLowerCase().endsWith('.gif') ||
        path.toLowerCase().endsWith('.heic')) {
      return Image.file(file, fit: BoxFit.cover);
    } else if (path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov')) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: DisplayVideo(selectedByte: file),
      );
    }

    return Text(translation(context).msg_unsupported_file);
  }
}
