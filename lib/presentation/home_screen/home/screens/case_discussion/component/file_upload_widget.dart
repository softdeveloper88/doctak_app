import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import '../bloc/case_discussion_event.dart';

class FileUploadWidget extends StatefulWidget {
  CaseDiscussionBloc caseDiscussionBloc;

  FileUploadWidget(this.caseDiscussionBloc, {super.key});

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  // List<String> list = ['images/socialv/posts/post_one.png', 'images/socialv/posts/post_two.png', 'images/socialv/posts/post_three.png', 'images/socialv/postImage.png'];
  late VideoPlayerController _controller;

  final ImagePicker imgpicker = ImagePicker();
  List<XFile> imagefiles = [];
  openImages() async {
    try {
      var pickedfiles = await imgpicker.pickMultipleMedia();
      if (pickedfiles != null) {
        for (var element in pickedfiles) {
          imagefiles.add(element);
          widget.caseDiscussionBloc.add(SelectedFiles(pickedfiles: element, isRemove: false));
        }
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
        widget.caseDiscussionBloc
            .add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
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
        widget.caseDiscussionBloc
            .add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
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
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                BlocBuilder<CaseDiscussionBloc, CaseDiscussionState>(
                  bloc: widget.caseDiscussionBloc,
                    builder: (context, state) {
                      if (state is PaginationLoadedState) {
                        return imagefiles != null
                            ? Wrap(
                          children: widget.caseDiscussionBloc.imagefiles
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
                                      widget.caseDiscussionBloc.add(
                                          SelectedFiles(
                                              pickedfiles: imageone,
                                              isRemove: true));
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
          const SizedBox(
            height: 16,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  openImages();
                },
                child: Row(
                  children: [
                    SizedBox(
                      height: 32,
                      width: 32,
                      // color: context.cardColor,
                      child: Icon(
                        Icons.image_outlined, size: 32, color: svGetBodyColor(),
                        // Image.asset('images/socialv/icons/ic_CameraPost.png',
                        //     height: 22, width: 22, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'From Gallery',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: svGetBodyColor(),
                          fontSize: kDefaultFontSize),
                    )
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[300],
              ),
              GestureDetector(
                onTap: () {
                  openVideo();
                },
                child: Row(
                  children: <Widget>[
                    Image.asset('images/socialv/icons/ic_Video.png',
                        color: svGetBodyColor(),
                        height: 32,
                        width: 32,
                        fit: BoxFit.cover),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Take Video',
                      style:  TextStyle(fontFamily: 'Poppins-Light',
                          fontWeight: FontWeight.w500,
                          color: svGetBodyColor(),
                          fontSize: kDefaultFontSize),
                    )
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[300],
              ),

              GestureDetector(
                onTap: () {
                  openCamera();
                },
                child: Row(
                  children: [
                    Image.asset('images/socialv/icons/ic_CameraPost.png',
                        color: svGetBodyColor(),
                        height: 32,
                        width: 32,
                        fit: BoxFit.cover),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Take Picture',
                      style:  TextStyle(fontFamily: 'Poppins-Light',
                          fontWeight: FontWeight.w500,
                          color: svGetBodyColor(),
                          fontSize: kDefaultFontSize),
                    )
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[300],
              ),

              // Image.asset('images/socialv/icons/ic_Voice.png', height: 32, width: 32, fit: BoxFit.cover),
              // GestureDetector(
              //     onTap: () {
              //       checkInPlaceBottomSheet(context, widget.caseDiscussionBloc);
              //     },
              //     child: Image.asset('images/socialv/icons/ic_Location.png',
              //         height: 32, width: 32, fit: BoxFit.cover)),
              // Image.asset('images/socialv/icons/ic_Paper.png',
              //     height: 32, width: 32, fit: BoxFit.cover),
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
