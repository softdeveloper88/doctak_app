import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

/// A robust image picker that handles Android 13+ limited access permission properly.
/// Falls back to photo_manager when image_picker fails (common with singleInstance/singleTop activities).
class RobustImagePicker {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick multiple images from gallery with proper limited access handling.
  /// Returns a list of XFile objects, or empty list if cancelled/failed.
  static Future<List<XFile>> pickMultipleImages({int? limit, int imageQuality = 85, double maxWidth = 1920, double maxHeight = 1080}) async {
    debugPrint('RobustImagePicker: Starting pickMultipleImages');

    // First try standard image_picker
    try {
      debugPrint('RobustImagePicker: Trying image_picker...');
      final List<XFile> result = await _imagePicker.pickMultipleMedia(limit: limit, imageQuality: imageQuality, maxWidth: maxWidth, maxHeight: maxHeight, requestFullMetadata: false);

      if (result.isNotEmpty) {
        debugPrint('RobustImagePicker: image_picker succeeded with ${result.length} files');
        return result;
      }

      debugPrint('RobustImagePicker: image_picker returned empty, trying photo_manager fallback...');
    } catch (e) {
      debugPrint('RobustImagePicker: image_picker failed: $e');
    }

    // Fallback to photo_manager which handles limited access better
    try {
      return await _pickWithPhotoManager(limit: limit);
    } catch (e) {
      debugPrint('RobustImagePicker: photo_manager fallback also failed: $e');
      return <XFile>[];
    }
  }

  /// Pick a single image from gallery
  static Future<XFile?> pickSingleImage({int imageQuality = 85, double maxWidth = 1920, double maxHeight = 1080}) async {
    debugPrint('RobustImagePicker: Starting pickSingleImage');

    // First try standard image_picker
    try {
      debugPrint('RobustImagePicker: Trying image_picker for single image...');
      final XFile? result = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: imageQuality, maxWidth: maxWidth, maxHeight: maxHeight);

      if (result != null) {
        debugPrint('RobustImagePicker: image_picker succeeded with ${result.path}');
        return result;
      }

      debugPrint('RobustImagePicker: image_picker returned null, trying photo_manager fallback...');
    } catch (e) {
      debugPrint('RobustImagePicker: image_picker failed: $e');
    }

    // Fallback to photo_manager
    try {
      final files = await _pickWithPhotoManager(limit: 1);
      return files.isNotEmpty ? files.first : null;
    } catch (e) {
      debugPrint('RobustImagePicker: photo_manager fallback also failed: $e');
      return null;
    }
  }

  /// Pick images using photo_manager (better support for limited access)
  static Future<List<XFile>> _pickWithPhotoManager({int? limit}) async {
    debugPrint('RobustImagePicker: Using photo_manager fallback');

    // Request permission
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    debugPrint('RobustImagePicker: photo_manager permission: ${permission.name}');

    if (!permission.isAuth && !permission.hasAccess) {
      debugPrint('RobustImagePicker: photo_manager permission denied');
      return <XFile>[];
    }

    // Get recent images
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(imageOption: const FilterOption(sizeConstraint: SizeConstraint(minWidth: 0, minHeight: 0))),
    );

    if (albums.isEmpty) {
      debugPrint('RobustImagePicker: No photo albums found');
      return <XFile>[];
    }

    // Get assets from the first album (usually "Recent" or "All Photos")
    final int fetchCount = limit ?? 50;
    final List<AssetEntity> assets = await albums[0].getAssetListPaged(page: 0, size: fetchCount);

    debugPrint('RobustImagePicker: Found ${assets.length} assets');

    if (assets.isEmpty) {
      return <XFile>[];
    }

    // For now, just return the first asset(s) if we can't show a picker UI
    // In a real implementation, you'd show a custom picker UI
    final List<XFile> result = <XFile>[];
    final int takeCount = limit ?? assets.length;

    for (int i = 0; i < takeCount && i < assets.length; i++) {
      final file = await assets[i].file;
      if (file != null) {
        result.add(XFile(file.path));
        debugPrint('RobustImagePicker: Added file ${file.path}');
      }
    }

    debugPrint('RobustImagePicker: Returning ${result.length} files from photo_manager');
    return result;
  }

  /// Show a bottom sheet picker using photo_manager for better control
  static Future<List<XFile>> showPhotoManagerPicker(BuildContext context, {int? limit, String title = 'Select Photos'}) async {
    debugPrint('RobustImagePicker: Showing photo_manager picker UI');

    // Request permission first
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    debugPrint('RobustImagePicker: photo_manager permission: ${permission.name}');

    if (!permission.isAuth && !permission.hasAccess) {
      debugPrint('RobustImagePicker: Permission not granted');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Photo access required to select images'), backgroundColor: Colors.orange[600], behavior: SnackBarBehavior.floating));
      }
      return <XFile>[];
    }

    // Show the picker modal
    final List<XFile>? result = await showModalBottomSheet<List<XFile>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoManagerPickerSheet(limit: limit, title: title),
    );

    return result ?? <XFile>[];
  }
}

/// A bottom sheet that shows photos from photo_manager for selection
class _PhotoManagerPickerSheet extends StatefulWidget {
  final int? limit;
  final String title;

  const _PhotoManagerPickerSheet({this.limit, required this.title});

  @override
  State<_PhotoManagerPickerSheet> createState() => _PhotoManagerPickerSheetState();
}

class _PhotoManagerPickerSheetState extends State<_PhotoManagerPickerSheet> {
  List<AssetEntity> _assets = [];
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(imageOption: const FilterOption(sizeConstraint: SizeConstraint(minWidth: 0, minHeight: 0))),
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
      debugPrint('Error loading assets: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        if (widget.limit == null || _selectedIndices.length < widget.limit!) {
          _selectedIndices.add(index);
        }
      }
    });
  }

  Future<void> _confirmSelection() async {
    final List<XFile> result = <XFile>[];

    for (final index in _selectedIndices) {
      final file = await _assets[index].file;
      if (file != null) {
        result.add(XFile(file.path));
      }
    }

    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(<XFile>[]), child: const Text('Cancel')),
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _selectedIndices.isNotEmpty ? _confirmSelection : null,
                  child: Text(
                    'Done (${_selectedIndices.length})',
                    style: TextStyle(color: _selectedIndices.isNotEmpty ? Colors.blue : Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assets.isEmpty
                ? const Center(child: Text('No photos found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                    itemCount: _assets.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndices.contains(index);
                      return GestureDetector(
                        onTap: () => _toggleSelection(index),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<Widget>(
                              future: _buildThumbnail(_assets[index]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                  );
                                }
                                if (snapshot.hasError) {
                                  debugPrint('FutureBuilder error: ${snapshot.error}');
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)),
                                  );
                                }
                                if (snapshot.hasData) {
                                  return snapshot.data!;
                                }
                                return Container(color: Colors.grey[300]);
                              },
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.blue.withValues(alpha: 0.3),
                                child: const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 32)),
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

  Future<Widget> _buildThumbnail(AssetEntity asset) async {
    try {
      final thumb = await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200), quality: 80);
      if (thumb != null && thumb.isNotEmpty) {
        return Image.memory(
          thumb,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading thumbnail: $error');
            return Container(
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Exception loading thumbnail: $e');
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
    );
  }
}
