import 'dart:async';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderWidget extends StatefulWidget {
  final VoidCallback? onStart;
  final ValueChanged<String>? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const AudioRecorderWidget({super.key, this.onStart, this.onStop, this.onPause, this.onResume});

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  String? _recordingPath;

  Future<void> _start() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Microphone permission not granted");
        return;
      }

      // Check if recording is already in progress
      if (await _audioRecorder.isRecording()) {
        return;
      }

      // Generate a temporary file path for the recording
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: _recordingPath ?? '');

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _startTimer();

      if (widget.onStart != null) widget.onStart!();
    } catch (e) {
      debugPrint("Error starting recording: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stop() async {
    try {
      _timer?.cancel();
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (widget.onStop != null && path != null) {
        widget.onStop!(path);
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted && _isRecording) {
        setState(() => _recordDuration++);
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
          child: Icon(CupertinoIcons.mic, color: svGetBodyColor(), size: 25),
        ),
      ),
    );
  }
}
