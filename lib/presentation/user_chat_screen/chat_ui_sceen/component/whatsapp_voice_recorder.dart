import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:permission_handler/permission_handler.dart';

class WhatsAppVoiceRecorder extends StatefulWidget {
  final Function(String path) onStop;
  final VoidCallback onCancel;
  
  const WhatsAppVoiceRecorder({
    super.key,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<WhatsAppVoiceRecorder> createState() => _WhatsAppVoiceRecorderState();
}

class _WhatsAppVoiceRecorderState extends State<WhatsAppVoiceRecorder>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecord _audioRecorder = FlutterSoundRecord();
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _timer;
  int _recordDuration = 0;
  double _slidePosition = 0.0;
  bool _isRecording = false;
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
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _stopRecording(save: false);
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        widget.onCancel();
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _recordPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.start(
        path: _recordPath!,
        encoder: AudioEncoder.AAC,
        bitRate: 128000,
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

    try {
      _timer?.cancel();
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });

      if (save && path != null && !_isCancelled) {
        widget.onStop(path);
      } else if (path != null) {
        // Delete the file if cancelled
        try {
          await File(path).delete();
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

    return Container(
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
          // Send button
          Positioned(
            right: 16 - _slidePosition,
            top: 6,
            bottom: 6,
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
              child: Container(
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
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    _stopRecording(save: true);
                  },
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}