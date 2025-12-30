import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:permission_handler/permission_handler.dart';

/// WhatsApp-style voice recorder with:
/// - Hold to record
/// - Slide left to cancel
/// - Slide up to lock (hands-free mode)
/// - Smooth animations and haptic feedback
class WhatsAppVoiceRecorder extends StatefulWidget {
  final Function(String path) onStop;
  final VoidCallback onCancel;
  final bool shouldStopAndSend;

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
    with TickerProviderStateMixin {
  // Audio recorder
  final AudioRecorder _recorder = AudioRecorder();

  // Track if widget is disposed to prevent ValueNotifier updates after dispose
  bool _isDisposed = false;

  // Recording state
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isCancelling = false;
  int _recordDuration = 0;
  String? _recordPath;
  Timer? _durationTimer;

  // Gesture tracking - using ValueNotifier for smooth updates without setState
  final ValueNotifier<double> _horizontalDrag = ValueNotifier(0.0);
  final ValueNotifier<double> _verticalDrag = ValueNotifier(0.0);
  Offset _startPosition = Offset.zero;
  bool _gestureActive = false;

  // Thresholds
  static const double _cancelThreshold = 120.0;
  static const double _lockThreshold = 100.0;
  static const int _minRecordDuration = 1;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _cancelAnimController;

  // Haptic flags
  bool _didCancelHaptic = false;
  bool _didLockHaptic = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startRecording();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _cancelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(WhatsAppVoiceRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldStopAndSend && !oldWidget.shouldStopAndSend) {
      _sendRecording();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _durationTimer?.cancel();
    _pulseController.dispose();
    _cancelAnimController.dispose();
    _horizontalDrag.dispose();
    _verticalDrag.dispose();
    _cleanupRecorder();
    super.dispose();
  }

  Future<void> _cleanupRecorder() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e) {
      debugPrint('Error cleaning up recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _cancel();
          return;
        }
      }

