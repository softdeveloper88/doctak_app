import 'dart:io';
import 'dart:typed_data';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/unified_gallery_picker.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import 'package:doctak_app/widgets/image_upload_widget/bloc/image_upload_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

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
    debugPrint('MultiWidget: *** OPENING GALLERY with UnifiedGalleryPicker ***');
    try {
      debugPrint('MultiWidget: Image limit: ${widget.imageLimit}');

      // Use unified gallery picker for consistent experience
      final List<File>? pickedFiles = await UnifiedGalleryPicker.pickMultipleImages(
        context,
        maxImages: widget.imageLimit > 0 ? widget.imageLimit : null,
        title: translation(context).lbl_choose_from_gallery,
      );

      debugPrint('MultiWidget: Picker returned: ${pickedFiles?.length ?? 0} files');

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        debugPrint('MultiWidget: First file path: ${pickedFiles.first.path}');
        debugPrint('Gallery: Selected ${pickedFiles.length} files from gallery');
        for (var element in pickedFiles) {
          if (widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit) {
            debugPrint('Gallery: Adding image ${element.path} to BLoC');
            widget.imageUploadBloc.add(SelectedFiles(pickedfiles: XFile(element.path), isRemove: false));
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
      final File? photo = await UnifiedGalleryPicker.captureFromCamera(context);

      if (photo != null) {
        if (widget.imageLimit == 0 || widget.imageUploadBloc.imagefiles.length < widget.imageLimit) {
          widget.imageUploadBloc.add(SelectedFiles(pickedfiles: XFile(photo.path), isRemove: false));
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
    final theme = OneUITheme.of(context);
    
    return Container(
      width: context.width(),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle - OneUI 8.5 style
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title section - OneUI 8.5 style
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    color: theme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Images',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        'Select medical images for analysis',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content area with scroll
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected images preview
                    BlocBuilder<ImageUploadBloc, ImageUploadState>(
                      bloc: widget.imageUploadBloc,
                      builder: (context, state) {
                        if (state is FileLoadedState && widget.imageUploadBloc.imagefiles.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      size: 16,
                                      color: theme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Selected Images (${widget.imageUploadBloc.imagefiles.length})',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: widget.imageUploadBloc.imagefiles.map((imageone) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: theme.scaffoldBackground,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: buildMediaItem(File(imageone.path)),
                                              ),
                                            ),
                                            Positioned(
                                              top: -4,
                                              right: -4,
                                              child: GestureDetector(
                                                onTap: () {
                                                  widget.imageUploadBloc.add(
                                                    SelectedFiles(
                                                      pickedfiles: imageone,
                                                      isRemove: true,
                                                    ),
                                                  );
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: theme.error,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme.error.withValues(alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 14,
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
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Special instruction for medical scans
                    if (widget.imageType == "CT Scan" ||
                        widget.imageType == "MRI Scan" ||
                        widget.imageType == "Mammography")
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.warning.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: theme.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Please upload one or two of the most relevant images for analysis.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: theme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Gallery button - OneUI 8.5 style
                    BlocBuilder<ImageUploadBloc, ImageUploadState>(
                      bloc: widget.imageUploadBloc,
                      builder: (context, state) {
                        bool canAddMore = widget.imageLimit == 0 ||
                            widget.imageUploadBloc.imagefiles.length < widget.imageLimit;
                        return _buildActionButton(
                          context: context,
                          theme: theme,
                          icon: Icons.photo_library_outlined,
                          title: 'Choose from Gallery',
                          subtitle: widget.imageLimit > 0
                              ? '${widget.imageUploadBloc.imagefiles.length}/${widget.imageLimit} images selected'
                              : 'Select medical images from your device',
                          gradientColors: canAddMore
                              ? [theme.primary.withValues(alpha: 0.85), theme.primary]
                              : [theme.textSecondary.withValues(alpha: 0.3), theme.textSecondary.withValues(alpha: 0.4)],
                          enabled: canAddMore,
                          onTap: canAddMore ? openImages : null,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Camera button - OneUI 8.5 style
                    BlocBuilder<ImageUploadBloc, ImageUploadState>(
                      bloc: widget.imageUploadBloc,
                      builder: (context, state) {
                        bool canAddMore = widget.imageLimit == 0 ||
                            widget.imageUploadBloc.imagefiles.length < widget.imageLimit;
                        return _buildActionButton(
                          context: context,
                          theme: theme,
                          icon: Icons.camera_alt_outlined,
                          title: 'Take Photo',
                          subtitle: widget.imageLimit > 0
                              ? '${widget.imageUploadBloc.imagefiles.length}/${widget.imageLimit} images selected'
                              : 'Capture medical image with camera',
                          gradientColors: canAddMore
                              ? [theme.success.withValues(alpha: 0.85), theme.success]
                              : [theme.textSecondary.withValues(alpha: 0.3), theme.textSecondary.withValues(alpha: 0.4)],
                          enabled: canAddMore,
                          onTap: canAddMore ? openCamera : null,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Continue button - OneUI 8.5 style
                    BlocBuilder<ImageUploadBloc, ImageUploadState>(
                      bloc: widget.imageUploadBloc,
                      builder: (context, state) {
                        final hasImages = widget.imageUploadBloc.imagefiles.isNotEmpty;
                        return Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(27),
                            gradient: hasImages
                                ? LinearGradient(
                                    colors: [theme.primary.withValues(alpha: 0.9), theme.primary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      theme.textSecondary.withValues(alpha: 0.2),
                                      theme.textSecondary.withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: hasImages
                                ? [
                                    BoxShadow(
                                      color: theme.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(27),
                              onTap: hasImages
                                  ? () => widget.onTap(widget.imageUploadBloc.imagefiles)
                                  : null,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasImages) ...[
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Text(
                                      hasImages ? 'Continue with Images' : 'Select Images First',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: hasImages
                                            ? Colors.white
                                            : theme.textSecondary.withValues(alpha: 0.6),
                                        fontSize: 16,
                                        letterSpacing: 0.3,
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

                    // Bottom safe area padding
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons with OneUI 8.5 style
  Widget _buildActionButton({
    required BuildContext context,
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 18,
                ),
              ],
            ),
          ),
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
