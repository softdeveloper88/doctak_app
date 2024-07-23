import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../presentation/home_screen/utils/SVCommon.dart';

class DisplayVideo extends StatefulWidget {
  final File selectedByte;

  const DisplayVideo({Key? key, required this.selectedByte}) : super(key: key);

  @override
  State<DisplayVideo> createState() => DisplayVideoState();
}

class DisplayVideoState extends State<DisplayVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.selectedByte)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(_controller),
                ClosedCaption(text: _controller.value.caption.text),
                // _ControlsOverlay(controller: _controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
              ],
            ),
          )
        : SizedBox(
            height: 200,
            child: Center(
                child: CircularProgressIndicator(
              color: svGetBodyColor(),
            )),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
