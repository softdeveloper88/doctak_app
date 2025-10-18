import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/robust_image_picker.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isPickingMedia = false;
  late StreamSubscription addPostSubscription;

  @override
  void initState() {
    super.initState();
    print('SVPostOptions: Setting up BLoC stream listener');
    // Sync local imagefiles with BLoC whenever state changes
    addPostSubscription = widget.searchPeopleBloc.stream.listen((state) {
      print('SVPostOptions: *** BLoC STREAM EVENT *** state: ${state.runtimeType}');
      if (state is PaginationLoadedState) {
        print('SVPostOptions: PaginationLoadedState - BLoC has ${widget.searchPeopleBloc.imagefiles.length} files');
        if (mounted) {
          setState(() {
            imagefiles = List.from(widget.searchPeopleBloc.imagefiles);
          });
        }
        print('SVPostOptions: Local imagefiles synced to ${imagefiles.length} files');
      }
    });
  }

  @override
  void dispose() {
    addPostSubscription.cancel();
    super.dispose();
  }

  openImages() async {
    if (_isPickingMedia) return;

    setState(() {
      _isPickingMedia = true;
    });

    try {
      debugPrint("SVPostOptions: *** OPENING GALLERY with RobustImagePicker ***");

      // Use RobustImagePicker which handles limited access + has photo_manager fallback
      List<XFile> pickedfiles = [];

      // First try showing the photo_manager picker directly (most reliable for limited access)
      try {
        debugPrint("SVPostOptions: Using RobustImagePicker.showPhotoManagerPicker...");
        pickedfiles = await RobustImagePicker.showPhotoManagerPicker(
          context,
          title: 'Select Photos',
        );
        debugPrint("SVPostOptions: showPhotoManagerPicker returned ${pickedfiles.length} files");
      } catch (e) {
        debugPrint("SVPostOptions: showPhotoManagerPicker failed: $e, trying fallback...");

        // Fallback to standard image picker
        try {
          pickedfiles = await RobustImagePicker.pickMultipleImages();
          debugPrint("SVPostOptions: Fallback pickMultipleImages returned ${pickedfiles.length} files");
        } catch (e2) {
          debugPrint("SVPostOptions: All pickers failed: $e2");
        }
      }

      if (pickedfiles.isNotEmpty) {
        debugPrint("SVPostOptions: Processing ${pickedfiles.length} selected files");
        // Filter supported formats
        List<XFile> validFiles = [];
        for (var element in pickedfiles) {
          final srcPath = element.path;
          final srcName = element.name;
          final isValid = _isValidMediaFile(srcPath) || _isValidMediaFile(srcName);
          if (isValid) {
            validFiles.add(element);
            debugPrint("SVPostOptions: Valid file added: ${element.path}");
          } else {
            debugPrint("SVPostOptions: Invalid file skipped: ${element.path} (name: ${element.name})");
          }
        }

        if (validFiles.isNotEmpty) {
          debugPrint("SVPostOptions: Adding ${validFiles.length} valid files to BLoC");
          for (var element in validFiles) {
            imagefiles.add(element);
            debugPrint("SVPostOptions: Adding file to BLoC: ${element.path}");
            widget.searchPeopleBloc.add(
              SelectedFiles(pickedfiles: element, isRemove: false),
            );
            debugPrint("SVPostOptions: SelectedFiles event sent to BLoC");
          }
          debugPrint("SVPostOptions: BLoC should have ${widget.searchPeopleBloc.imagefiles.length} files now");
          setState(() {});
          debugPrint("SVPostOptions: setState() called - UI should refresh");
          debugPrint("SVPostOptions: Local imagefiles has ${imagefiles.length} total files");
        } else {
          _showErrorMessage(
            "No valid image files selected. Please select JPG, PNG, WebP, or GIF files.",
          );
        }
      } else {
        debugPrint("SVPostOptions: No images selected by user");
      }
    } catch (e) {
      debugPrint("Error while picking file: $e");
      debugPrint("Error stack trace: ${StackTrace.current}");
      _showErrorMessage("Error selecting images. Please try again.");
    } finally {
      setState(() {
        _isPickingMedia = false;
      });
    }
  }

  bool _isValidMediaFile(String path) {
    if (path.isEmpty) return false;
    final lowercasePath = path.toLowerCase();
    // Accept Android content URIs (limited access) as valid media
    if (lowercasePath.startsWith('content://')) return true;
    return lowercasePath.endsWith('.jpg') ||
      lowercasePath.endsWith('.jpeg') ||
      lowercasePath.endsWith('.png') ||
      lowercasePath.endsWith('.webp') ||
      lowercasePath.endsWith('.gif') ||
      lowercasePath.endsWith('.heic');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  openVideo() async {
    if (_isPickingMedia) return;

    setState(() {
      _isPickingMedia = true;
    });

    try {
      // Check camera and microphone permissions using professional handler
      final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(context);
      if (!cameraGranted) {
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      final microphoneGranted = await PermissionUtils.ensureMicrophonePermission();
      if (!microphoneGranted) {
        _showErrorMessage("Microphone access is required for video recording.");
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      var pickedfiles = await imgpicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      if (pickedfiles != null) {
        imagefiles.add(pickedfiles);
        widget.searchPeopleBloc.add(
          SelectedFiles(pickedfiles: pickedfiles, isRemove: false),
        );
        setState(() {});
      } else {
        debugPrint("No video is selected.");
      }
    } catch (e) {
      debugPrint("Error while picking video: $e");
      _showErrorMessage("Error recording video. Please try again.");
    } finally {
      setState(() {
        _isPickingMedia = false;
      });
    }
  }

  openCamera() async {
    if (_isPickingMedia) return;

    setState(() {
      _isPickingMedia = true;
    });

    try {
      // Check camera permission using professional handler
      final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(context);
      if (!cameraGranted) {
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      var pickedfiles = await imgpicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (pickedfiles != null) {
        imagefiles.add(pickedfiles);
        widget.searchPeopleBloc.add(
          SelectedFiles(pickedfiles: pickedfiles, isRemove: false),
        );
        setState(() {});
      } else {
        debugPrint("No image is selected.");
      }
    } catch (e) {
      debugPrint("Error while taking photo: $e");
      _showErrorMessage("Error taking photo. Please try again.");
    } finally {
      setState(() {
        _isPickingMedia = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
        children: [
          // Selected Media Preview - Show if any media selected
          BlocBuilder<AddPostBloc, AddPostState>(
            bloc: widget.searchPeopleBloc,
            builder: (context, state) {
              print('SVPostOptions: BlocBuilder state: ${state.runtimeType}, BLoC files: ${widget.searchPeopleBloc.imagefiles.length}');
              if (state is PaginationLoadedState &&
                  widget.searchPeopleBloc.imagefiles.isNotEmpty) {
                print('SVPostOptions: Rendering ${widget.searchPeopleBloc.imagefiles.length} images in UI');
                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media (${widget.searchPeopleBloc.imagefiles.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.searchPeopleBloc.imagefiles.length,
                          itemBuilder: (context, index) {
                            final imageone =
                                widget.searchPeopleBloc.imagefiles[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: buildMediaItem(
                                        File(imageone.path),
                                      ),
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
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
          // Media Options - Compact grid layout for side-by-side display
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Media',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                _buildCompactMediaOptions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMediaOptions(BuildContext context, bool isTablet) {
    return [
      _buildMediaOption(
        context: context,
        icon: Icons.photo_library_outlined,
        title: translation(context).lbl_from_gallery,
        subtitle: _isPickingMedia ? 'Loading...' : 'Choose photos or videos',
        color: Colors.blue[700]!,
        onTap: _isPickingMedia
            ? null
            : () {
                openImages();
              },
        isLoading: _isPickingMedia,
        isTablet: false,
      ),
      const SizedBox(height: 8),
      _buildMediaOption(
        context: context,
        icon: Icons.videocam_outlined,
        title: translation(context).lbl_take_video,
        subtitle: 'Record a new video',
        color: Colors.purple[700]!,
        onTap: _isPickingMedia
            ? null
            : () {
                openVideo();
              },
        isLoading: false,
        isTablet: false,
      ),
      const SizedBox(height: 8),
      _buildMediaOption(
        context: context,
        icon: Icons.camera_alt_outlined,
        title: translation(context).lbl_take_picture,
        subtitle: 'Capture a new photo',
        color: Colors.green[700]!,
        onTap: _isPickingMedia
            ? null
            : () {
                openCamera();
              },
        isLoading: false,
        isTablet: false,
      ),
      const SizedBox(height: 16), // Bottom padding
    ];
  }

  Widget _buildCompactMediaOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactMediaOption(
            context: context,
            icon: Icons.photo_library_outlined,
            title: 'Gallery',
            color: Colors.blue[700]!,
            onTap: _isPickingMedia
                ? null
                : () {
                    openImages();
                  },
            isLoading: _isPickingMedia,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactMediaOption(
            context: context,
            icon: Icons.videocam_outlined,
            title: 'Video',
            color: Colors.purple[700]!,
            onTap: _isPickingMedia
                ? null
                : () {
                    openVideo();
                  },
            isLoading: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactMediaOption(
            context: context,
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            color: Colors.green[700]!,
            onTap: _isPickingMedia
                ? null
                : () {
                    openCamera();
                  },
            isLoading: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMediaOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    )
                  : Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: onTap == null ? Colors.grey[400] : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
    required bool isTablet,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 4 : 0,
        vertical: isTablet ? 0 : 1,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isTablet
              ? Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            )
                          : Icon(icon, size: 24, color: color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: onTap == null
                            ? Colors.grey[400]
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            )
                          : Icon(icon, size: 22, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: onTap == null
                                  ? Colors.grey[400]
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
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
    );
  }

  Widget buildMediaItem(File file) {
    final path = file.path;
    // First check for common video extensions
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm')) {
      // Display video with play icon overlay
      return Stack(
        children: [
          AspectRatio(aspectRatio: 1, child: DisplayVideo(selectedByte: file)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Determine if it looks like an image (by extension) or is a content URI
    final looksLikeImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif');

    if (looksLikeImage || path.startsWith('content://') || path.startsWith('/data/')) {
      // Try to read bytes and render as image; this handles content URIs and files without extension
      return FutureBuilder<List<int>>(
        future: XFile(path).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            debugPrint('buildMediaItem error: ${snapshot.error}');
            return Container(
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unsupported file',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 8,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Render image from bytes with a fallback if decoding fails
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Image.memory error: $error');
              return Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unsupported file',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 8,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    // Fallback: unknown file type -> show generic file icon
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            'Unsupported file',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 8,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
