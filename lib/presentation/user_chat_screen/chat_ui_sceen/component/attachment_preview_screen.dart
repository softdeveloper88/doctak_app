import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:path/path.dart' as path;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'debug_attachment_helper.dart';

class AttachmentPreviewScreen extends StatefulWidget {
  final File file;
  final String type;
  final Function(File file, String caption) onSend;

  const AttachmentPreviewScreen({super.key, required this.file, required this.type, required this.onSend});

  @override
  State<AttachmentPreviewScreen> createState() => _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  File? _editedImageFile;
  bool _showEmojiPicker = false;
  List<OverlayItem> _overlayItems = [];
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Debug logging
    DebugAttachmentHelper.logFileInfo(widget.file, 'Preview Screen Init');
    DebugAttachmentHelper.logAttachmentFlow('Preview Screen', {'File Type': widget.type, 'File Path': widget.file.path});

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();

    if (widget.type == 'video') {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(widget.file);
    await _videoController!.initialize();
    setState(() {
      _isVideoInitialized = true;
    });
    _videoController!.play();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Preview area
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(position: _slideAnimation, child: _buildPreview()),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (widget.type == 'image') ...[
                        IconButton(
                          icon: const Icon(Icons.crop_rotate, color: Colors.white),
                          onPressed: _openImageEditor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_fields, color: Colors.white),
                          onPressed: _addTextOverlay,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji picker
                  if (_showEmojiPicker && widget.type == 'image')
                    Container(
                      height: 300,
                      color: Colors.black87,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          _addEmojiOverlay(emoji.emoji);
                          setState(() {
                            _showEmojiPicker = false;
                          });
                        },
                        config: Config(
                          height: 300,
                          checkPlatformCompatibility: true,
                          viewOrderConfig: const ViewOrderConfig(),
                          emojiViewConfig: const EmojiViewConfig(emojiSizeMax: 32),
                          skinToneConfig: const SkinToneConfig(),
                          categoryViewConfig: const CategoryViewConfig(),
                          bottomActionBarConfig: const BottomActionBarConfig(),
                          searchViewConfig: const SearchViewConfig(),
                        ),
                      ),
                    ),
                  
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Caption input
                          Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _captionController,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Add a caption...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    maxLines: null,
                                    textCapitalization: TextCapitalization.sentences,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: SVAppColorPrimary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: SVAppColorPrimary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        File fileToSend = _editedImageFile ?? widget.file;
                                        
                                        // If there are overlay items, render them to a new image
                                        if (_overlayItems.isNotEmpty && widget.type == 'image') {
                                          final renderedFile = await _renderOverlaysToImage();
                                          if (renderedFile != null) {
                                            fileToSend = renderedFile;
                                          }
                                        }
                                        
                                        widget.onSend(fileToSend, _captionController.text.trim());
                                      },
                                      borderRadius: BorderRadius.circular(25),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (widget.type) {
      case 'image':
        return _buildImagePreview();
      case 'video':
        return _buildVideoPreview();
      case 'document':
        return _buildDocumentPreview();
      default:
        return const Center(
          child: Text('Unsupported file type', style: TextStyle(color: Colors.white)),
        );
    }
  }

  Widget _buildImagePreview() {
    final imageFile = _editedImageFile ?? widget.file;
    
    return RepaintBoundary(
      key: _imageKey,
      child: Stack(
        children: [
          // Base image
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  DebugAttachmentHelper.logImageError(error, stackTrace, 'Image Preview Loading');
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 64),
                        const SizedBox(height: 16),
                        const Text('Failed to load image', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          'Path: ${imageFile.path}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    return child;
                  }
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: child,
                  );
                },
              ),
            ),
          ),
          
          // Overlays (emojis and text)
          ..._overlayItems.map((item) => item.buildWidget(
                onUpdate: () => setState(() {}),
                onDelete: () {
                  setState(() {
                    _overlayItems.remove(item);
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)),
          if (!_videoController!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
            ),
          // Video duration
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
              child: Text(_formatDuration(_videoController!.value.duration), style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final fileName = path.basename(widget.file.path);
    final fileExtension = path.extension(widget.file.path).toLowerCase();
    final fileSize = widget.file.lengthSync();

    IconData iconData;
    Color iconColor;

    switch (fileExtension) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case '.doc':
      case '.docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case '.ppt':
      case '.pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case '.txt':
        iconData = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      case '.zip':
      case '.rar':
        iconData = Icons.folder_zip;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.blueGrey;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              fileName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(_formatFileSize(fileSize), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                fileExtension.replaceAll('.', '').toUpperCase(),
                style: TextStyle(color: iconColor, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Image editing methods
  Future<void> _openImageEditor() async {
    try {
      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: (_editedImageFile ?? widget.file).readAsBytesSync(),
          ),
        ),
      );

      if (editedImage != null) {
        // Save edited image to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(editedImage);

        setState(() {
          _editedImageFile = tempFile;
        });
      }
    } catch (e) {
      debugPrint('Error opening image editor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open image editor'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addEmojiOverlay(String emoji) {
    setState(() {
      _overlayItems.add(
        OverlayItem(
          type: OverlayType.emoji,
          content: emoji,
          position: const Offset(100, 100),
          scale: 1.0,
          rotation: 0.0,
        ),
      );
    });
  }

  Future<void> _addTextOverlay() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Add Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SVAppColorPrimary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SVAppColorPrimary, width: 2),
            ),
          ),
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text('Add', style: TextStyle(color: SVAppColorPrimary)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _overlayItems.add(
          OverlayItem(
            type: OverlayType.text,
            content: result,
            position: const Offset(100, 200),
            scale: 1.0,
            rotation: 0.0,
          ),
        );
      });
    }
  }

  Future<File?> _renderOverlaysToImage() async {
    try {
      final boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rendered_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint('Error rendering overlays: $e');
      return null;
    }
  }
}

// Overlay item class
enum OverlayType { emoji, text }

class OverlayItem {
  final OverlayType type;
  final String content;
  Offset position;
  double scale;
  double rotation;

  OverlayItem({
    required this.type,
    required this.content,
    required this.position,
    required this.scale,
    required this.rotation,
  });

  Widget buildWidget({
    required VoidCallback onUpdate,
    required VoidCallback onDelete,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          position += details.delta;
          onUpdate();
        },
        onScaleUpdate: (details) {
          scale *= details.scale;
          rotation += details.rotation;
          onUpdate();
        },
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: type == OverlayType.emoji
                      ? Text(
                          content,
                          style: const TextStyle(fontSize: 48),
                        )
                      : Text(
                          content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
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
}
