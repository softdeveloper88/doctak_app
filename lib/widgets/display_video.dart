import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';
import '../core/utils/video_utils.dart';

class DisplayVideo extends StatefulWidget {
  final File selectedByte;

  const DisplayVideo({super.key, required this.selectedByte});

  @override
  State<DisplayVideo> createState() => DisplayVideoState();
}

class DisplayVideoState extends State<DisplayVideo> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(widget.selectedByte);
      await _controller.initialize();

      if (mounted) {
        // Check video resolution
        final videoInfo = _controller.value;
        final resolution = videoInfo.size;

        // Log video information using utility
        VideoUtils.logVideoInfo(videoInfo, 'Local Video');

        // Check if resolution is supported
        if (!VideoUtils.isResolutionSupported(resolution)) {
          debugPrint('WARNING: Local video resolution may not be supported - ${VideoUtils.getVideoQuality(resolution)}');
        }

        _controller.setLooping(true);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing local video: $e');
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

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SizedBox(
        height: 200,
        child: Container(
          color: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: appStore.isDarkMode ? Colors.white70 : Colors.black54, size: 48),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appStore.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                    _initializeVideo();
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

    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(_controller),
                ClosedCaption(text: _controller.value.caption.text),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.blue,
                    // handleColor: Colors.blueAccent,
                    backgroundColor: Colors.grey,
                    bufferedColor: Colors.lightBlue,
                  ),
                ),
              ],
            ),
          )
        : SizedBox(
            height: 200,
            child: Container(
              color: appStore.isDarkMode ? Colors.black : Colors.grey[900],
              child: Center(child: CircularProgressIndicator(color: appStore.isDarkMode ? Colors.white : Colors.blue)),
            ),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
