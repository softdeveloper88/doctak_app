import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:doctak_app/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';

import '../../../../../main.dart';

class SVPostOptionsComponent extends StatefulWidget {
  AddPostBloc searchPeopleBloc;

  SVPostOptionsComponent(this.searchPeopleBloc, {super.key});

  @override
  State<SVPostOptionsComponent> createState() => _SVPostOptionsComponentState();
}

class _SVPostOptionsComponentState extends State<SVPostOptionsComponent> {

  final ImagePicker imgpicker = ImagePicker();
  List<XFile> imagefiles = [];
  openImages() async {
    try {
      var pickedfiles = await imgpicker.pickMultipleMedia();
      //you can use ImageCourse.camera for Camera capture
      if (pickedfiles != null) {
        for (var element in pickedfiles) {
          imagefiles.add(element);
          widget.searchPeopleBloc
              .add(SelectedFiles(pickedfiles: element, isRemove: false));
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
        widget.searchPeopleBloc
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
        widget.searchPeopleBloc.add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: appStore.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Media Preview - More compact
          BlocBuilder<AddPostBloc, AddPostState>(
            bloc: widget.searchPeopleBloc,
            builder: (context, state) {
              if (state is PaginationLoadedState &&
                  widget.searchPeopleBloc.imagefiles.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.searchPeopleBloc.imagefiles.map((imageone) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: Stack(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: buildMediaItem(File(imageone.path)),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {});
                                    imagefiles.remove(imageone);
                                    widget.searchPeopleBloc.add(
                                      SelectedFiles(
                                        pickedfiles: imageone,
                                        isRemove: true,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          // Media Options - More compact
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Gallery Option
                InkWell(
                  onTap: () => openImages(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation(context).lbl_from_gallery,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Choose photos or videos',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Divider(
                  color: Colors.grey.withOpacity(0.2),
                  indent: 48,
                  height: 1,
                ),
                const SizedBox(height: 2),
                // Video Option
                InkWell(
                  onTap: () => openVideo(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.videocam_outlined,
                            size: 18,
                            color: Colors.purple[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation(context).lbl_take_video,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Record a new video',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Divider(
                  color: Colors.grey.withOpacity(0.2),
                  indent: 48,
                  height: 1,
                ),
                const SizedBox(height: 2),
                // Camera Option
                InkWell(
                  onTap: () => openCamera(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation(context).lbl_take_picture,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Capture a new photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    }
    else if (file.path.endsWith('.mp4') || file.path.endsWith('.mov')) {
      // Display video
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: DisplayVideo(
          selectedByte: file,
        ),
      );
    }
    else {
      // Handle other types of files
      return Text(translation(context).msg_unsupported_file);
    }
  }
}
