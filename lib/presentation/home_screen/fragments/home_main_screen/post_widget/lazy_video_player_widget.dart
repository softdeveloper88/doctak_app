import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../main.dart';
import '../../../../../core/utils/video_utils.dart';

/// Lazy video player that only initializes when visible on screen
/// This dramatically improves scrolling performance in post lists
class LazyVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool showMinimalControls;

  const LazyVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.showMinimalControls = false,
  });

  @override
  State<LazyVideoPlayerWidget> createState() => _LazyVideoPlayerWidgetState();
}

class _LazyVideoPlayerWidgetState extends State<LazyVideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _hasError = false;
  String? _errorMessage;
  bool _isVisible = false;
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (info.size.isEmpty) return;
    
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.3; // At least 30% visible

    if (_isVisible && !wasVisible && !_isInitialized && !_isInitializing) {
      // Became visible - initialize
      _initializeVideoPlayer();
    } else if (!_isVisible && wasVisible) {
      // Became invisible - pause video to save resources
      _controller?.pause();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();

      if (!mounted) {
        _disposeControllers();
        return;
      }

      final videoInfo = _controller!.value;
      final resolution = videoInfo.size;

      VideoUtils.logVideoInfo(videoInfo, 'Post Video');

      if (!VideoUtils.isResolutionSupported(resolution)) {
        debugPrint('WARNING: Video resolution may not be supported');
      }

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        allowFullScreen: !widget.showMinimalControls,
        allowMuting: true,
        showControls: !widget.showMinimalControls,
        showControlsOnInitialize: false,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue,
        ),
        placeholder: _buildPlaceholder(),
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget('Video playback error: $errorMessage');
        },
      );

      _isInitialized = true;
      _isInitializing = false;
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _isInitializing = false;
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = VideoUtils.getVideoErrorMessage(e);
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: appStore.isDarkMode ? Colors.white70 : Colors.black54,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appStore.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                  _initializeVideoPlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[300],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: appStore.isDarkMode ? Colors.white54 : Colors.black38,
          ),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Tap to load video',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get a safe aspect ratio, defaulting to 16:9 if invalid
  double get _safeAspectRatio {
    if (_controller == null) return 16 / 9;
    final ratio = _controller!.value.aspectRatio;
    // Check for invalid values: 0, NaN, Infinity, or very extreme ratios
    if (ratio <= 0 || ratio.isNaN || ratio.isInfinite || ratio < 0.1 || ratio > 10) {
      return 16 / 9; // Default to 16:9
    }
    return ratio;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.videoUrl.hashCode}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildErrorWidget(_errorMessage ?? 'Unknown error occurred'),
      );
    }

    if (!_isInitialized) {
      // Show placeholder until initialized
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () {
            if (!_isInitializing) {
              _initializeVideoPlayer();
            }
          },
          child: _buildThumbnailPlaceholder(),
        ),
      );
    }

    if (_controller != null &&
        _controller!.value.isInitialized &&
        _chewieController != null) {
      Widget videoWidget = widget.showMinimalControls
          ? Stack(
              children: [
                Chewie(controller: _chewieController!),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                      setState(() {});
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: !_controller!.value.isPlaying ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Chewie(controller: _chewieController!);

      return widget.showMinimalControls
          ? videoWidget
          : AspectRatio(
              aspectRatio: _safeAspectRatio,
              child: videoWidget,
            );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _buildPlaceholder(),
    );
  }
}
