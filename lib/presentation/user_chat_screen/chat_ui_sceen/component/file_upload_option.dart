import 'dart:io';

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
  openImages() async {
    try {
      var pickedfiles = await imgpicker.pickMultipleMedia();
      //you can use ImageCourse.camera for Camera capture
      if (pickedfiles != null) {
        pickedfiles.forEach((element) {
          imagefiles.add(element);
          widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: element,isRemove: false));
        });
        setState(() {});
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("error while picking file.");
    }
  }
  openVideo() async {
    try {
      var pickedfiles = await imgpicker.pickVideo(source: ImageSource.camera);
      //you can use ImageCourse.camera for Camera capture
      if (pickedfiles != null) {
        // pickedfiles.forEach((element) {
        imagefiles.add(pickedfiles);
        widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: pickedfiles,isRemove: false));
        // });
        // setState(() {
        // });
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("error while picking file.$e");
    }
  }
  openCamera() async {
    try {
      var pickedfiles = await imgpicker.pickImage(source: ImageSource.camera);
      //you can use ImageCourse.camera for Camera capture
      if (pickedfiles != null) {
        // pickedfiles.forEach((element) {
        imagefiles.add(pickedfiles);
        widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: pickedfiles,isRemove: false));
        // });
        // setState(() {
        // });
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("error while picking file. $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: svGetScaffoldColor(),
        borderRadius: radiusOnly(
            topRight: SVAppContainerRadius, topLeft: SVAppContainerRadius),
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Image.asset('images/socialv/icons/ic_CameraPost.png',
                        height: 22, width: 22, fit: BoxFit.cover),
                  ),
                ),
                BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is PaginationLoadedState) {
                        return imagefiles != null
                            ? Wrap(
                          children: widget.searchPeopleBloc.imagefiles
                              .map((imageone) {
                            return Stack(children: [
                              Card(
                                child: SizedBox(
                                  height: 60, width: 60,
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
                                      widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: imageone,isRemove: true));

                                    },
                                    child: const Icon(
                                      Icons.remove_circle_outlined,
                                      color: Colors.red,
                                    )),
                              )
                            ]);
                          }).toList(),
                        )
                            : Container();
                      } else {
                        return Container();
                      }
                    }),
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
                  child: Image.asset('images/socialv/icons/ic_Video.png',
                      height: 32, width: 32, fit: BoxFit.cover)),
              GestureDetector(
                  onTap: () {
                    openCamera();
                  },
                  child: Image.asset('images/socialv/icons/ic_CameraPost.png',
                      height: 32, width: 32, fit: BoxFit.cover)),
              // Image.asset('images/socialv/icons/ic_Voice.png', height: 32, width: 32, fit: BoxFit.cover),
              GestureDetector(
                  onTap: () {
                    checkInPlaceBottomSheet(context, widget.searchPeopleBloc);
                  },
                  child: Image.asset('images/socialv/icons/ic_Location.png',
                      height: 32, width: 32, fit: BoxFit.cover)),
              Image.asset('images/socialv/icons/ic_Paper.png',
                  height: 32, width: 32, fit: BoxFit.cover),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMediaItem(File file) {
    if (file.path.endsWith('.jpg') ||
        file.path.endsWith('.jpeg') ||
        file.path.endsWith('.png')) {
      // Display image
      return Image.file(
        file,
        fit: BoxFit.cover,
      );
    } else if (file.path.endsWith('.mp4') || file.path.endsWith('.mov')) {
      // Display video
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: DisplayVideo(
          selectedByte: file,
        ),
      );
    } else {
      // Handle other types of files
      return const Text('Unsupported file type');
    }
  }

}