      // Get temp directory and create file path
      final dir = await getTemporaryDirectory();
      _recordPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordPath!,
      );

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
      }

      // Light haptic on start
      HapticFeedback.lightImpact();

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordDuration++;
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _cancel();
    }
  }

  Future<void> _sendRecording() async {
    if (_isCancelling || !_isRecording) return;

    _durationTimer?.cancel();

    try {
      final path = await _recorder.stop();

      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }

      // Check minimum duration
      if (_recordDuration < _minRecordDuration) {
        debugPrint('Recording too short: $_recordDuration seconds');
        await _deleteRecordingFile();
        if (mounted) widget.onCancel();
        return;
      }

      // Check file exists and has content
      if (path != null && _recordPath != null) {
        final file = File(_recordPath!);
        if (await file.exists() && await file.length() > 0) {
          HapticFeedback.lightImpact();
          if (mounted) widget.onStop(_recordPath!);
          return;
        }
      }

      // File doesn't exist or is empty
      if (mounted) widget.onCancel();
    } catch (e) {
      debugPrint('Error sending recording: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _cancel() async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    _durationTimer?.cancel();

    // Animate cancel
    await _cancelAnimController.forward();
    HapticFeedback.mediumImpact();

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }

    await _deleteRecordingFile();

    // Small delay for animation
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) widget.onCancel();
  }

  Future<void> _deleteRecordingFile() async {
    if (_recordPath != null) {
      try {
        final file = File(_recordPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isLocked || _isCancelling) return;
    _startPosition = event.position;
    _gestureActive = true;
    _didCancelHaptic = false;
    _didLockHaptic = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDisposed || !_gestureActive || _isLocked || _isCancelling) return;

    final current = event.position;

    // Calculate drag distances (positive = moved left/up)
    final horizontal = (_startPosition.dx - current.dx).clamp(0.0, _cancelThreshold + 60);
    final vertical = (_startPosition.dy - current.dy).clamp(0.0, _lockThreshold + 60);

    // Check again before updating ValueNotifiers (they may be disposed during async operations)
    if (_isDisposed) return;
    _horizontalDrag.value = horizontal;
    _verticalDrag.value = vertical;

    // Haptic feedback when approaching thresholds
    if (horizontal > _cancelThreshold * 0.7 && !_didCancelHaptic) {
      _didCancelHaptic = true;
      HapticFeedback.selectionClick();
    }

    if (vertical > _lockThreshold * 0.7 && !_didLockHaptic && !_isLocked) {
      _didLockHaptic = true;
      HapticFeedback.selectionClick();
    }

    // Check if cancel threshold reached
    if (horizontal >= _cancelThreshold) {
      _gestureActive = false;
      _cancel();
      return;
    }

    // Check if lock threshold reached
    if (vertical >= _lockThreshold && !_isLocked) {
      _gestureActive = false;
      if (!_isDisposed) {
        _horizontalDrag.value = 0;
        _verticalDrag.value = 0;
        setState(() {
          _isLocked = true;
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_gestureActive) return;
    _gestureActive = false;

    if (_isDisposed || _isLocked || _isCancelling) return;

    // If drag was significant towards cancel, cancel
    if (_horizontalDrag.value > _cancelThreshold * 0.6) {
      _cancel();
      return;
    }

    // Reset drags safely
    if (!_isDisposed) {
      _horizontalDrag.value = 0;
      _verticalDrag.value = 0;
    }

    // Send the recording
    _sendRecording();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!_gestureActive) return;
    _gestureActive = false;

    if (_isDisposed || _isLocked || _isCancelling) return;

    // If cancelled while dragging, check if should cancel recording
    if (_horizontalDrag.value > _cancelThreshold * 0.5) {
      _cancel();
      return;
    }

    // Reset drags safely
    if (!_isDisposed) {
      _horizontalDrag.value = 0;
      _verticalDrag.value = 0;
    }

    // Send the recording
    _sendRecording();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appStore.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 8),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main recording bar
            _buildRecordingBar(textColor, subtleColor, bgColor),

            // Lock indicator floating above (when swiping up)
            ValueListenableBuilder<double>(
              valueListenable: _verticalDrag,
              builder: (context, vDrag, _) {
                if (_isLocked || vDrag <= 20) return const SizedBox.shrink();
                return _buildFloatingLockIndicator(vDrag, bgColor, subtleColor);
              },
            ),

            // Cancel overlay animation
            if (_isCancelling) _buildCancelOverlay(bgColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar(Color textColor, Color subtleColor, Color bgColor) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Left side: Cancel area
          Expanded(
            child: _isLocked
                ? _buildLockedCancelButton()
                : _buildSlideToCancel(subtleColor),
          ),

          // Center: Duration display
          _buildDurationDisplay(textColor),

          // Right side: Mic button or Send button
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isLocked) _buildLockHint(subtleColor),
                if (_isLocked) _buildSendButton(),
                const SizedBox(width: 8),
                _buildMicButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideToCancel(Color subtleColor) {
    return ValueListenableBuilder<double>(
      valueListenable: _horizontalDrag,
      builder: (context, hDrag, _) {
        final cancelProgress = (hDrag / _cancelThreshold).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(-hDrag * 0.4, 0),
          child: Opacity(
            opacity: (1.0 - cancelProgress * 0.5).clamp(0.3, 1.0),
            child: Row(
              children: [
                // Trash/chevron icon with scale animation
                Transform.scale(
                  scale: 1.0 + cancelProgress * 0.3,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cancelProgress > 0.5
                          ? Colors.red.withOpacity(0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cancelProgress > 0.5
                          ? Icons.delete_rounded
                          : Icons.chevron_left_rounded,
                      color: cancelProgress > 0.5 ? Colors.red : subtleColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // "Slide to cancel" text
                AnimatedOpacity(
                  opacity: cancelProgress > 0.3 ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    'Slide to cancel',
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedCancelButton() {
    return GestureDetector(
      onTap: _cancel,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
            SizedBox(width: 6),
            Text(
              'Cancel',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDisplay(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing red dot
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final scale = 0.8 + _pulseController.value * 0.4;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Text(
          _formatDuration(_recordDuration),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildLockHint(Color subtleColor) {
    return ValueListenableBuilder<double>(
      valueListenable: _verticalDrag,
      builder: (context, vDrag, _) {
        final lockProgress = (vDrag / _lockThreshold).clamp(0.0, 1.0);

        return ValueListenableBuilder<double>(
          valueListenable: _horizontalDrag,
          builder: (context, hDrag, _) {
            final cancelProgress = (hDrag / _cancelThreshold).clamp(0.0, 1.0);

            return AnimatedOpacity(
              opacity: 1.0 - cancelProgress,
              duration: const Duration(milliseconds: 100),
              child: Transform.translate(
                offset: Offset(0, -vDrag * 0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.0 + lockProgress * 0.2,
                      child: Icon(
                        lockProgress > 0.5
                            ? Icons.lock_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: lockProgress > 0.5
                            ? SVAppColorPrimary
                            : subtleColor,
                        size: 18,
                      ),
                    ),
                    if (lockProgress < 0.5)
                      Text(
                        'Lock',
                        style: TextStyle(color: subtleColor, fontSize: 10),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendRecording,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: SVAppColorPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Send',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return ValueListenableBuilder<double>(
      valueListenable: _horizontalDrag,
      builder: (context, hDrag, _) {
        final cancelProgress = (hDrag / _cancelThreshold).clamp(0.0, 1.0);
        final isCancelMode = cancelProgress > 0.5;

        return ValueListenableBuilder<double>(
          valueListenable: _verticalDrag,
          builder: (context, vDrag, _) {
            final lockProgress = (vDrag / _lockThreshold).clamp(0.0, 1.0);

            return Transform.translate(
              offset: Offset(-hDrag * 0.8, -vDrag * 0.5),
              child: AnimatedScale(
                scale: _isLocked ? 0.85 : (1.0 + lockProgress * 0.15),
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCancelMode
                          ? [Colors.red, Colors.red.shade700]
                          : [
                              SVAppColorPrimary,
                              SVAppColorPrimary.withOpacity(0.8)
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isCancelMode ? Colors.red : SVAppColorPrimary)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCancelMode
                        ? Icons.delete_rounded
                        : (_isLocked ? Icons.stop_rounded : Icons.mic),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingLockIndicator(
      double vDrag, Color bgColor, Color subtleColor) {
    final lockProgress = (vDrag / _lockThreshold).clamp(0.0, 1.0);

    return Positioned(
      right: 20,
      bottom: 56 + vDrag * 0.7,
      child: AnimatedOpacity(
        opacity: (vDrag / 40).clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lockProgress > 0.7 ? SVAppColorPrimary : bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: lockProgress > 0.7
                  ? SVAppColorPrimary
                  : (appStore.isDarkMode
                      ? Colors.white24
                      : Colors.grey.shade300),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_rounded,
            color: lockProgress > 0.7 ? Colors.white : subtleColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelOverlay(Color bgColor) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _cancelAnimController,
        builder: (context, _) {
          return Container(
            color: bgColor.withOpacity(0.95 * _cancelAnimController.value),
            child: Center(
              child: Transform.scale(
                scale: 0.5 + _cancelAnimController.value * 0.5,
                child: Opacity(
                  opacity: _cancelAnimController.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
