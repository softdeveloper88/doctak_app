import 'dart:io';
import 'dart:typed_data';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/robust_image_picker.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import 'bloc/image_upload_event.dart';

class MultipleImageUploadWidget extends StatefulWidget {
  final ImageUploadBloc imageUploadBloc;
  final Function(List<XFile>) onTap;
  final int imageLimit;
  final String? imageType;
  // When true, the gallery picker opens automatically once the widget appears
  final bool autoOpenGallery;

  const MultipleImageUploadWidget(this.imageUploadBloc, this.onTap, {this.imageType, this.imageLimit = 0, this.autoOpenGallery = false, super.key});

  @override
  State<MultipleImageUploadWidget> createState() => _MultipleImageUploadWidgetState();
}

class _MultipleImageUploadWidgetState extends State<MultipleImageUploadWidget> {
  // List<String> list = ['images/socialv/posts/post_one.png', 'images/socialv/posts/post_two.png', 'images/socialv/posts/post_three.png', 'images/socialv/postImage.png'];
  int selectTab = 0;
  final ImagePicker imgpicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Optionally auto-open gallery (used for X-Ray flow per request)
    if (widget.autoOpenGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          // Only open if user can add more images according to imageLimit
          final canAddMore = widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit;
          if (canAddMore) {
            openImages();
          }
        });
      });
    }
  }

  Future<void> openImages() async {
    debugPrint('MultiWidget: *** OPENING GALLERY with RobustImagePicker ***');
    try {
      List<XFile> pickedfiles = [];
      debugPrint('MultiWidget: Image limit: ${widget.imageLimit}');

      // Use RobustImagePicker which handles limited access + has photo_manager fallback
      try {
        debugPrint('MultiWidget: Using RobustImagePicker.showPhotoManagerPicker...');
        pickedfiles = await RobustImagePicker.showPhotoManagerPicker(context, limit: widget.imageLimit > 0 ? widget.imageLimit : null, title: 'Select Photos');
        debugPrint('MultiWidget: showPhotoManagerPicker returned ${pickedfiles.length} files');
      } catch (e) {
        debugPrint('MultiWidget: showPhotoManagerPicker failed: $e, trying fallback...');

        // Fallback to standard RobustImagePicker
        try {
          pickedfiles = await RobustImagePicker.pickMultipleImages(limit: widget.imageLimit > 0 ? widget.imageLimit : null);
          debugPrint('MultiWidget: Fallback pickMultipleImages returned ${pickedfiles.length} files');
        } catch (e2) {
          debugPrint('MultiWidget: All pickers failed: $e2');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open gallery: ${e2.toString()}'),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          return;
        }
      }

      debugPrint('MultiWidget: Picker returned: ${pickedfiles.length} files');
      if (pickedfiles.isNotEmpty) {
        debugPrint('MultiWidget: First file path: ${pickedfiles.first.path}');
      }

      if (pickedfiles.isNotEmpty) {
        debugPrint('Gallery: Selected ${pickedfiles.length} files from gallery');
        for (var element in pickedfiles) {
          if (widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit) {
            debugPrint('Gallery: Adding image ${element.path} to BLoC');
            widget.imageUploadBloc.add(SelectedFiles(pickedfiles: element, isRemove: false));
            debugPrint('Gallery: BLoC now has ${widget.imageUploadBloc.imagefiles.length} images');
          }
        }
        debugPrint('Gallery: Calling setState');
        setState(() {});
      } else {
        debugPrint("No image is selected (user may have cancelled).");
      }
    } catch (e) {
      debugPrint('MultiWidget: ERROR in openImages: $e');
      debugPrint('MultiWidget: Error stack trace:');
      debugPrint(StackTrace.current.toString());
      // Show generic error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> openVideo() async {
    try {
      // Check camera and microphone permissions
      final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(context);
      if (!cameraGranted) {
        return;
      }

      final microphoneGranted = await PermissionUtils.ensureMicrophonePermission();
      if (!microphoneGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone access is required for video recording.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      var pickedfiles = await imgpicker.pickVideo(source: ImageSource.camera);
      if (pickedfiles != null) {
        widget.imageUploadBloc.add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
      } else {
        debugPrint("No video is selected.");
      }
    } catch (e) {
      debugPrint("Error while picking video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error recording video. Please try again.', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> openCamera() async {
    try {
      // Use the professional camera permission handler
      final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(context);
      if (!cameraGranted) {
        return;
      }

      var pickedfiles = await imgpicker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1920, maxHeight: 1080);

      if (pickedfiles != null) {
        if (widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit) {
          widget.imageUploadBloc.add(SelectedFiles(pickedfiles: pickedfiles, isRemove: false));
          setState(() {});
        }
      } else {
        debugPrint("No image is selected.");
      }
    } catch (e) {
      debugPrint("Error while taking photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error taking photo. Please try again.', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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
                                children: widget.imageUploadBloc.imagefiles.map((imageone) {
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
                                            widget.imageUploadBloc.add(SelectedFiles(pickedfiles: imageone, isRemove: true));
                                            setState(() {});
                                          },
                                          child: const Icon(Icons.remove_circle_outlined, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              )
                            : Container();
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
            const SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageType == "CT Scan" || widget.imageType == "MRI Scan" || widget.imageType == "Mammography")
                  const Text(
                    "Please upload one or two of the most relevant images for analysis.",
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
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
                          colors: canAddMore ? [Colors.blue[600]!, Colors.blue[700]!] : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: (canAddMore ? Colors.blue : Colors.grey).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: canAddMore
                              ? () {
                                  openImages();
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.photo_library_outlined, size: 24, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Choose from Gallery',
                                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                                      ),
                                      Text(
                                        widget.imageLimit > 0 ? '${widget.imageUploadBloc.imagefiles.length}/${widget.imageLimit} images selected' : 'Select medical images from your device',
                                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.8), size: 16),
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
                          colors: canAddMore ? [Colors.teal[600]!, Colors.teal[700]!] : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: (canAddMore ? Colors.teal : Colors.grey).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: canAddMore
                              ? () {
                                  openCamera();
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_outlined, size: 24, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Take Photo',
                                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                                      ),
                                      Text(
                                        widget.imageLimit > 0 ? '${widget.imageUploadBloc.imagefiles.length}/${widget.imageLimit} images selected' : 'Capture medical image with camera',
                                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.8), size: 16),
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
            ),
            const SizedBox(height: 16),
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
                        colors: widget.imageUploadBloc.imagefiles.isNotEmpty ? [Colors.blue[600]!, Colors.blue[700]!] : [Colors.grey[300]!, Colors.grey[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: widget.imageUploadBloc.imagefiles.isNotEmpty ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
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
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
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
  final path = file.path;

  // If path looks like a content URI (Android limited access), load bytes via XFile
  if (path.startsWith('content://') ||
      !(path.toLowerCase().endsWith('.jpg') ||
          path.toLowerCase().endsWith('.jpeg') ||
          path.toLowerCase().endsWith('.png') ||
          path.toLowerCase().endsWith('.webp') ||
          path.toLowerCase().endsWith('.gif') ||
          path.toLowerCase().endsWith('.heic'))) {
    // Use FutureBuilder to read bytes asynchronously and render Image.memory
    return FutureBuilder<List<int>>(
      future: XFile(path).readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          debugPrint('buildMediaItem error: ${snapshot.error}');
          return Container(
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        final bytes = Uint8List.fromList(snapshot.data!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image.memory error: $error');
            return Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            );
          },
        );
      },
    );
  }

  // Recognized image file path; use Image.file
  if (path.toLowerCase().endsWith('.jpg') ||
      path.toLowerCase().endsWith('.jpeg') ||
      path.toLowerCase().endsWith('.png') ||
      path.toLowerCase().endsWith('.webp') ||
      path.toLowerCase().endsWith('.gif') ||
      path.toLowerCase().endsWith('.heic')) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image.file error: $error');
        return Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }

  // Video handling
  if (path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov')) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DisplayVideo(selectedByte: file),
    );
  }

  return const Text('Unsupported file type');
}
