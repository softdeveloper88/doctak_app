import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:path/path.dart' as path;
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
                          onPressed: () {
                            // TODO: Implement image editing
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                          onPressed: () {
                            // TODO: Implement sticker/emoji overlay
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_fields, color: Colors.white),
                          onPressed: () {
                            // TODO: Implement text overlay
                          },
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent]),
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
                                  onTap: () {
                                    widget.onSend(widget.file, _captionController.text.trim());
                                    // Don't pop here - let the onSend callback handle navigation
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
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          widget.file,
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
                  Text('Failed to load image', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'Path: ${widget.file.path}',
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
            return AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 300), child: child);
          },
        ),
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
}
