import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:permission_handler/permission_handler.dart';

class WhatsAppVoiceRecorder extends StatefulWidget {
  final Function(String path) onStop;
  final VoidCallback onCancel;
  final bool shouldStopAndSend; // Flag to trigger stop and send

  const WhatsAppVoiceRecorder({
    super.key,
    required this.onStop,
    required this.onCancel,
    this.shouldStopAndSend = false,
  });

  @override
  State<WhatsAppVoiceRecorder> createState() => _WhatsAppVoiceRecorderState();
}

class _WhatsAppVoiceRecorderState extends State<WhatsAppVoiceRecorder>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _timer;
  int _recordDuration = 0;
  double _slidePosition = 0.0;
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  String? _recordPath;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initRecorder();
  }

  @override
  void didUpdateWidget(WhatsAppVoiceRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When shouldStopAndSend changes to true, stop and send the recording
    if (widget.shouldStopAndSend && !oldWidget.shouldStopAndSend && !_isCancelled) {
      print('📤 Stopping and sending recording...');
      _stopRecording(save: true);
    }
  }

  Future<void> _initRecorder() async {
    _isRecorderInitialized = true;
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    // Clean up without sending if dispose is called directly
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        widget.onCancel();
        return;
      }

      if (!_isRecorderInitialized) {
        widget.onCancel();
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _recordPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordPath!,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration++;
        });
      });
    } catch (e) {
      print('Error starting recording: $e');
      widget.onCancel();
    }
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  Future<void> _stopRecording({bool save = true}) async {
    if (!_isRecording) return;

    print('🛑 Stopping recording... save: $save, cancelled: $_isCancelled');

    try {
      _timer?.cancel();
      await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (save && _recordPath != null && !_isCancelled) {
        print('✅ Calling onStop with path: $_recordPath');
        widget.onStop(_recordPath!);
      } else if (_recordPath != null) {
        print('❌ Recording cancelled, deleting file');
        // Delete the file if cancelled
        try {
          await File(_recordPath!).delete();
        } catch (_) {}
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _handleSlide(double dx) {
    setState(() {
      _slidePosition = dx.clamp(0.0, 200.0);
      if (_slidePosition > 150) {
        _isCancelled = true;
        _stopRecording(save: false);
        widget.onCancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding for system navigation bars
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Listener(
      // Detect when user releases finger anywhere on the screen
      onPointerUp: (event) {
        print('👆 Pointer up detected in recorder - stopping and sending');
        if (!_isCancelled) {
          _stopRecording(save: true);
        }
      },
      child: Container(
        // Add padding for system navigation bars
        padding: EdgeInsets.only(bottom: keyboardPadding > 0 ? 0 : bottomPadding),
        decoration: BoxDecoration(
          color: appStore.isDarkMode
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: appStore.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Container(
          height: 60,
          child: Stack(
        children: [
          // Slide to cancel
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                Icon(
                  Icons.chevron_left,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'Slide to cancel',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Recording indicator
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Release to send indicator with mic icon
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                _handleSlide(-details.delta.dx + _slidePosition);
              },
              onHorizontalDragEnd: (_) {
                if (_slidePosition < 150) {
                  setState(() {
                    _slidePosition = 0;
                  });
                }
              },
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: _slidePosition),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        Text(
                          'Release',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SVAppColorPrimary,
                          SVAppColorPrimary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SVAppColorPrimary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    ));
  }
}