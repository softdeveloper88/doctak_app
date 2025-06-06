import 'dart:async';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:nb_utils/nb_utils.dart';

class AudioRecorderWidget extends StatefulWidget {
  final VoidCallback? onStart;
  final ValueChanged<String>? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const AudioRecorderWidget({
    Key? key,
    this.onStart,
    this.onStop,
    this.onPause,
    this.onResume,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  Timer? _ampTimer;
  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();

  @override
  void dispose() {
    _timer?.cancel();
    _ampTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Start recording with default settings for compatibility
        await _audioRecorder.start();

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _startTimer();

        if (widget.onStart != null) widget.onStart!();
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
      // Reset state on error
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stop() async {
    try {
      _timer?.cancel();
      _ampTimer?.cancel();
      final String? path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (widget.onStop != null && path != null) widget.onStop!(path);

      // Example: Sending recorded file to the server

    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  // Pause and resume methods available if needed for future features

  void _startTimer() {
    _timer?.cancel();
    _ampTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted && _isRecording) {
        setState(() => _recordDuration++);
      }
    });

    _ampTimer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
      if (mounted && _isRecording) {
        try {
          // Get amplitude for potential visual feedback
          await _audioRecorder.getAmplitude();
        } catch (e) {
          debugPrint('Error getting amplitude: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        await _start();
      },
      onLongPressEnd: (details) async {
        await _stop();
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.fromLTRB(16, 5, 5, 5),
        decoration: BoxDecoration(
          color: _isRecording
              ? Colors.red
              : appStore.isDarkMode
              ? svGetScaffoldColor()
              : cardLightColor,
          shape: BoxShape.circle,
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            CupertinoIcons.mic,
            color: svGetBodyColor(),
            size: 25,
          ),
        ),
      ),
    );
  }
}
