// full_screen_image_page.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/network/custom_cache_manager.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:gal/gal.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/utils/post_utils.dart';
import '../../../../data/models/post_model/post_data_model.dart';
import 'full_screen_video_page.dart';

/// Lightweight post metadata for the details overlay when a legacy [Post] is unavailable.
class PostImageDetailsContext {
  final String? title;
  final String? body;
  final String? authorName;
  final int likeCount;
  final int commentCount;
  final VoidCallback? onOpenPost;

  const PostImageDetailsContext({
    this.title,
    this.body,
    this.authorName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.onOpenPost,
  });
}

class FullScreenImagePage extends StatefulWidget {
  final String? imageUrl;
  final Post? post;
  final PostImageDetailsContext? detailsContext;
  final int listCount;
  final List<Map<String, String>>? mediaUrls;

  const FullScreenImagePage({
    super.key,
    required this.listCount,
    this.imageUrl,
    this.post,
    this.detailsContext,
    this.mediaUrls,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _captionExpanded = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  bool get _hasDetailsPanel => widget.post != null || widget.detailsContext != null;

  List<Map<String, String>> get _resolvedMedia {
    if (widget.mediaUrls != null && widget.mediaUrls!.isNotEmpty) {
      return widget.mediaUrls!;
    }
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return [{'url': widget.imageUrl!, 'type': 'image'}];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    final media = _resolvedMedia;
    var initialPage = 0;
    if (widget.imageUrl != null && media.length > 1) {
      final index = media.indexWhere((m) => m['url'] == widget.imageUrl);
      if (index != -1) initialPage = index;
    }
    _currentIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _safeUrl(String? raw) => AppData.fullImageUrl(raw ?? '');

  ImageProvider _imageProvider(String url) {
    final safe = _safeUrl(url);
    return CachedNetworkImageProvider(
      safe,
      // Private media (e.g. chat attachments) requires the bearer token.
      headers: AppData.mediaHeadersFor(safe),
      cacheManager: CustomCacheManager(),
    );
  }

  String _getCurrentMediaUrl() {
    final media = _resolvedMedia;
    if (media.isEmpty) return widget.imageUrl ?? '';
    return media[_currentIndex.clamp(0, media.length - 1)]['url'] ?? '';
  }

  String? _captionText() {
    if (widget.post?.title != null && widget.post!.title!.isNotEmpty) {
      return widget.post!.title;
    }
    final ctx = widget.detailsContext;
    if (ctx?.title != null && ctx!.title!.isNotEmpty) return ctx.title;
    return ctx?.body;
  }

  String? _authorName() {
    return widget.detailsContext?.authorName;
  }

  int _likeCount() {
    if (widget.post != null) return widget.post!.likes?.length ?? 0;
    return widget.detailsContext?.likeCount ?? 0;
  }

  int _commentCount() {
    if (widget.post != null) return widget.post!.comments?.length ?? 0;
    return widget.detailsContext?.commentCount ?? 0;
  }

  VoidCallback? _onOpenPost() => widget.detailsContext?.onOpenPost;

  Future<void> _downloadCurrent() async {
    final url = _getCurrentMediaUrl();
    if (url.isEmpty || _downloading) return;

    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
        if (!await Gal.hasAccess()) {
          _toast('Permission denied', Icons.error, Colors.red);
          return;
        }
      }
    } catch (_) {
      _toast('Permission denied', Icons.error, Colors.red);
      return;
    }

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    final isVideo = _isVideoUrl(url);
    final ext = isVideo ? '.mp4' : '.jpg';
    final fileName = 'DocTak_${DateTime.now().millisecondsSinceEpoch}$ext';

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';
      await Dio().download(
        _safeUrl(url),
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      if (isVideo) {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }
      final file = File(path);
      if (await file.exists()) await file.delete();
      _toast(isVideo ? 'Video saved' : 'Image saved', Icons.check_circle, Colors.green);
    } catch (_) {
      _toast('Download failed', Icons.error, Colors.red);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _toast(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].any(lower.contains);
  }

  bool _isHtml(String text) => RegExp(r'<[^>]*>').hasMatch(text);

  void _openVideoFullscreen(Map<String, String> item) {
    openFullScreenVideo(
      context,
      videoUrl: item['url']!,
      detailsContext: widget.detailsContext,
    );
  }

  Widget _buildImagePage(Map<String, String> item) {
    if (item['type'] == 'video') {
      return GestureDetector(
        onDoubleTap: () => _openVideoFullscreen(item),
        onTap: () => _openVideoFullscreen(item),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Container(color: Colors.black),
            const Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 72),
            Positioned(
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to play fullscreen',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PhotoView(
      imageProvider: _imageProvider(item['url']!),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      initialScale: PhotoViewComputedScale.contained,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (_, event) => Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white54,
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        ),
      ),
      errorBuilder: (_, _, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 56),
          const SizedBox(height: 12),
          Text(
            'Image failed to load',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<Map<String, String>> media) {
    if (media.length == 1) {
      return _buildImagePage(media.first);
    }

    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      pageController: _pageController,
      itemCount: media.length,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onPageChanged: (i) => setState(() => _currentIndex = i),
      builder: (_, index) {
        final item = media[index];
        if (item['type'] == 'video') {
          return PhotoViewGalleryPageOptions.customChild(
            child: GestureDetector(
              onDoubleTap: () => _openVideoFullscreen(item),
              onTap: () => _openVideoFullscreen(item),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.black),
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 72),
                  const Positioned(
                    bottom: 32,
                    child: Text(
                      'Tap to play fullscreen',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained,
            initialScale: PhotoViewComputedScale.contained,
          );
        }
        return PhotoViewGalleryPageOptions(
          imageProvider: _imageProvider(item['url']!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white38, size: 48),
        );
      },
    );
  }

  Widget _topBar(int mediaCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          ),
          Expanded(
            child: mediaCount > 1
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $mediaCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_downloading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _downloadCurrent,
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _pageDots(int count) {
    if (count <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            ),
          );
        }),
      ),
    );
  }

  Widget _bottomInfoPanel() {
    final caption = _captionText();
    final author = _authorName();
    final onOpenPost = _onOpenPost();
    if (caption == null && author == null && onOpenPost == null) {
      return const SizedBox.shrink();
    }

    final words = (caption ?? '').split(' ');
    final showExpand = words.length > 20;
    final displayCaption = _captionExpanded || !showExpand
        ? caption
        : '${words.take(18).join(' ')}…';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.paddingOf(context).bottom + 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (author != null && author.isNotEmpty)
            Text(
              author,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (displayCaption != null && displayCaption.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: showExpand ? () => setState(() => _captionExpanded = !_captionExpanded) : null,
              child: _isHtml(displayCaption)
                  ? HtmlWidget(
                      displayCaption,
                      textStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.45,
                      ),
                      onTapUrl: (link) async {
                        if (link.contains('doctak/jobs-detail')) {
                          final jobId = Uri.parse(link).pathSegments.last;
                          JobsDetailsScreen(jobId: jobId).launch(context);
                        } else {
                          PostUtils.launchURL(context, link);
                        }
                        return true;
                      },
                    )
                  : Text(
                      displayCaption,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
            ),
            if (showExpand)
              GestureDetector(
                onTap: () => setState(() => _captionExpanded = !_captionExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _captionExpanded ? 'Show less' : 'Show more',
                    style: const TextStyle(
                      color: Color(0xFF6BA3F5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _chipStat(Icons.favorite_rounded, '${_likeCount()}', translation(context).lbl_likes),
              const SizedBox(width: 10),
              _chipStat(Icons.chat_bubble_rounded, '${_commentCount()}', translation(context).lbl_comments),
              const Spacer(),
              if (onOpenPost != null)
                TextButton(
                  onPressed: onOpenPost,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('View post', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipStat(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = _resolvedMedia;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            SafeArea(bottom: false, child: _topBar(media.length)),
            Expanded(
              child: media.isEmpty
                  ? const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
                    )
                  : _buildGallery(media),
            ),
            if (media.length > 1) _pageDots(media.length),
            if (_hasDetailsPanel) _bottomInfoPanel(),
          ],
        ),
      ),
    );
  }
}
