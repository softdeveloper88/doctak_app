import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:doctak_app/core/network/video_cache_manager.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/video_url_utils.dart';
import 'package:doctak_app/core/utils/video_utils.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Opens a fullscreen video player with standard playback controls.
void openFullScreenVideo(
  BuildContext context, {
  required String videoUrl,
  String? thumbnailUrl,
  Duration? startPosition,
  PostImageDetailsContext? detailsContext,
}) {
  final nav = Navigator.of(context);
  PostImageDetailsContext? wrappedDetails = detailsContext;
  if (detailsContext?.onOpenPost != null) {
    final openPost = detailsContext!.onOpenPost!;
    wrappedDetails = PostImageDetailsContext(
      title: detailsContext.title,
      body: detailsContext.body,
      authorName: detailsContext.authorName,
      likeCount: detailsContext.likeCount,
      commentCount: detailsContext.commentCount,
      onOpenPost: () {
        nav.pop();
        openPost();
      },
    );
  }

  nav.push(
    MaterialPageRoute(
      builder: (_) => FullScreenVideoPage(
        videoUrl: AppData.fullImageUrl(videoUrl),
        thumbnailUrl: thumbnailUrl != null ? AppData.fullImageUrl(thumbnailUrl) : null,
        startPosition: startPosition,
        detailsContext: wrappedDetails,
      ),
    ),
  );
}

class FullScreenVideoPage extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final Duration? startPosition;
  final PostImageDetailsContext? detailsContext;

  const FullScreenVideoPage({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.startPosition,
    this.detailsContext,
  });

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _hasError = false;
  String? _errorMessage;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initPlayer();
  }

  Future<VideoPlayerController> _createAndInitController(String resolvedUrl) async {
    final uri = VideoUrlUtils.resolveUri(resolvedUrl);
    final options = VideoPlayerOptions(
      mixWithOthers: false,
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

  Future<void> _initPlayer() async {
    try {
      final resolvedUrl = VideoUrlUtils.resolveUrl(widget.videoUrl);
      if (VideoUrlUtils.isIosUnsupportedFormat(resolvedUrl)) {
        throw UnsupportedError('Video format not supported on iOS');
      }

      final controller = await _createAndInitController(resolvedUrl);
      VideoUtils.logVideoInfo(controller.value, 'Fullscreen Video');

      if (widget.startPosition != null && widget.startPosition! > Duration.zero) {
        await controller.seekTo(widget.startPosition!);
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        showControlsOnInitialize: true,
        showOptions: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF4A90E2),
          handleColor: const Color(0xFF6BA3F5),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white54),
        ),
        errorBuilder: (_, msg) => _errorView(msg),
      );

      setState(() {
        _controller = controller;
        _chewie = chewie;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = VideoUtils.getVideoErrorMessage(e);
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _initializing = true;
                });
                _initPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final ctx = widget.detailsContext;
    if (ctx == null) return const SizedBox.shrink();
    final caption = ctx.title ?? ctx.body;
    if ((ctx.authorName == null || ctx.authorName!.isEmpty) &&
        (caption == null || caption.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ctx.authorName != null && ctx.authorName!.isNotEmpty)
            Text(
              ctx.authorName!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
          ],
          if (ctx.onOpenPost != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: ctx.onOpenPost,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: const Text('View post'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _hasError
                  ? _errorView(_errorMessage ?? 'Playback error')
                  : _initializing || _chewie == null
                      ? const Center(child: CircularProgressIndicator(color: Colors.white54))
                      : Center(child: Chewie(controller: _chewie!)),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }
}
