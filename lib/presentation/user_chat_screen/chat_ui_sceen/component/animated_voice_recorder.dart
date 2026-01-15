import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:permission_handler/permission_handler.dart';

/// Advanced animated voice recorder with WhatsApp-like animations
/// Features:
/// - Smooth scale animations on mic button
/// - Animated slide-up lock container
/// - Wave animation during recording
/// - Slide to cancel with trash animation
/// - Lock mode for hands-free recording
class AnimatedVoiceRecorder extends StatefulWidget {
  final Function(String path) onStop;
  final VoidCallback onCancel;
  final bool shouldStopAndSend;
  final Offset? initialPointerPosition;

  const AnimatedVoiceRecorder({super.key, required this.onStop, required this.onCancel, this.shouldStopAndSend = false, this.initialPointerPosition});

  @override
  State<AnimatedVoiceRecorder> createState() => _AnimatedVoiceRecorderState();
}

class _AnimatedVoiceRecorderState extends State<AnimatedVoiceRecorder> with TickerProviderStateMixin {
  // Audio recorder
  final AudioRecorder _recorder = AudioRecorder();

  // Track if widget is disposed
  bool _isDisposed = false;

  // Recording state
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isCancelling = false;
  int _recordDuration = 0;
  String? _recordPath;
  Timer? _durationTimer;

  // Gesture tracking
  double _horizontalDrag = 0.0;
  double _verticalDrag = 0.0;
  Offset _startPosition = Offset.zero;
  bool _gestureActive = false;

  // Thresholds
  static const double _cancelThreshold = 100.0;
  static const double _lockThreshold = 80.0;
  static const int _minRecordDuration = 1;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _micScaleController;
  late AnimationController _cancelAnimController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _micScaleAnimation;

  // Haptic flags
  bool _didCancelHaptic = false;
  bool _didLockHaptic = false;

  // Wave amplitudes for visualization
  List<double> _waveAmplitudes = List.generate(30, (i) => 0.3);
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startRecording();

