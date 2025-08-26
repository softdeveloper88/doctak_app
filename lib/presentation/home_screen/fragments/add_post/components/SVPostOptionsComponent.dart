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
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

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

  openImages() async {
    if (_isPickingMedia) return;

    setState(() {
      _isPickingMedia = true;
    });

    try {
      // Check and request permissions first
      PermissionStatus status;
      if (Platform.isIOS) {
        status = await Permission.photos.request();
        if (status == PermissionStatus.limited) {
          // iOS 14+ limited access - still allow proceeding
          print("Limited photo access granted");
        }
      } else {
        // Android
        if (Platform.isAndroid && await Permission.storage.isPermanentlyDenied) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      }

      if (status == PermissionStatus.denied) {
        _showErrorMessage("Gallery access denied. Please allow access in settings.");
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      if (status == PermissionStatus.permanentlyDenied) {
        _showErrorMessage("Gallery access permanently denied. Please enable in settings.");
        await openAppSettings();
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      // Try pickMultipleMedia first, fallback to pickMultiImage if not supported
      List<XFile> pickedfiles = [];

      try {
        pickedfiles = await imgpicker.pickMultipleMedia(
          imageQuality: 85,
        );
      } catch (e) {
        print("pickMultipleMedia failed, trying pickMultiImage: $e");
        // Fallback to pickMultiImage for older devices
        try {
          pickedfiles = await imgpicker.pickMultiImage(
            imageQuality: 85,
          );
        } catch (e2) {
          print("pickMultiImage also failed: $e2");
          _showErrorMessage("Failed to open gallery. Please try again.");
          setState(() {
            _isPickingMedia = false;
          });
          return;
        }
      }

      if (pickedfiles.isNotEmpty) {
        // Filter supported formats
        List<XFile> validFiles = [];
        for (var element in pickedfiles) {
          if (_isValidMediaFile(element.path)) {
            validFiles.add(element);
          }
        }

        if (validFiles.isNotEmpty) {
          for (var element in validFiles) {
            imagefiles.add(element);
            widget.searchPeopleBloc.add(
              SelectedFiles(pickedfiles: element, isRemove: false),
            );
          }
          setState(() {});
        } else {
          _showErrorMessage(
            "No valid image files selected. Please select JPG, PNG, WebP, or GIF files.",
          );
        }
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("Error while picking file: $e");
      _showErrorMessage("Error selecting images. Please try again.");
    } finally {
      setState(() {
        _isPickingMedia = false;
      });
    }
  }

  bool _isValidMediaFile(String path) {
    final lowercasePath = path.toLowerCase();
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
      // Check camera and microphone permissions for video recording
      var cameraStatus = await Permission.camera.request();
      var microphoneStatus = await Permission.microphone.request();
      
      if (cameraStatus == PermissionStatus.denied || microphoneStatus == PermissionStatus.denied) {
        _showErrorMessage("Camera or microphone access denied. Please allow access in settings.");
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      if (cameraStatus == PermissionStatus.permanentlyDenied || 
          microphoneStatus == PermissionStatus.permanentlyDenied) {
        _showErrorMessage("Camera or microphone access permanently denied. Please enable in settings.");
        await openAppSettings();
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
        print("No video is selected.");
      }
    } catch (e) {
      print("Error while picking video: $e");
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
      // Check camera permission
      PermissionStatus status = await Permission.camera.request();
      
      if (status == PermissionStatus.denied) {
        _showErrorMessage("Camera access denied. Please allow access in settings.");
        setState(() {
          _isPickingMedia = false;
        });
        return;
      }

      if (status == PermissionStatus.permanentlyDenied) {
        _showErrorMessage("Camera access permanently denied. Please enable in settings.");
        await openAppSettings();
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
        print("No image is selected.");
      }
    } catch (e) {
      print("Error while taking photo: $e");
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
              if (state is PaginationLoadedState &&
                  widget.searchPeopleBloc.imagefiles.isNotEmpty) {
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
    final lowercasePath = file.path.toLowerCase();

    if (lowercasePath.endsWith('.jpg') ||
        lowercasePath.endsWith('.jpeg') ||
        lowercasePath.endsWith('.png') ||
        lowercasePath.endsWith('.webp') ||
        lowercasePath.endsWith('.gif') ||
        lowercasePath.endsWith('.heic')) {
      // Display image with better error handling
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  'Error loading image',
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
    } else if (lowercasePath.endsWith('.mp4') ||
        lowercasePath.endsWith('.mov') ||
        lowercasePath.endsWith('.avi') ||
        lowercasePath.endsWith('.mkv')) {
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
    } else {
      // Handle other types of files
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
}
