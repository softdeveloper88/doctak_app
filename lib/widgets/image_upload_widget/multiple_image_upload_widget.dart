import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import 'bloc/image_upload_event.dart';

class MultipleImageUploadWidget extends StatefulWidget {
  ImageUploadBloc imageUploadBloc;
  Function(List<XFile>) onTap;
  int imageLimit;

  MultipleImageUploadWidget(this.imageUploadBloc, this.onTap,
      {this.imageLimit = 0, super.key});

  @override
  State<MultipleImageUploadWidget> createState() =>
      _MultipleImageUploadWidgetState();
}

class _MultipleImageUploadWidgetState extends State<MultipleImageUploadWidget> {
  // List<String> list = ['images/socialv/posts/post_one.png', 'images/socialv/posts/post_two.png', 'images/socialv/posts/post_three.png', 'images/socialv/postImage.png'];
  late VideoPlayerController _controller;

  final ImagePicker imgpicker = ImagePicker();
  List<XFile> imagefiles = [];
  int i=0;
  openImages() async {
    try {

      var pickedfiles;
      print(widget.imageLimit);
      if (widget.imageLimit == 0 || widget.imageLimit == 1) {
        pickedfiles = await imgpicker.pickMultipleMedia();
      } else {
        pickedfiles = await imgpicker.pickMultipleMedia(limit: widget.imageLimit);
      }

      if (pickedfiles != null) {

        for (var element in pickedfiles) {
          if(i<widget.imageLimit && widget.imageUploadBloc.imagefiles.length+1<=widget.imageLimit) {
            i++;
            setState(() {});
            imagefiles.add(element);
            widget.imageUploadBloc
                .add(SelectedFiles(pickedfiles: element, isRemove: false));
          }
        }
        i=0;
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
        widget.imageUploadBloc
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

        widget.imageUploadBloc
            .add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
        // });
        setState(() {});
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
                BlocBuilder<ImageUploadBloc, ImageUploadState>(
                    bloc: widget.imageUploadBloc,
                    builder: (context, state) {
                      if (state is FileLoadedState) {
                        return imagefiles != []
                            ? Wrap(
                                children: widget.imageUploadBloc.imagefiles
                                    .map((imageone) {
                                  return Stack(children: [
                                    Card(
                                      child: SizedBox(
                                        height: 60, width: 60,
                                        child:
                                            buildMediaItem(File(imageone.path)),
                                        // child: Image.file(File(imageone.path,),fit: BoxFit.fill,),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                          onTap: () {
                                            setState(() {});
                                            imagefiles.remove(imageone);

                                            widget.imageUploadBloc.add(
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
                  if (widget.imageLimit == 0) {
                    openImages();
                  } else {
                    if (widget.imageUploadBloc.imagefiles.length + 1 <= widget.imageLimit) {
                      openImages();
                    }
                  }
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
                      style: GoogleFonts.poppins(
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
              // GestureDetector(
              //   onTap: () {
              //     openVideo();
              //   },
              //   child: Row(
              //     children: <Widget>[
              //       Image.asset('images/socialv/icons/ic_Video.png',
              //           color: svGetBodyColor(),
              //           height: 32,
              //           width: 32,
              //           fit: BoxFit.cover),
              //       const SizedBox(
              //         width: 10,
              //       ),
              //       Text(
              //         'Take Video',
              //         style: GoogleFonts.poppins(
              //             fontWeight: FontWeight.w500,
              //             color: svGetBodyColor(),
              //             fontSize: kDefaultFontSize),
              //       )
              //     ],
              //   ),
              // ),
              // Divider(
              //   color: Colors.grey[300],
              // ),

              GestureDetector(
                onTap: () {
                  if (widget.imageLimit == 0) {
                    print("zero ${widget.imageLimit}");
                    openCamera();
                  } else if (widget.imageUploadBloc.imagefiles.length + 1 <=
                      widget.imageLimit) {
                    print(
                        "not zero ${widget.imageLimit} ${widget.imageUploadBloc.imagefiles.length}");

                    openCamera();
                  }
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
                      style: GoogleFonts.poppins(
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
              //       checkInPlaceBottomSheet(context, widget.imageUploadBloc);
              //     },
              //     child: Image.asset('images/socialv/icons/ic_Location.png',
              //         height: 32, width: 32, fit: BoxFit.cover)),
              // Image.asset('images/socialv/icons/ic_Paper.png',
              //     height: 32, width: 32, fit: BoxFit.cover),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: svAppButton(
              context: context,
              // style: svAppButton(text: text, onTap: onTap, context: context),
              onTap: () => widget.onTap(imagefiles),
              text: 'Next',
            ),
          ),
        ],
      ),
    );
  }
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
