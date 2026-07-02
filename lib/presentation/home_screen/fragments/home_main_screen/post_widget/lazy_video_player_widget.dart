import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:doctak_app/core/network/video_cache_manager.dart';
import 'package:doctak_app/core/utils/video_url_utils.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_video_page.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../main.dart';
import '../../../../../core/utils/video_utils.dart';
import 'feed_video_autoplay_registry.dart';

/// Lazy video player that only initializes when visible on screen
/// This dramatically improves scrolling performance in post lists
class LazyVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool showMinimalControls;
  /// Optional poster image shown before the user taps play (feed mode).
  final String? thumbnailUrl;
  /// Optional post context shown on the fullscreen player bottom bar.
  final PostImageDetailsContext? detailsContext;

  const LazyVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.showMinimalControls = false,
    this.thumbnailUrl,
    this.detailsContext,
  });

  @override
  State<LazyVideoPlayerWidget> createState() => _LazyVideoPlayerWidgetState();
}

class _LazyVideoPlayerWidgetState extends State<LazyVideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _hasError = false;
  String? _errorMessage;
  bool _isVisible = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _userStartedPlayback = false;
  bool _isAutoplayActive = false;
  late final String _registryId;

  bool get _isFeedMode => widget.showMinimalControls;

  @override
  void initState() {
    super.initState();
    _registryId = '${widget.videoUrl.hashCode}_${identityHashCode(this)}';
  }

  @override
  void dispose() {
    if (_isFeedMode) {
      FeedVideoAutoplayRegistry.instance.removeCandidate(_registryId);
    }
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (info.size.isEmpty || !mounted) return;

    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0.3;

    if (_isFeedMode) {
      if (FeedVideoAutoplayRegistry.instance.isSuspended) {
        if (_isAutoplayActive) _stopCenterAutoplay();
        return;
      }

      final media = MediaQuery.of(context);
      final viewportHeight =
          media.size.height - media.padding.top - media.padding.bottom;
      final viewportCenterY = media.padding.top + viewportHeight / 2;
      final centerDistance = (info.visibleBounds.center.dy - viewportCenterY).abs();
      final maxCenterDistance = viewportHeight * 0.38;

      FeedVideoAutoplayRegistry.instance.updateCandidate(
        id: _registryId,
        centerDistance: centerDistance,
        visibleFraction: info.visibleFraction,
        maxCenterDistance: maxCenterDistance,
        onActivate: _startCenterAutoplay,
        onDeactivate: _stopCenterAutoplay,
      );

      if (!_isVisible && wasVisible && !_isAutoplayActive) {
        _controller?.pause();
      }
      return;
    }

    if (_isVisible && !wasVisible && !_isInitialized && !_isInitializing) {
      _initializeVideoPlayer(previewOnly: false);
    } else if (!_isVisible && wasVisible) {
      _controller?.pause();
    }
  }

  Future<void> _startCenterAutoplay() async {
    if (_isAutoplayActive || _isInitializing) return;
    _isAutoplayActive = true;
    if (mounted) setState(() => _userStartedPlayback = true);

    if (!_isInitialized) {
      await _initializeVideoPlayer(previewOnly: false, autoPlay: true);
      return;
    }

    if (_controller == null) return;
    if (_chewieController == null) {
      _attachChewie(autoPlay: true);
    } else if (!(_controller!.value.isPlaying)) {
      await _controller!.setVolume(1);
      await _controller!.play();
    }
    if (mounted) setState(() {});
  }

  void _stopCenterAutoplay() {
    if (!_isAutoplayActive) {
      _controller?.pause();
      return;
    }
    _isAutoplayActive = false;
    _controller?.pause();
    if (mounted) {
      setState(() => _userStartedPlayback = false);
    }
  }

  void _openFullscreen() {
    _controller?.pause();
    if (!mounted) return;

    openFullScreenVideo(
      context,
      videoUrl: widget.videoUrl,
      thumbnailUrl: widget.thumbnailUrl,
      startPosition: _controller?.value.position,
      detailsContext: widget.detailsContext,
    );
  }

  Future<void> _onFeedPlayTap() async {
    if (_isInitializing) return;
    _isAutoplayActive = true;
    setState(() => _userStartedPlayback = true);

    if (!_isInitialized) {
      await _initializeVideoPlayer(previewOnly: false, autoPlay: true);
      return;
    }

    if (_controller == null) return;

    if (_chewieController == null) {
      _attachChewie(autoPlay: true);
      if (mounted) setState(() {});
      return;
    }

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.setVolume(1);
      await _controller!.play();
    }
    if (mounted) setState(() {});
  }

  void _attachChewie({bool autoPlay = false}) {
    if (_controller == null || _chewieController != null) return;
    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: autoPlay,
      looping: false,
      allowFullScreen: !widget.showMinimalControls,
      allowMuting: true,
      showControls: !widget.showMinimalControls,
      showControlsOnInitialize: false,
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blueAccent,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightBlue,
      ),
      placeholder: _buildPlaceholder(),
      errorBuilder: (context, errorMessage) {
        return _buildErrorWidget('Video playback error: $errorMessage');
      },
    );
  }

  Future<void> _initializeVideoPlayer({
    bool previewOnly = false,
    bool autoPlay = false,
  }) async {
    if (_isInitializing) return;

    if (_isInitialized && _controller != null) {
      if (!previewOnly) {
        await _controller!.setVolume(1);
        _attachChewie(autoPlay: autoPlay);
        if (autoPlay) await _controller!.play();
        if (mounted) setState(() {});
      }
      return;
    }

    _isInitializing = true;

    try {
      final resolvedUrl = VideoUrlUtils.resolveUrl(widget.videoUrl);
      if (VideoUrlUtils.isIosUnsupportedFormat(resolvedUrl)) {
        throw UnsupportedError('Video format not supported on iOS');
      }

      _controller = await _createAndInitVideoController(resolvedUrl);

      if (!mounted) {
        _disposeControllers();
        return;
      }

      final videoInfo = _controller!.value;
      final resolution = videoInfo.size;

      VideoUtils.logVideoInfo(videoInfo, 'Post Video');

      if (!VideoUtils.isResolutionSupported(resolution)) {
        debugPrint('WARNING: Video resolution may not be supported');
      }

      await _controller!.setVolume(previewOnly ? 0 : 1);
      await _controller!.pause();
      await _controller!.seekTo(Duration.zero);

      if (!previewOnly) {
        _attachChewie(autoPlay: autoPlay);
      }

      _isInitialized = true;
      _isInitializing = false;

      if (autoPlay && _controller != null) {
        await _controller!.setVolume(1);
        await _controller!.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _isInitializing = false;
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = VideoUtils.getVideoErrorMessage(e);
        });
      }
    }
  }

  Future<VideoPlayerController> _createAndInitVideoController(
    String resolvedUrl,
  ) async {
    final uri = VideoUrlUtils.resolveUri(resolvedUrl);
    final options = VideoPlayerOptions(
      mixWithOthers: true,
      allowBackgroundPlayback: false,
    );

    final networkController = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: VideoUrlUtils.defaultHeaders,
      videoPlayerOptions: options,
    );

    try {
      await networkController.initialize();
      return networkController;
    } catch (networkError) {
      debugPrint('Network video init failed, trying cached file: $networkError');
      await networkController.dispose();

      if (!Platform.isIOS) rethrow;

      final file = await VideoCacheManager().getVideoFile(resolvedUrl);
      final fileController = VideoPlayerController.file(
        file,
        videoPlayerOptions: options,
      );
      await fileController.initialize();
      return fileController;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: appStore.isDarkMode ? Colors.white70 : Colors.black54,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appStore.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                  _initializeVideoPlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayOverlay({bool loading = false}) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildThumbnailSurface() {
    final thumb = widget.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return AppCachedNetworkImage(
        imageUrl: thumb,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => _buildThumbnailPlaceholder(),
        errorWidget: (_, __, ___) => _buildThumbnailPlaceholder(),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    if (_isInitializing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnailPlaceholder(),
          Container(
            color: Colors.black.withValues(alpha: 0.2),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      );
    }

    return _buildThumbnailPlaceholder();
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: appStore.isDarkMode
              ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
              : [const Color(0xFFE8E8E8), const Color(0xFFCFCFCF)],
        ),
      ),
      child: Icon(
        Icons.videocam_outlined,
        size: 48,
        color: appStore.isDarkMode ? Colors.white24 : Colors.black26,
      ),
    );
  }

  Widget _buildFullscreenHint() {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Double-tap',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedThumbnailCard() {
    return GestureDetector(
      onTap: _onFeedPlayTap,
      onDoubleTap: _openFullscreen,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          _buildThumbnailSurface(),
          if (_isInitializing)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: _buildPlayOverlay(loading: true),
            )
          else if (!_isAutoplayActive &&
              (!_userStartedPlayback || !(_controller?.value.isPlaying ?? false)))
            _buildPlayOverlay(),
          _buildFullscreenHint(),
        ],
      ),
    );
  }

  /// Get a safe aspect ratio, clamped to a feed-friendly range.
  /// Portrait videos are capped at 4:5 (like Instagram) so they don't
  /// fill the entire screen. Landscape videos keep their natural ratio
  /// up to ultra-wide 21:9.
  double get _safeAspectRatio {
    if (_controller == null) return 16 / 9;
    final ratio = _controller!.value.aspectRatio;
    if (ratio <= 0 || ratio.isNaN || ratio.isInfinite || ratio < 0.1 || ratio > 10) {
      return 16 / 9;
    }
    // Clamp: min 4:5 portrait (0.8), max ~21:9 ultra-wide (2.33)
    return ratio.clamp(0.8, 2.4);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_$_registryId'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: _buildContent(),
    );
  }

  Widget _wrapVideo(Widget child, {double aspectRatio = 16 / 9}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxVideoHeight = screenHeight * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxVideoHeight),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _wrapVideo(
        _buildErrorWidget(_errorMessage ?? 'Unknown error occurred'),
      );
    }

    // Feed cards: autoplay when centered; manual tap still toggles playback.
    if (_isFeedMode) {
      if (_userStartedPlayback &&
          _controller != null &&
          _controller!.value.isInitialized &&
          _chewieController != null) {
        return _wrapVideo(
          aspectRatio: _safeAspectRatio,
          GestureDetector(
            onTap: _onFeedPlayTap,
            onDoubleTap: _openFullscreen,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Chewie(controller: _chewieController!),
                if (!_controller!.value.isPlaying)
                  Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: _buildPlayOverlay(),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _openFullscreen,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return _wrapVideo(_buildFeedThumbnailCard());
    }

    if (!_isInitialized) {
      return _wrapVideo(
        GestureDetector(
          onTap: () {
            if (!_isInitializing) {
              _initializeVideoPlayer(autoPlay: true);
            }
          },
          child: _buildThumbnailPlaceholder(),
        ),
      );
    }

    if (_controller != null &&
        _controller!.value.isInitialized &&
        _chewieController != null) {
      return _wrapVideo(
        aspectRatio: _safeAspectRatio,
        ClipRect(child: Chewie(controller: _chewieController!)),
      );
    }

    return _wrapVideo(_buildPlaceholder());
  }
}
