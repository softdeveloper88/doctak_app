import 'dart:io';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:doctak_app/utils/permission_utils.dart';

/// A unified gallery picker that provides consistent image picking experience
/// across the entire application for both iOS and Android.
/// 
/// Features:
/// - Photo Manager based gallery grid with thumbnails
/// - Camera option with proper permission handling
/// - Single and multiple image selection modes
/// - Consistent OneUI 8.5 styled bottom sheet design
/// - Proper handling for both iOS and Android permissions
class UnifiedGalleryPicker {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Show the unified gallery picker bottom sheet
  /// 
  /// [context] - BuildContext for showing the bottom sheet
  /// [maxImages] - Maximum number of images that can be selected (null for unlimited, 1 for single selection)
  /// [showCamera] - Whether to show the camera option
  /// [title] - Title displayed in the bottom sheet header
  /// [onImageSelected] - Callback when single image is selected (for single mode)
  /// [onImagesSelected] - Callback when multiple images are selected (for multi mode)
  /// 
  /// Returns list of selected files, or null if cancelled
  static Future<List<File>?> show(
    BuildContext context, {
    int? maxImages,
    bool showCamera = true,
    String title = 'Select Photo',
  }) async {
    return await showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => _UnifiedGalleryPickerSheet(
        maxImages: maxImages,
        showCamera: showCamera,
        title: title,
      ),
    );
  }

  /// Convenience method for picking a single image
  static Future<File?> pickSingleImage(
    BuildContext context, {
    bool showCamera = true,
    String title = 'Select Photo',
  }) async {
    final result = await show(
      context,
      maxImages: 1,
      showCamera: showCamera,
      title: title,
    );
    return result?.isNotEmpty == true ? result!.first : null;
  }

  /// Convenience method for picking multiple images
  static Future<List<File>?> pickMultipleImages(
    BuildContext context, {
    int? maxImages,
    bool showCamera = true,
    String title = 'Select Photos',
  }) async {
    return await show(
      context,
      maxImages: maxImages,
      showCamera: showCamera,
      title: title,
    );
  }
  
  /// Direct camera capture (useful when only camera is needed)
  static Future<File?> captureFromCamera(BuildContext context) async {
    final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(context);
    if (!cameraGranted) return null;

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (photo != null) {
        return File(photo.path);
      }
    } catch (e) {
      debugPrint('UnifiedGalleryPicker: Camera capture failed: $e');
    }
    return null;
  }
}

/// The main bottom sheet widget for unified gallery picking
class _UnifiedGalleryPickerSheet extends StatefulWidget {
  final int? maxImages;
  final bool showCamera;
  final String title;

  const _UnifiedGalleryPickerSheet({
    required this.maxImages,
    required this.showCamera,
    required this.title,
  });

  @override
  State<_UnifiedGalleryPickerSheet> createState() => _UnifiedGalleryPickerSheetState();
}

