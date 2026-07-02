import 'package:flutter_tts/flutter_tts.dart';

/// Singleton text-to-speech service shared across the app.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _currentlyPlayingId;

  String? get currentlyPlayingId => _currentlyPlayingId;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      _currentlyPlayingId = null;
      _onStateChanged?.call();
    });
    _tts.setCancelHandler(() {
      _currentlyPlayingId = null;
      _onStateChanged?.call();
    });
    _tts.setErrorHandler((msg) {
      _currentlyPlayingId = null;
      _onStateChanged?.call();
    });
  }

  void Function()? _onStateChanged;

  /// Register a callback that fires when TTS starts/stops.
  void setOnStateChanged(void Function()? callback) {
    _onStateChanged = callback;
  }

  /// Speak [text]. If already speaking the same [id], stop instead (toggle).
  Future<void> speak(String text, {String? id}) async {
    await _ensureInit();
    if (_currentlyPlayingId == id && id != null) {
      await stop();
      return;
    }
    await _tts.stop();
    _currentlyPlayingId = id;
    _onStateChanged?.call();
    // Strip markdown formatting for cleaner speech
    final clean = _stripMarkdown(text);
    await _tts.speak(clean);
  }

  Future<void> stop() async {
    await _tts.stop();
    _currentlyPlayingId = null;
    _onStateChanged?.call();
  }

  bool isSpeaking(String id) => _currentlyPlayingId == id;

  /// Rough markdown stripping for spoken output.
  static String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,3}'), '')
        .replaceAll(RegExp(r'_{1,3}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'^\s*[-*+]\s', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s', multiLine: true), '')
        .replaceAll(RegExp(r'>\s?'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
