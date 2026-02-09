import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../main.dart';
import '../../../../../core/utils/video_utils.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool showMinimalControls;

  const VideoPlayerWidget({super.key, required this.videoUrl, this.showMinimalControls = false});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? chewieController;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  Future<void> initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await _controller!.initialize();

      if (mounted) {
        // Check video resolution and handle high-resolution videos
        final videoInfo = _controller!.value;
        final resolution = videoInfo.size;

        // Log video information using utility
        VideoUtils.logVideoInfo(videoInfo, 'Post Video');

        // Check if resolution is supported
        if (!VideoUtils.isResolutionSupported(resolution)) {
          debugPrint('WARNING: Video resolution may not be supported - ${VideoUtils.getVideoQuality(resolution)}');
        }

        chewieController = ChewieController(
          videoPlayerController: _controller!,
          autoPlay: false,
          looping: false,
          allowFullScreen: !widget.showMinimalControls,
          allowMuting: true,
          showControls: !widget.showMinimalControls,
          showControlsOnInitialize: false,
          showOptions: false,
          materialProgressColors: ChewieProgressColors(playedColor: Colors.blue, handleColor: Colors.blueAccent, backgroundColor: Colors.grey, bufferedColor: Colors.lightBlue),
          placeholder: Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          errorBuilder: (context, errorMessage) {
            return _buildErrorWidget('Video playback error: $errorMessage');
          },
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    return VideoUtils.getVideoErrorMessage(error);
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
              Icon(Icons.error_outline, color: appStore.isDarkMode ? Colors.white70 : Colors.black54, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: appStore.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                  initializeVideoPlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
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
    if (_hasError) {
      return AspectRatio(aspectRatio: 16 / 9, child: _buildErrorWidget(_errorMessage ?? 'Unknown error occurred'));
    }

    if (_controller != null && _controller!.value.isInitialized && chewieController != null) {
      Widget videoWidget = widget.showMinimalControls
          ? Stack(
              children: [
                Chewie(controller: chewieController!),
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
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Chewie(controller: chewieController!);

      return widget.showMinimalControls ? videoWidget : AspectRatio(aspectRatio: _safeAspectRatio, child: videoWidget);
    } else {
      Widget loadingWidget = Container(
        color: appStore.isDarkMode ? Colors.black : Colors.grey[900],
        child: Center(child: CircularProgressIndicator(color: appStore.isDarkMode ? Colors.white : Colors.blue)),
      );

      return widget.showMinimalControls ? loadingWidget : AspectRatio(aspectRatio: 16 / 9, child: loadingWidget);
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Dispose of the controller when done
    chewieController?.dispose();
    super.dispose();
  }
}
