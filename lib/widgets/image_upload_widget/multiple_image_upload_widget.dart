import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  openImages() async {
    try {
      // Enhanced permission handling for different Android versions
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        _permissionDialog(context);
        return;
      }

      var pickedfiles;
      print(widget.imageLimit);
      if (widget.imageLimit == 0 || widget.imageLimit == 1) {
        pickedfiles = await imgpicker.pickMultipleMedia(
          imageQuality: 85, // Optimize for performance
          maxWidth: 1920,
          maxHeight: 1080,
        );
      } else {
        pickedfiles = await imgpicker.pickMultipleMedia(
          limit: widget.imageLimit,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );
      }

      if (pickedfiles != null) {
        for (var element in pickedfiles) {
          if(widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit) {
            widget.imageUploadBloc
                .add(SelectedFiles(pickedfiles: element, isRemove: false));
          }
        }
        setState(() {});
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      _permissionDialog(context);
      print("error while picking file.$e");
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    Permission permission;
    
    // Handle different Android versions
    if (sdkInt >= 33) {
      // Android 13+ (API 33+) - Use granular permissions
      permission = Permission.photos;
    } else if (sdkInt >= 30) {
      // Android 11-12 (API 30-32) - Use external storage with media access
      permission = Permission.storage;
    } else {
      // Android 10 and below (API 29 and below)
      permission = Permission.storage;
    }

    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      return false;
    }

    return false;
  }
  Future<void> _permissionDialog(context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Photo Access Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'DocTak needs access to your photos to upload medical images for AI analysis. Please enable photo permissions in your device settings.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Open Settings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
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
        // Video files are handled directly by the BLoC
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
      // Enhanced permission handling for different Android versions
      bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        _permissionDialog(context);
        return;
      }

      var pickedfiles = await imgpicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (pickedfiles != null) {
        if(widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit) {
          widget.imageUploadBloc
              .add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
          setState(() {});
        }
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      _permissionDialog(context);
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
                          return widget.imageUploadBloc.imagefiles.isNotEmpty
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
                                              widget.imageUploadBloc.add(
                                                  SelectedFiles(
                                                      pickedfiles: imageone,
                                                      isRemove: true));
                                              setState(() {});
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
                if(widget.imageType=="CT Scan" || widget.imageType=="MRI Scan" || widget.imageType=="Mammography")  Text("Please upload one or two of the most relevant images for analysis.",style: TextStyle(fontFamily: 'Poppins',color: Colors.black87,fontWeight: FontWeight.bold),),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300]),
                BlocBuilder<ImageUploadBloc, ImageUploadState>(
                  bloc: widget.imageUploadBloc,
                  builder: (context, state) {
                    bool canAddMore = widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: canAddMore
                              ? [Colors.blue[600]!, Colors.blue[700]!]
                              : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (canAddMore ? Colors.blue : Colors.grey).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: canAddMore ? () {
                        openImages();
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_outlined,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose from Gallery',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    widget.imageLimit > 0 
                                        ? '${widget.imageUploadBloc.imagefiles.length}/${widget.imageLimit} images selected' 
                                        : 'Select medical images from your device',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                BlocBuilder<ImageUploadBloc, ImageUploadState>(
                  bloc: widget.imageUploadBloc,
                  builder: (context, state) {
                    bool canAddMore = widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: canAddMore
                              ? [Colors.teal[600]!, Colors.teal[700]!]
                              : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (canAddMore ? Colors.teal : Colors.grey).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: canAddMore ? () {
                        openCamera();
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Take Photo',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    widget.imageLimit > 0 
                                        ? '${widget.imageUploadBloc.imagefiles.length}/${widget.imageLimit} images selected' 
                                        : 'Capture medical image with camera',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    );
                  },
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
              child: BlocBuilder<ImageUploadBloc, ImageUploadState>(
                bloc: widget.imageUploadBloc,
                builder: (context, state) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: widget.imageUploadBloc.imagefiles.isNotEmpty
                            ? [Colors.blue[600]!, Colors.blue[700]!]
                            : [Colors.grey[300]!, Colors.grey[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: widget.imageUploadBloc.imagefiles.isNotEmpty ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: widget.imageUploadBloc.imagefiles.isNotEmpty ? () => widget.onTap(widget.imageUploadBloc.imagefiles) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.imageUploadBloc.imagefiles.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                widget.imageUploadBloc.imagefiles.isNotEmpty ? 'Continue with Images' : 'Select Images First',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: widget.imageUploadBloc.imagefiles.isNotEmpty ? Colors.white : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