class _UnifiedGalleryPickerSheetState extends State<_UnifiedGalleryPickerSheet> 
    with SingleTickerProviderStateMixin {
  List<AssetEntity> _assets = [];
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isSingleSelectMode = false;
  
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isSingleSelectMode = widget.maxImages == 1;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _loadAssets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    try {
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      debugPrint('UnifiedGalleryPicker: Permission state: ${permission.name}');

      if (!permission.isAuth && !permission.hasAccess) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasPermission = false;
          });
        }
        return;
      }

      _hasPermission = true;

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(minWidth: 0, minHeight: 0),
          ),
        ),
      );

      if (albums.isNotEmpty) {
        final assets = await albums[0].getAssetListPaged(page: 0, size: 100);
        if (mounted) {
          setState(() {
            _assets = assets;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('UnifiedGalleryPicker: Error loading assets: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(int index) {
    if (_isSingleSelectMode) {
      // For single selection, immediately return the selected image
      _selectAndReturn(index);
      return;
    }

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (widget.maxImages == null || _selectedIndices.length < widget.maxImages!) {
          _selectedIndices.add(index);
        } else {
          // Show max limit reached feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum ${widget.maxImages} images allowed'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _selectAndReturn(int index) async {
    try {
      final file = await _assets[index].file;
      if (file != null && mounted) {
        Navigator.of(context).pop([file]);
      }
    } catch (e) {
      debugPrint('UnifiedGalleryPicker: Error getting file: $e');
    }
  }

  Future<void> _confirmSelection() async {
    final List<File> result = [];

    for (final index in _selectedIndices) {
      final file = await _assets[index].file;
      if (file != null) {
        result.add(file);
      }
    }

    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _openCamera() async {
    final cameraGranted = await PermissionUtils.requestCameraPermissionWithUI(context);
    if (!cameraGranted) return;

    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null && mounted) {
        Navigator.of(context).pop([File(photo.path)]);
      }
    } catch (e) {
      debugPrint('UnifiedGalleryPicker: Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error taking photo. Please try again.'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              _buildHeader(theme),
              // Tabs (Gallery + Camera)
              if (widget.showCamera) _buildTabs(theme),
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoading(theme)
                    : !_hasPermission
                        ? _buildNoPermission(theme)
                        : _assets.isEmpty
                            ? _buildEmptyState(theme)
                            : _buildGalleryGrid(theme, bottomPadding),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OneUITheme theme) {
    return Container(
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
              Icons.photo_library_rounded,
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
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                if (!_isSingleSelectMode && widget.maxImages != null)
                  Text(
                    'Select up to ${widget.maxImages} photo${widget.maxImages! > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Done button for multi-select mode
          if (!_isSingleSelectMode)
            TextButton(
              onPressed: _selectedIndices.isNotEmpty ? _confirmSelection : null,
              style: TextButton.styleFrom(
                backgroundColor: _selectedIndices.isNotEmpty 
                    ? theme.primary 
                    : theme.divider,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                _selectedIndices.isNotEmpty 
                    ? 'Done (${_selectedIndices.length})' 
                    : 'Done',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: _selectedIndices.isNotEmpty 
                      ? Colors.white 
                      : theme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs(OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Gallery Tab (always selected in this view)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_rounded, size: 18, color: theme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Gallery',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Camera Tab
          Expanded(
            child: GestureDetector(
              onTap: _openCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 18, color: theme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Camera',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading photos...',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermission(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: theme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Photo Access Required',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow photo access to select images from your gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => PhotoManager.openSetting(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: theme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No photos found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your gallery appears to be empty',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(OneUITheme theme, double bottomPadding) {
    return GridView.builder(
      padding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16 + bottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedIndices.contains(index);
        return GestureDetector(
          onTap: () => _toggleSelection(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              FutureBuilder<Widget>(
                future: _buildThumbnail(_assets[index], theme),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: theme.divider,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: snapshot.data!,
                    );
                  }
                  return Container(
                    color: theme.divider,
                    child: Icon(Icons.image_outlined, color: theme.textSecondary),
                  );
                },
              ),
              // Selection overlay
              if (isSelected)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: theme.primary.withValues(alpha: 0.3),
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              // Selection number badge for multi-select
              if (isSelected && !_isSingleSelectMode)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${_selectedIndices.toList().indexOf(index) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              // Unselected border
              if (!isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Widget> _buildThumbnail(AssetEntity asset, OneUITheme theme) async {
    try {
      final thumb = await asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 80,
      );
      if (thumb != null && thumb.isNotEmpty) {
        return Image.memory(
          thumb,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: theme.divider,
              child: Icon(Icons.broken_image_outlined, color: theme.textSecondary),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('UnifiedGalleryPicker: Error loading thumbnail: $e');
    }
    return Container(
      color: theme.divider,
      child: Icon(Icons.image_outlined, color: theme.textSecondary),
    );
  }
}
