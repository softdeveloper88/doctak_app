import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

import '../../../utils/SVCommon.dart';
import '../../../../../main.dart';
import '../../../../../core/utils/video_utils.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

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
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.blue,
            handleColor: Colors.blueAccent,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.lightBlue,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
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
                  initializeVideoPlayer();
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

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildErrorWidget(_errorMessage ?? 'Unknown error occurred'),
      );
    }
    
    if (_controller != null && _controller!.value.isInitialized && chewieController != null) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Chewie(controller: chewieController!),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: appStore.isDarkMode ? Colors.black : Colors.grey[900],
          child: Center(
            child: CircularProgressIndicator(
              color: appStore.isDarkMode ? Colors.white : Colors.blue,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Dispose of the controller when done
    chewieController?.dispose();
    super.dispose();
  }
}
