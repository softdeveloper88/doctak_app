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
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

import 'bloc/image_upload_event.dart';

class MultipleImageUploadWidget extends StatefulWidget {
  ImageUploadBloc imageUploadBloc;
  Function(List<XFile>) onTap;
  int imageLimit;
  String? imageType;

  MultipleImageUploadWidget(this.imageUploadBloc, this.onTap,
      {this.imageType,this.imageLimit = 0, super.key});

  @override
  State<MultipleImageUploadWidget> createState() =>
      _MultipleImageUploadWidgetState();
}

class _MultipleImageUploadWidgetState extends State<MultipleImageUploadWidget> {
  // List<String> list = ['images/socialv/posts/post_one.png', 'images/socialv/posts/post_two.png', 'images/socialv/posts/post_three.png', 'images/socialv/postImage.png'];
  late VideoPlayerController _controller;
  int selectTab=0;
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
      _permissionDialog(context);
      print("error while picking file.$e");
    }
  }
  Future<void> _permissionDialog(context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // <-- SEE HERE
          title: Text(
            'You want to enable permission?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14.sp),
          ),
          // content: const SingleChildScrollView(
          //   child: ListBody(
          // //     children: <Widget>[
          // //       Text('Are you sure want to enable permission?'),
          // //     ],
          //   ),
          // ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
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
                if(widget.imageType=="CT Scan" || widget.imageType=="MRI Scan" || widget.imageType=="Mammography")  Text("Please upload one or two of the most relevant images for analysis.",style: GoogleFonts.poppins(color: Colors.black87,fontWeight: FontWeight.bold),),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300]),
                MaterialButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.black, width: 1.0),
                  ),
                  color: imagefiles.isEmpty?Colors.blue:Colors.blueGrey[200],
                  onPressed: () {

                    if (widget.imageLimit == 0) {
                      openImages();
                    } else {
                      if (widget.imageUploadBloc.imagefiles.length + 1 <= widget.imageLimit) {
                        openImages();
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'From Gallery',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontSize: kDefaultFontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                MaterialButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: const BorderSide(color: Colors.black, width: 1.0),
                  ),
                  color:imagefiles.isEmpty?Colors.blue:Colors.blueGrey[200],
                  onPressed: () {

                    if (widget.imageLimit == 0) {
                      openCamera();
                    } else if (widget.imageUploadBloc.imagefiles.length + 1 <= widget.imageLimit) {
                      openCamera();
                    }
                  },
                  // borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.asset(
                          'images/socialv/icons/ic_CameraPost.png',
                          color: Colors.white,
                          height: 32,
                          width: 32,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Take Picture',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontSize: kDefaultFontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300]),
              ],
            )
            ,
            const SizedBox(
              height: 16,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: svAppButton(
                color: imagefiles.isNotEmpty?Colors.blue:Colors.blueGrey[200],
                context: context,
                // style: svAppButton(text: text, onTap: onTap, context: context),
                onTap: () => widget.onTap(imagefiles),
                text: 'Next',
              ),
            ),
          ],
        ),
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
