import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/ios_agora_pip_service.dart';

/// A mixin to add PiP widget capture capability to call screens
/// Captures the call screen widget just before app goes to background
/// and sends it to native iOS for PiP display
mixin PiPWidgetCaptureMixin<T extends StatefulWidget> on State<T> {
  GlobalKey? _pipCaptureKey;
  final IOSAgoraPiPService _iosPipService = IOSAgoraPiPService();

  /// Initialize the capture key - call this in initState
  void initPiPCapture(GlobalKey key) {
    _pipCaptureKey = key;
  }

  /// Capture the current widget state and send to iOS PiP
  /// Call this in didChangeAppLifecycleState when state is inactive or paused
  Future<void> captureWidgetForPiP() async {
    if (!Platform.isIOS) return;
    if (_pipCaptureKey?.currentContext == null) return;

    try {
      final RenderRepaintBoundary? boundary = _pipCaptureKey!.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null || !boundary.attached) {
        debugPrint('📺 PiPCapture: Boundary not ready');
        return;
      }

      // Capture at PiP-appropriate resolution
      const double pixelRatio = 1.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final int width = image.width;
      final int height = image.height;
      image.dispose();

      if (byteData == null) {
        debugPrint('📺 PiPCapture: Failed to get byte data');
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Send to iOS native PiP
      await _iosPipService.updateFrame(pngBytes, width, height);
      debugPrint('📺 PiPCapture: Sent frame ${width}x$height to iOS PiP');
    } catch (e) {
      debugPrint('📺 PiPCapture: Error capturing widget: $e');
    }
  }
}

/// A compact PiP-friendly view to show during call
/// This is designed to look good in the iOS PiP window
class PiPCallView extends StatelessWidget {
  final String contactName;
  final String? avatarUrl;
  final Duration callDuration;
  final bool isVideoCall;
  final bool isMuted;
  final bool isVideoEnabled;

  const PiPCallView({super.key, required this.contactName, this.avatarUrl, required this.callDuration, this.isVideoCall = true, this.isMuted = false, this.isVideoEnabled = true});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade700,
              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
            ),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildInitialAvatar()),
                  )
                : _buildInitialAvatar(),
          ),

          const SizedBox(height: 16),

          // Contact name
          Text(
            contactName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Call duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              _formatDuration(callDuration),
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'monospace'),
            ),
          ),

          const SizedBox(height: 16),

          // Status icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isMuted) _buildStatusIcon(Icons.mic_off, Colors.red),
              if (!isVideoEnabled && isVideoCall) _buildStatusIcon(Icons.videocam_off, Colors.red),
              if (!isMuted && (isVideoEnabled || !isVideoCall)) _buildStatusIcon(isVideoCall ? Icons.videocam : Icons.call, Colors.green),
            ],
          ),

          const SizedBox(height: 20),

          // "In Call" indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green),
              ),
              const SizedBox(width: 6),
              Text('In Call', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
