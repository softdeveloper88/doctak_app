import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:doctak_app/main.dart';
import 'debug_attachment_helper.dart';

class AttachmentBottomSheet extends StatefulWidget {
  final Function(File file, String type) onFileSelected;
  
  const AttachmentBottomSheet({
    Key? key,
    required this.onFileSelected,
  }) : super(key: key);

  @override
  State<AttachmentBottomSheet> createState() => _AttachmentBottomSheetState();
}

class _AttachmentBottomSheetState extends State<AttachmentBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<AssetEntity> _mediaList = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  final List<AttachmentOption> _options = [
    AttachmentOption(
      icon: Icons.photo_library_rounded,
      label: 'Gallery',
      color: const Color(0xFF6B4EFF),
      type: AttachmentType.gallery,
    ),
    AttachmentOption(
      icon: Icons.camera_alt_rounded,
      label: 'Camera',
      color: const Color(0xFF00C853),
      type: AttachmentType.camera,
    ),
    AttachmentOption(
      icon: Icons.videocam_rounded,
      label: 'Video',
      color: const Color(0xFFFF4757),
      type: AttachmentType.video,
    ),
    AttachmentOption(
      icon: Icons.insert_drive_file_rounded,
      label: 'Document',
      color: const Color(0xFF2196F3),
      type: AttachmentType.document,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadMedia();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          videoOption: const FilterOption(
            durationConstraint: DurationConstraint(
              min: Duration.zero,
              max: Duration(hours: 24),
            ),
          ),
        ),
      );

      if (albums.isNotEmpty) {
        final List<AssetEntity> media = await albums[0].getAssetListPaged(
          page: 0,
          size: 50,
        );
        
        if (mounted) {
          setState(() {
            _mediaList = media;
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Tab bar
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: appStore.isDarkMode 
                    ? Colors.grey[800] 
                    : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: List.generate(
                    _options.length,
                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                              ? _options[index].color
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _options[index].icon,
                                size: 18,
                                color: _currentIndex == index
                                  ? Colors.white
                                  : appStore.isDarkMode 
                                    ? Colors.white70 
                                    : Colors.black54,
                              ),
                              if (_currentIndex == index) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _options[index].label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content area
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildGalleryView(),
                    _buildCameraOption(),
                    _buildVideoOption(),
                    _buildDocumentOption(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mediaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No media found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _mediaList.length,
      itemBuilder: (context, index) {
        return FutureBuilder<Widget>(
          future: _buildMediaThumbnail(_mediaList[index]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GestureDetector(
                onTap: () async {
                  try {
                    DebugAttachmentHelper.logAttachmentFlow('Gallery Selection', {
                      'Asset ID': _mediaList[index].id,
                      'Asset Type': _mediaList[index].type.toString(),
                    });
                    
                    final File? file = await _mediaList[index].file;
                    if (file != null && await file.exists()) {
                      DebugAttachmentHelper.logFileInfo(file, 'Selected Gallery Media');
                      
                      widget.onFileSelected(
                        file, 
                        _mediaList[index].type == AssetType.video ? 'video' : 'image'
                      );
                    } else {
                      debugPrint('File does not exist or is null');
                      // Show error message to user
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to access this media file'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    DebugAttachmentHelper.logImageError(e, null, 'Gallery Selection');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load media file'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Hero(
                  tag: 'media_$index',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          snapshot.data!,
                          if (_mediaList[index].type == AssetType.video)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(_mediaList[index].videoDuration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Widget> _buildMediaThumbnail(AssetEntity asset) async {
    try {
      final thumbnail = await asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 70,
      );
      
      if (thumbnail != null) {
        return Image.memory(
          thumbnail,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading thumbnail: $error');
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[600],
                size: 32,
              ),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: child,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error getting thumbnail for asset: $e');
    }
    
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.image,
        color: Colors.grey[600],
        size: 32,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildCameraOption() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              try {
                debugPrint('=== CAMERA CAPTURE START ===');

                debugPrint('Starting image picker...');
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );

                debugPrint('Image picker result: ${photo?.path ?? 'null'}');

                if (photo != null && photo.path.isNotEmpty) {
                  debugPrint('Creating file from path: ${photo.path}');
                  final file = File(photo.path);

                  debugPrint('Checking if file exists...');
                  final fileExists = await file.exists();
                  debugPrint('File exists: $fileExists');

                  if (fileExists) {
                    DebugAttachmentHelper.logFileInfo(
                        file, 'Camera Captured Image');
                    debugPrint('About to call onFileSelected...');

                    widget.onFileSelected(file, 'image');
                    debugPrint('onFileSelected called successfully');
                  } else {
                    debugPrint(
                        'Camera file does not exist at path: ${photo.path}');
                  }
                } else {
                  debugPrint(
                      'Camera returned null photo or empty path (user may have cancelled)');
                }

                debugPrint('=== CAMERA CAPTURE END ===');
              } catch (e, stackTrace) {
                debugPrint('=== CAMERA CAPTURE ERROR ===');
                debugPrint('Error taking photo: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint('========================');
              }
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Take a photo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: appStore.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture and send instantly',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoOption() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Record Video Option
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        debugPrint('=== VIDEO CAPTURE START ===');

                        debugPrint('Starting video picker...');
                        final ImagePicker picker = ImagePicker();
                        final XFile? video = await picker.pickVideo(
                          source: ImageSource.camera,
                          maxDuration: const Duration(minutes: 5),
                        );

                        debugPrint('Video picker result: ${video?.path ?? 'null'}');

                        if (video != null && video.path.isNotEmpty) {
                          debugPrint('Creating file from path: ${video.path}');
                          final file = File(video.path);

                          debugPrint('Checking if file exists...');
                          final fileExists = await file.exists();
                          debugPrint('File exists: $fileExists');

                          if (fileExists) {
                            DebugAttachmentHelper.logFileInfo(
                                file, 'Camera Recorded Video');
                            debugPrint('About to call onFileSelected...');

                            widget.onFileSelected(file, 'video');
                            debugPrint('onFileSelected called successfully');
                          } else {
                            debugPrint(
                                'Video file does not exist at path: ${video.path}');
                          }
                        } else {
                          debugPrint(
                              'Video recording cancelled by user or returned empty path');
                        }

                        debugPrint('=== VIDEO CAPTURE END ===');
                      } catch (e, stackTrace) {
                        debugPrint('=== VIDEO CAPTURE ERROR ===');
                        debugPrint('Error recording video: $e');
                        debugPrint('Stack trace: $stackTrace');
                        debugPrint('========================');
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4757).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Record',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appStore.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              
              // Pick from Gallery Option
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        debugPrint('=== VIDEO GALLERY PICK START ===');

                        debugPrint('Starting video picker from gallery...');
                        final ImagePicker picker = ImagePicker();
                        final XFile? video = await picker.pickVideo(
                          source: ImageSource.gallery,
                        );

                        debugPrint('Video picker result: ${video?.path ?? 'null'}');

                        if (video != null && video.path.isNotEmpty) {
                          debugPrint('Creating file from path: ${video.path}');
                          final file = File(video.path);

                          debugPrint('Checking if file exists...');
                          final fileExists = await file.exists();
                          debugPrint('File exists: $fileExists');

                          if (fileExists) {
                            DebugAttachmentHelper.logFileInfo(
                                file, 'Gallery Selected Video');
                            debugPrint('About to call onFileSelected...');

                            widget.onFileSelected(file, 'video');
                            debugPrint('onFileSelected called successfully');
                          } else {
                            debugPrint(
                                'Video file does not exist at path: ${video.path}');
                          }
                        } else {
                          debugPrint(
                              'Video selection cancelled by user or returned empty path');
                        }

                        debugPrint('=== VIDEO GALLERY PICK END ===');
                      } catch (e, stackTrace) {
                        debugPrint('=== VIDEO GALLERY PICK ERROR ===');
                        debugPrint('Error picking video: $e');
                        debugPrint('Stack trace: $stackTrace');
                        debugPrint('========================');
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4EFF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.video_library_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appStore.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Choose a video to send',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentOption() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildDocumentTypeCard(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: const Color(0xFFE53935),
                  onTap: () => _pickDocument(['pdf']),
                ),
                _buildDocumentTypeCard(
                  icon: Icons.description,
                  label: 'Word',
                  color: const Color(0xFF1976D2),
                  onTap: () => _pickDocument(['doc', 'docx']),
                ),
                _buildDocumentTypeCard(
                  icon: Icons.table_chart,
                  label: 'Excel',
                  color: const Color(0xFF388E3C),
                  onTap: () => _pickDocument(['xls', 'xlsx']),
                ),
                _buildDocumentTypeCard(
                  icon: Icons.folder_open,
                  label: 'All Files',
                  color: const Color(0xFF6B4EFF),
                  onTap: () => _pickDocument(null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(List<String>? allowedExtensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        widget.onFileSelected(File(result.files.single.path!), 'document');
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }
}

class AttachmentOption {
  final IconData icon;
  final String label;
  final Color color;
  final AttachmentType type;

  AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.type,
  });
}

enum AttachmentType {
  gallery,
  camera,
  video,
  document,
}
