import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../utils/SVCommon.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  Future<void> initializeVideoPlayer() async {
    _controller ??= VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          chewieController = ChewieController(
            videoPlayerController: _controller!,
            autoPlay: false,
            looping: false,
          );
          setState(() {}); // Update UI once the controller has initialized
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Chewie(controller: chewieController!),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9, // Common aspect ratio for videos
        child: Container(
          color: Colors.black, // Video player typically has a black background
          child:  Center(
            child: CircularProgressIndicator(color: svGetBodyColor(),), // Loading indicator
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
