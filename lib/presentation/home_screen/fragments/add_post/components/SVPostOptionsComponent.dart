import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/robust_image_picker.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SVPostOptionsComponent extends StatefulWidget {
  final AddPostBloc searchPeopleBloc;

  const SVPostOptionsComponent(this.searchPeopleBloc, {super.key});

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
      print(
        'SVPostOptions: *** BLoC STREAM EVENT *** state: ${state.runtimeType}',
      );
      if (state is PaginationLoadedState) {
        print(
          'SVPostOptions: PaginationLoadedState - BLoC has ${widget.searchPeopleBloc.imagefiles.length} files',
        );
        if (mounted) {
          setState(() {
            imagefiles = List.from(widget.searchPeopleBloc.imagefiles);
          });
        }
        print(
          'SVPostOptions: Local imagefiles synced to ${imagefiles.length} files',
        );
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
      debugPrint(
        "SVPostOptions: *** OPENING GALLERY with RobustImagePicker ***",
      );

      List<XFile> pickedfiles = [];

      try {
        debugPrint(
          "SVPostOptions: Using RobustImagePicker.showPhotoManagerPicker...",
        );
        pickedfiles = await RobustImagePicker.showPhotoManagerPicker(
          context,
          title: 'Select Photos',
        );
        debugPrint(
          "SVPostOptions: showPhotoManagerPicker returned ${pickedfiles.length} files",
        );
      } catch (e) {
        debugPrint(
          "SVPostOptions: showPhotoManagerPicker failed: $e, trying fallback...",
        );

        try {
          pickedfiles = await RobustImagePicker.pickMultipleImages();
          debugPrint(
            "SVPostOptions: Fallback pickMultipleImages returned ${pickedfiles.length} files",
          );
        } catch (e2) {
          debugPrint("SVPostOptions: All pickers failed: $e2");
        }
      }

      if (pickedfiles.isNotEmpty) {
        debugPrint(
          "SVPostOptions: Processing ${pickedfiles.length} selected files",
        );
        List<XFile> validFiles = [];
        for (var element in pickedfiles) {
          final srcPath = element.path;
          final srcName = element.name;
          final isValid =
              _isValidMediaFile(srcPath) || _isValidMediaFile(srcName);
          if (isValid) {
            validFiles.add(element);
            debugPrint("SVPostOptions: Valid file added: ${element.path}");
          } else {
            debugPrint(
              "SVPostOptions: Invalid file skipped: ${element.path} (name: ${element.name})",
            );
          }
        }

        if (validFiles.isNotEmpty) {
          debugPrint(
            "SVPostOptions: Adding ${validFiles.length} valid files to BLoC",
          );
          for (var element in validFiles) {
            imagefiles.add(element);
            debugPrint("SVPostOptions: Adding file to BLoC: ${element.path}");
            widget.searchPeopleBloc.add(
              SelectedFiles(pickedfiles: element, isRemove: false),
            );
            debugPrint("SVPostOptions: SelectedFiles event sent to BLoC");
          }
          debugPrint(
            "SVPostOptions: BLoC should have ${widget.searchPeopleBloc.imagefiles.length} files now",
          );
          setState(() {});
          debugPrint("SVPostOptions: setState() called - UI should refresh");
          debugPrint(
            "SVPostOptions: Local imagefiles has ${imagefiles.length} total files",
          );
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
    if (lowercasePath.startsWith('content://')) return true;
    return lowercasePath.endsWith('.jpg') ||
        lowercasePath.endsWith('.jpeg') ||
        lowercasePath.endsWith('.png') ||
        lowercasePath.endsWith('.webp') ||
        lowercasePath.endsWith('.gif') ||
        lowercasePath.endsWith('.heic');
  }

  void _showErrorMessage(String message) {
    final theme = OneUITheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: theme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(
        context,
      );
      if (!cameraGranted) {
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      final microphoneGranted =
          await PermissionUtils.ensureMicrophonePermission();
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
      final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(
        context,
      );
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
    final theme = OneUITheme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        children: [
          // Selected Media Preview
          BlocBuilder<AddPostBloc, AddPostState>(
            bloc: widget.searchPeopleBloc,
            builder: (context, state) {
              print(
                'SVPostOptions: BlocBuilder state: ${state.runtimeType}, BLoC files: ${widget.searchPeopleBloc.imagefiles.length}',
              );
              if (state is PaginationLoadedState &&
                  widget.searchPeopleBloc.imagefiles.isNotEmpty) {
                print(
                  'SVPostOptions: Rendering ${widget.searchPeopleBloc.imagefiles.length} images in UI',
                );
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.photo_on_rectangle,
                            size: 16,
                            color: theme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Media (${widget.searchPeopleBloc.imagefiles.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 56,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.searchPeopleBloc.imagefiles.length,
                          itemBuilder: (context, index) {
                            final imageone =
                                widget.searchPeopleBloc.imagefiles[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: theme.border,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: buildMediaItem(
                                        File(imageone.path),
                                        theme,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
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
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.error,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.cardBackground,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.error.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.xmark,
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
          // Media Options Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.photo_camera,
                  size: 18,
                  color: theme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Media',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Media Options Grid - One UI 8.5 Style
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMediaOptionCard(
                    context: context,
                    theme: theme,
                    icon: CupertinoIcons.photo_on_rectangle,
                    title: 'Gallery',
                    color: const Color(0xFF0A84FF),
                    onTap: _isPickingMedia ? null : openImages,
                    isLoading: _isPickingMedia,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMediaOptionCard(
                    context: context,
                    theme: theme,
                    icon: CupertinoIcons.videocam_fill,
                    title: 'Video',
                    color: const Color(0xFFAF52DE),
                    onTap: _isPickingMedia ? null : openVideo,
                    isLoading: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMediaOptionCard(
                    context: context,
                    theme: theme,
                    icon: CupertinoIcons.camera_fill,
                    title: 'Camera',
                    color: const Color(0xFF34C759),
                    onTap: _isPickingMedia ? null : openCamera,
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOptionCard({
    required BuildContext context,
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return Material(
      color: theme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(theme.isDark ? 0.12 : 0.06),
                color.withOpacity(theme.isDark ? 0.05 : 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(theme.isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      )
                    : Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: onTap == null ? theme.textTertiary : theme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMediaItem(File file, OneUITheme theme) {
    final path = file.path;
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm')) {
      return Stack(
        children: [
          AspectRatio(aspectRatio: 1, child: DisplayVideo(selectedByte: file)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.play_fill,
                    color: theme.primary,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final looksLikeImage =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif');

    if (looksLikeImage ||
        path.startsWith('content://') ||
        path.startsWith('/data/')) {
      return FutureBuilder<List<int>>(
        future: XFile(path).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: theme.surfaceVariant,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            debugPrint('buildMediaItem error: ${snapshot.error}');
            return _buildUnsupportedFileWidget(theme);
          }

          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Image.memory error: $error');
              return _buildUnsupportedFileWidget(theme);
            },
          );
        },
      );
    }

    return _buildUnsupportedFileWidget(theme);
  }

  Widget _buildUnsupportedFileWidget(OneUITheme theme) {
    return Container(
      color: theme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc, color: theme.textTertiary, size: 18),
          const SizedBox(height: 2),
          Text(
            'File',
            style: TextStyle(
              color: theme.textTertiary,
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
