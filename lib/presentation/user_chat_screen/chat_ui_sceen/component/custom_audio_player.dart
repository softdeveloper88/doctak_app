import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'dart:io';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'audio_cache_manager.dart';
import 'audio_player_manager.dart';

class CustomAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const CustomAudioPlayer({super.key, required this.audioUrl, required this.isMe});

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  AudioPlayer? _audioPlayer;
  bool _playerReady = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _currentSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _disposePlayer() {
    final player = _audioPlayer;
    _audioPlayer = null;
    _playerReady = false;
    if (player != null) {
      AudioPlayerManager().unregisterPlayer(player);
      player.dispose();
    }
  }

  Map<String, String> _audioHeaders() {
    final headers = <String, String>{
      'User-Agent': 'DocTak/1.0',
      'Accept': 'audio/*,*/*',
    };
    final token = AppData.userToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> _initializePlayer() async {
    if (widget.audioUrl.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _playerReady = false;
        });
      }
      return;
    }

    final player = AudioPlayer();

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _playerReady = false;
        });
      }

      // Try to get cached audio first
      final cacheManager = AudioCacheManager();
      final cachedPath = await cacheManager.getCachedAudioPath(widget.audioUrl);

      if (!mounted) {
        await player.dispose();
        return;
      }

      if (cachedPath != null && await File(cachedPath).exists()) {
        debugPrint('Playing from cache: $cachedPath');
        await player.setFilePath(cachedPath);
      } else {
        debugPrint('Streaming from URL: ${widget.audioUrl}');
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(widget.audioUrl),
            headers: _audioHeaders(),
          ),
          preload: true,
        );
      }

      if (!mounted) {
        await player.dispose();
        return;
      }

      _audioPlayer = player;

      // Listen to player state
      player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });

          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
            });
          }
        }
      });

      player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      player.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _playerReady = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      await player.dispose();
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _playerReady = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(CustomAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _disposePlayer();
      _isPlaying = false;
      _duration = Duration.zero;
      _position = Duration.zero;
      _hasError = false;
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final player = _audioPlayer;
    if (player == null) return;
    try {
      if (_isPlaying) {
        await player.pause();
      } else {
        AudioPlayerManager().registerPlayer(player, widget.audioUrl);

        if (_position >= _duration && _duration > Duration.zero) {
          await player.seek(Duration.zero);
        }
        await player.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  Future<void> _changeSpeed(double speed) async {
    final player = _audioPlayer;
    if (player == null) return;
    try {
      await player.setSpeed(speed);
      setState(() {
        _currentSpeed = speed;
      });
    } catch (e) {
      debugPrint('Error changing speed: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: widget.isMe ? Colors.white70 : Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Audio unavailable',
              style: TextStyle(fontSize: 12, color: widget.isMe ? Colors.white70 : Colors.grey[600], fontFamily: 'Poppins'),
            ),
          ],
        ),
      );
    }

    if (!_playerReady || _audioPlayer == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.isMe ? Colors.white70 : SVAppColorPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading voice…',
              style: TextStyle(
                fontSize: 12,
                color: widget.isMe ? Colors.white70 : Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    final player = _audioPlayer!;
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65, minWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          InkWell(
            onTap: _isLoading ? null : _togglePlayPause,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.white.withValues(alpha: 0.2) : (appStore.isDarkMode ? SVAppColorPrimary.withValues(alpha: 0.2) : SVAppColorPrimary.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(widget.isMe ? Colors.white : SVAppColorPrimary)),
                      ),
                    )
                  : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: widget.isMe ? Colors.white : (appStore.isDarkMode ? Colors.white : SVAppColorPrimary), size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: widget.isMe ? Colors.white : SVAppColorPrimary,
                    inactiveTrackColor: widget.isMe ? Colors.white.withValues(alpha: 0.3) : SVAppColorPrimary.withValues(alpha: 0.3),
                    thumbColor: widget.isMe ? Colors.white : SVAppColorPrimary,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 3,
                  ),
                  child: StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      return Slider(
                        value: position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                        max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                        onChanged: (value) async {
                          final newPosition = Duration(milliseconds: value.toInt());
                          await player.seek(newPosition);
                        },
                        onChangeStart: (_) {
                          player.pause();
                        },
                        onChangeEnd: (_) {
                          if (_isPlaying) {
                            player.play();
                          }
                        },
                      );
                    },
                  ),
                ),
                // Duration text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 10, color: widget.isMe ? Colors.white.withValues(alpha: 0.8) : (appStore.isDarkMode ? Colors.white60 : Colors.grey[600]), fontFamily: 'Poppins'),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(fontSize: 10, color: widget.isMe ? Colors.white.withValues(alpha: 0.8) : (appStore.isDarkMode ? Colors.white60 : Colors.grey[600]), fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Speed control
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Playback Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ...List.generate(
                        _speedOptions.length,
                        (index) => ListTile(
                          title: Text(
                            '${_speedOptions[index]}x',
                            style: TextStyle(
                              color: _currentSpeed == _speedOptions[index] ? Theme.of(context).primaryColor : null,
                              fontWeight: _currentSpeed == _speedOptions[index] ? FontWeight.bold : null,
                            ),
                          ),
                          trailing: _currentSpeed == _speedOptions[index] ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                          onTap: () {
                            _changeSpeed(_speedOptions[index]);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: widget.isMe ? Colors.white.withValues(alpha: 0.2) : SVAppColorPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${_currentSpeed}x',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.isMe ? Colors.white : (appStore.isDarkMode ? Colors.white : SVAppColorPrimary), fontFamily: 'Poppins'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
