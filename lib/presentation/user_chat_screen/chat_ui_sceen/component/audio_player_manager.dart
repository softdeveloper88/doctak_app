import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal();

  AudioPlayer? _currentPlayer;
  String? _currentAudioUrl;

  /// Registers a new audio player and stops any currently playing audio
  void registerPlayer(AudioPlayer player, String audioUrl) {
    // If there's a different audio playing, stop it
    if (_currentPlayer != null && _currentAudioUrl != audioUrl) {
      _currentPlayer!.stop();
    }

    _currentPlayer = player;
    _currentAudioUrl = audioUrl;
  }

  /// Unregisters a player when it's disposed
  void unregisterPlayer(AudioPlayer player) {
    if (_currentPlayer == player) {
      _currentPlayer = null;
      _currentAudioUrl = null;
    }
  }

  /// Stops any currently playing audio
  void stopCurrentPlayer() {
    _currentPlayer?.stop();
  }
}