    // If we have an initial pointer position, the user is already holding
    // so activate gesture tracking immediately and add global pointer listener
    if (widget.initialPointerPosition != null) {
      _startPosition = widget.initialPointerPosition!;
      _gestureActive = true;
      _didCancelHaptic = false;
      _didLockHaptic = false;

      // Add global pointer route to track movements
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointerEvent);
      });
    }
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (_isDisposed || _isCancelling) return;

    // If locked, only listen for pointer up to clean up, don't process
    if (_isLocked) {
      if (event is PointerUpEvent || event is PointerCancelEvent) {
        _gestureActive = false;
        _removeGlobalPointerListener();
      }
      return;
    }

    if (!_gestureActive) return;

    if (event is PointerMoveEvent) {
      _handlePointerMove(event.position);
    } else if (event is PointerUpEvent) {
      _handlePointerUp();
    } else if (event is PointerCancelEvent) {
      _handlePointerUp();
    }
  }

  void _handlePointerMove(Offset currentPosition) {
    if (_isDisposed || !_gestureActive || _isLocked || _isCancelling) return;

    // Calculate drag distances
    final horizontal = (_startPosition.dx - currentPosition.dx).clamp(0.0, _cancelThreshold + 60);
    final vertical = (_startPosition.dy - currentPosition.dy).clamp(0.0, _lockThreshold + 60);

    if (_isDisposed) return;

    setState(() {
      _horizontalDrag = horizontal;
      _verticalDrag = vertical;
    });

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
      _removeGlobalPointerListener();
      _cancel();
      return;
    }

    // Check if lock threshold reached
    if (vertical >= _lockThreshold && !_isLocked) {
      // Don't set _gestureActive = false here, let pointer up handle cleanup
      if (!_isDisposed) {
        setState(() {
          _horizontalDrag = 0;
          _verticalDrag = 0;
          _isLocked = true;
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _handlePointerUp() {
    if (!_gestureActive) return;
    _gestureActive = false;
    _removeGlobalPointerListener();

    if (_isDisposed || _isLocked || _isCancelling) return;

    if (_horizontalDrag > _cancelThreshold * 0.6) {
      _cancel();
      return;
    }

    setState(() {
      _horizontalDrag = 0;
      _verticalDrag = 0;
    });

    _sendRecording();
  }

  void _removeGlobalPointerListener() {
    try {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleGlobalPointerEvent);
    } catch (e) {
      debugPrint('Error removing global pointer route: $e');
    }
  }

  void _initAnimations() {
    // Pulse animation for recording indicator
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Wave animation for audio visualization
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);

    // Mic button scale animation
    _micScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _micScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _micScaleController, curve: Curves.elasticOut));
    _micScaleController.forward();

    // Cancel animation
    _cancelAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

    // Start wave simulation
    _startWaveSimulation();
  }

  void _startWaveSimulation() {
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _isRecording) {
        setState(() {
          _waveAmplitudes = List.generate(30, (i) {
            final random = math.Random();
            return 0.2 + random.nextDouble() * 0.6;
          });
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedVoiceRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only auto-send if not locked - when locked, user must tap send button
    if (widget.shouldStopAndSend && !oldWidget.shouldStopAndSend && !_isLocked) {
      _sendRecording();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _removeGlobalPointerListener();
    _durationTimer?.cancel();
    _waveTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _micScaleController.dispose();
    _cancelAnimController.dispose();
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
      _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: _recordPath!);

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

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appStore.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRect(
      clipBehavior: Clip.none,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: (keyboardPadding > 0 ? 0 : bottomPadding) + 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main recording bar - same height as input field
            _buildRecordingBar(textColor, subtleColor, isDark),

            // Animated lock container (slide up)
            if (!_isLocked && _verticalDrag > 15) _buildAnimatedLockContainer(bgColor, subtleColor),

            // Cancel overlay animation
            if (_isCancelling) _buildCancelOverlay(bgColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar(Color textColor, Color subtleColor, bool isDark) {
    final cancelProgress = (_horizontalDrag / _cancelThreshold).clamp(0.0, 1.0);
    final isCancelMode = cancelProgress > 0.5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Recording info container (matches input field style)
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Recording indicator
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4 * _pulseAnimation.value),
                            blurRadius: 6 * _pulseAnimation.value,
                            spreadRadius: 1 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Duration
                Text(
                  _formatDuration(_recordDuration),
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(width: 12),
                // Wave visualization
                Expanded(child: _buildWaveVisualization()),
                const SizedBox(width: 8),
                // Slide to cancel / Cancel button
                if (_isLocked) _buildLockedCancelButton() else _buildSlideToCancel(subtleColor, cancelProgress),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Right side: Mic button (fixed position, same as input field)
        _buildAnimatedMicButton(isCancelMode),
      ],
    );
  }

  Widget _buildWaveVisualization() {
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(12, (index) {
              final amplitude = _waveAmplitudes[index % _waveAmplitudes.length];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 2.5,
                height: 6 + (amplitude * 14),
                decoration: BoxDecoration(
                  color: SVAppColorPrimary.withValues(alpha: 0.5 + amplitude * 0.5),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSlideToCancel(Color subtleColor, double cancelProgress) {
    final isCancelNear = cancelProgress > 0.5;

    return Transform.translate(
      offset: Offset(-_horizontalDrag * 0.3, 0),
      child: AnimatedOpacity(
        opacity: (1.0 - cancelProgress * 0.5).clamp(0.4, 1.0),
        duration: const Duration(milliseconds: 100),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: isCancelNear ? Colors.red.withValues(alpha: 0.15) : Colors.transparent, shape: BoxShape.circle),
              child: Icon(isCancelNear ? Icons.delete_rounded : Icons.chevron_left_rounded, color: isCancelNear ? Colors.red : subtleColor, size: 18),
            ),
            if (cancelProgress < 0.3)
              Text(
                'Slide',
                style: TextStyle(color: subtleColor.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCancelButton() {
    return GestureDetector(
      onTap: _cancel,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, color: Colors.red.shade400, size: 16),
            const SizedBox(width: 4),
            Text(
              'Cancel',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMicButton(bool isCancelMode) {
    final lockProgress = (_verticalDrag / _lockThreshold).clamp(0.0, 1.0);
    // Limit vertical offset to prevent overflow
    final limitedVerticalDrag = _verticalDrag.clamp(0.0, 60.0);

    return Transform.translate(
      offset: Offset(-_horizontalDrag * 0.6, -limitedVerticalDrag * 0.5),
      child: AnimatedBuilder(
        animation: _micScaleAnimation,
        builder: (context, _) {
          final baseScale = _isLocked ? 0.9 : _micScaleAnimation.value;
          final dragScale = 1.0 + lockProgress * 0.15;

          return GestureDetector(
            onTap: _isLocked ? _sendRecording : null,
            child: Transform.scale(
              scale: baseScale * dragScale,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCancelMode ? [Colors.red, Colors.red.shade700] : [SVAppColorPrimary, SVAppColorPrimary.withValues(alpha: 0.75)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isCancelMode ? Colors.red : SVAppColorPrimary).withValues(alpha: _gestureActive ? 0.5 : 0.3),
                      blurRadius: _gestureActive ? 16 : 10,
                      offset: const Offset(0, 3),
                      spreadRadius: _gestureActive ? 2 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isCancelMode ? Icons.delete_rounded : (_isLocked ? Icons.send_rounded : Icons.mic),
                      key: ValueKey(isCancelMode ? 'delete' : (_isLocked ? 'send' : 'mic')),
                      color: Colors.white,
                      size: 24,
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

  Widget _buildAnimatedLockContainer(Color bgColor, Color subtleColor) {
    final lockProgress = (_verticalDrag / _lockThreshold).clamp(0.0, 1.0);
    final containerHeight = (80.0 * lockProgress).clamp(0.0, 80.0);

    return Positioned(
      right: 12,
      bottom: 60,
      child: Container(
        width: 44,
        height: containerHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: lockProgress > 0.7 ? SVAppColorPrimary : (appStore.isDarkMode ? Colors.white24 : Colors.grey.shade300), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: containerHeight > 30
            ? Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: lockProgress > 0.7 ? SVAppColorPrimary.withValues(alpha: 0.2) : Colors.transparent, shape: BoxShape.circle),
                  child: Icon(lockProgress > 0.7 ? Icons.lock_rounded : Icons.lock_open_rounded, color: lockProgress > 0.7 ? SVAppColorPrimary : subtleColor, size: 18),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCancelOverlay(Color bgColor) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _cancelAnimController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.95 * _cancelAnimController.value),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.5 + _cancelAnimController.value * 0.5,
                child: Opacity(
                  opacity: _cancelAnimController.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.red, size: 28),
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
