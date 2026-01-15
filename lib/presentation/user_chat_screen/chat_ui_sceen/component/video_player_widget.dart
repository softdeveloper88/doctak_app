import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:doctak_app/main.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  Future<void> initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize()
            .then((_) {
              if (mounted) {
                chewieController = ChewieController(
                  videoPlayerController: _controller!,
                  autoPlay: false,
                  looping: false,
                  errorBuilder: (context, errorMessage) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('Unable to load video', style: TextStyle(color: appStore.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                );
                setState(() {}); // Update UI once the controller has initialized
              }
            })
            .catchError((error) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
            });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: appStore.isDarkMode ? Colors.white70 : Colors.black54, size: 48),
                const SizedBox(height: 8),
                Text('Unable to load video', style: TextStyle(color: appStore.isDarkMode ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Chewie(controller: chewieController!),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9, // Common aspect ratio for videos
        child: Container(
          color: appStore.isDarkMode ? Colors.black : Colors.grey[900],
          child: Center(child: CircularProgressIndicator(color: appStore.isDarkMode ? Colors.white : Colors.blue)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    chewieController?.dispose();
    super.dispose();
  }
}
