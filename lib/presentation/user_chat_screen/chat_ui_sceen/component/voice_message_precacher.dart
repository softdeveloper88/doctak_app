import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'audio_cache_manager.dart';

class VoiceMessagePrecacher extends StatefulWidget {
  final String audioUrl;
  final Widget child;
  
  const VoiceMessagePrecacher({
    Key? key,
    required this.audioUrl,
    required this.child,
  }) : super(key: key);

  @override
  State<VoiceMessagePrecacher> createState() => _VoiceMessagePrecacherState();
}

class _VoiceMessagePrecacherState extends State<VoiceMessagePrecacher> {
  bool _hasPrecached = false;
  final AudioCacheManager _cacheManager = AudioCacheManager();

  Future<void> _precacheAudio() async {
    if (_hasPrecached) return;
    
    _hasPrecached = true;
    
    // Pre-cache the audio file in the background
    try {
      debugPrint('Pre-caching audio: ${widget.audioUrl}');
      await _cacheManager.getCachedAudioPath(widget.audioUrl);
    } catch (e) {
      debugPrint('Error pre-caching audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('voice_precacher_${widget.audioUrl}'),
      onVisibilityChanged: (info) {
        // Start pre-caching when the widget is at least 10% visible
        if (info.visibleFraction > 0.1 && !_hasPrecached) {
          _precacheAudio();
        }
      },
      child: widget.child,
    );
  }
}