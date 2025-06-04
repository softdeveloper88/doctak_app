import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'dart:io';
import 'audio_cache_manager.dart';
import 'audio_player_manager.dart';

class CustomAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const CustomAudioPlayer({
    Key? key,
    required this.audioUrl,
    required this.isMe,
  }) : super(key: key);

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  late AudioPlayer _audioPlayer;
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

  Future<void> _initializePlayer() async {
    _audioPlayer = AudioPlayer();
    
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Try to get cached audio first
      final cacheManager = AudioCacheManager();
      final cachedPath = await cacheManager.getCachedAudioPath(widget.audioUrl);
      
      if (cachedPath != null && await File(cachedPath).exists()) {
        // Play from cache
        debugPrint('Playing from cache: $cachedPath');
        await _audioPlayer.setFilePath(cachedPath);
      } else {
        // Fallback to streaming from URL (will be cached for next time)
        debugPrint('Streaming from URL: ${widget.audioUrl}');
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(widget.audioUrl),
            headers: {
              'User-Agent': 'DocTak/1.0',
            },
          ),
          preload: true,
        );
      }

      // Listen to player state
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
          
          // Check if playback completed
          if (state.processingState == ProcessingState.completed) {
            // Just stop playing, keep position at end
            setState(() {
              _isPlaying = false;
            });
          }
        }
      });

      // Listen to duration
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Listen to position with smoother updates
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Listen for errors
      _audioPlayer.playbackEventStream.listen(
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    AudioPlayerManager().unregisterPlayer(_audioPlayer);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Register this player with the manager (will stop any other playing audio)
        AudioPlayerManager().registerPlayer(_audioPlayer, widget.audioUrl);
        
        // If at the end, seek to beginning first
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  Future<void> _changeSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
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
            Icon(
              Icons.error_outline,
              color: widget.isMe ? Colors.white70 : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Audio unavailable',
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

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
        minWidth: 200,
      ),
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
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : (appStore.isDarkMode
                        ? SVAppColorPrimary.withOpacity(0.2)
                        : SVAppColorPrimary.withOpacity(0.1)),
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isMe
                                ? Colors.white
                                : SVAppColorPrimary,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe
                          ? Colors.white
                          : (appStore.isDarkMode
                              ? Colors.white
                              : SVAppColorPrimary),
                      size: 20,
                    ),
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
                    activeTrackColor: widget.isMe
                        ? Colors.white
                        : SVAppColorPrimary,
                    inactiveTrackColor: widget.isMe
                        ? Colors.white.withOpacity(0.3)
                        : SVAppColorPrimary.withOpacity(0.3),
                    thumbColor: widget.isMe
                        ? Colors.white
                        : SVAppColorPrimary,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    trackHeight: 3,
                  ),
                  child: StreamBuilder<Duration>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      return Slider(
                        value: position.inMilliseconds.toDouble().clamp(
                          0.0,
                          _duration.inMilliseconds.toDouble(),
                        ),
                        max: _duration.inMilliseconds.toDouble() > 0 
                            ? _duration.inMilliseconds.toDouble() 
                            : 1.0,
                        onChanged: (value) async {
                          final newPosition = Duration(milliseconds: value.toInt());
                          await _audioPlayer.seek(newPosition);
                        },
                        onChangeStart: (_) {
                          _audioPlayer.pause();
                        },
                        onChangeEnd: (_) {
                          if (_isPlaying) {
                            _audioPlayer.play();
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
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isMe
                              ? Colors.white.withOpacity(0.8)
                              : (appStore.isDarkMode
                                  ? Colors.white60
                                  : Colors.grey[600]),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.isMe
                              ? Colors.white.withOpacity(0.8)
                              : (appStore.isDarkMode
                                  ? Colors.white60
                                  : Colors.grey[600]),
                          fontFamily: 'Poppins',
                        ),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Playback Speed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...List.generate(
                        _speedOptions.length,
                        (index) => ListTile(
                          title: Text(
                            '${_speedOptions[index]}x',
                            style: TextStyle(
                              color: _currentSpeed == _speedOptions[index]
                                  ? Theme.of(context).primaryColor
                                  : null,
                              fontWeight: _currentSpeed == _speedOptions[index]
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                          trailing: _currentSpeed == _speedOptions[index]
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
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
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.2)
                    : SVAppColorPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentSpeed}x',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isMe
                      ? Colors.white
                      : (appStore.isDarkMode
                          ? Colors.white
                          : SVAppColorPrimary),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}