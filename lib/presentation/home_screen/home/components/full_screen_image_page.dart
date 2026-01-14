// full_screen_image_page.dart
import 'dart:io';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:gal/gal.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/utils/post_utils.dart';
import '../../../../data/models/post_model/post_data_model.dart';
import '../../fragments/home_main_screen/post_widget/video_player_widget.dart';

class FullScreenImagePage extends StatefulWidget {
  final String? imageUrl;
  final Post? post;
  final int listCount;
  final List<Map<String, String>>? mediaUrls;

  const FullScreenImagePage({
    super.key,
    required this.listCount,
    this.imageUrl,
    this.post,
    this.mediaUrls,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage>
    with TickerProviderStateMixin {
  Map<String, double> downloadProgress = {};
  Map<String, bool> isDownloading = {};
  int _currentCarouselIndex = 0;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _detailsAnimationController;
  late Animation<double> _detailsAnimation;
  bool _showDetails = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _detailsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _detailsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _detailsAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    try {
      // Gal package handles permissions internally
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
        return await Gal.hasAccess();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _downloadMedia(String url, BuildContext context) async {
    // Check if already downloading
    if (isDownloading[url] == true) {
      _showToast("Download already in progress", Icons.info, Colors.orange);
      return;
    }

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      _showToast(
        "Permission denied. Please grant storage access.",
        Icons.error,
        Colors.red,
      );
      return;
    }

    setState(() {
      isDownloading[url] = true;
      downloadProgress[url] = 0.0;
    });

    _progressAnimationController.forward();

    final Dio dio = Dio();
    final isVideo = _isVideoUrl(url);
    final extension = isVideo ? '.mp4' : '.jpg';
    final fileName =
        'DocTak_${DateTime.now().millisecondsSinceEpoch}$extension';

    try {
      final dir = await getTemporaryDirectory();
      final String filePath = '${dir.path}/$fileName';

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            setState(() {
              downloadProgress[url] = progress;
            });
          }
        },
      );

      // Save to gallery
      if (isVideo) {
        await Gal.putVideo(filePath);
      } else {
        await Gal.putImage(filePath);
      }

      _showToast(
        isVideo ? "Video saved to gallery" : "Image saved to gallery",
        Icons.check_circle,
        Colors.green,
      );

      // Clean up temporary file
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _showToast(
        "Failed to download. Please try again.",
        Icons.error,
        Colors.red,
      );
    } finally {
      setState(() {
        isDownloading[url] = false;
        downloadProgress.remove(url);
      });
      _progressAnimationController.reverse();
    }
  }

  void _showToast(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.wmv',
      '.flv',
      '.webm',
    ];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains(ext));
  }

  bool isShown = true;

  Widget _buildProgressOverlay() {
    final hasDownloading = isDownloading.values.any(
      (downloading) => downloading,
    );
    if (!hasDownloading) return const SizedBox.shrink();

    final currentUrl = isDownloading.keys.firstWhere(
      (key) => isDownloading[key] == true,
    );
    final progress = downloadProgress[currentUrl] ?? 0.0;
    final isVideo = _isVideoUrl(currentUrl);

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, 100 * (1 - _progressAnimation.value)),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.image,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloading ${isVideo ? 'video' : 'image'}...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saving to gallery',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blue,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int initialPage = 0;
    if (widget.mediaUrls != null && widget.imageUrl != null) {
      final index = widget.mediaUrls!.indexWhere(
        (element) => element['url'] == widget.imageUrl,
      );
      if (index != -1) {
        initialPage = index;
      }
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image with interactive viewer
          (widget.mediaUrls != null && widget.mediaUrls!.length > 1)
              ? CarouselSlider(
                  options: CarouselOptions(
                    height: MediaQuery.of(context).size.height,
                    viewportFraction: 1.0,
                    initialPage: initialPage,
                    enableInfiniteScroll: false,
                    reverse: false,
                    autoPlay: false,
                    enlargeCenterPage: false,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                  ),
                  items: widget.mediaUrls?.map((i) {
                    return Builder(
                      builder: (BuildContext context) {
                        if (i['type'] == "image") {
                          return InteractiveViewer(
                            panEnabled: false,
                            child: Center(
                              child: Image.network(
                                i['url']!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (
                                      BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                              ),
                            ),
                          );
                        } else {
                          return Center(
                            child: VideoPlayerWidget(videoUrl: i['url']!),
                          );
                        }
                      },
                    );
                  }).toList(),
                )
              : InteractiveViewer(
                  panEnabled: false,
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder:
                        (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                  ),
                ),
          // OneUI 8.5 Style Enhanced Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // OneUI 8.5 Style back button with frosted glass effect
                  _buildOneUIButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  // Download button - works for both single and multiple images
                  Row(
                    children: [
                      // Page indicator for multiple images
                      if (widget.mediaUrls != null &&
                          widget.mediaUrls!.length > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentCarouselIndex + 1}/${widget.mediaUrls!.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      // Download button
                      _buildDownloadButton(_getCurrentMediaUrl(), context),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Progress overlay
          _buildProgressOverlay(),

          // OneUI 8.5 Style floating action button for post details
          if (widget.post != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30, right: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showDetails = !_showDetails;
                            });
                            if (_showDetails) {
                              _detailsAnimationController.forward();
                            } else {
                              _detailsAnimationController.reverse();
                            }
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _showDetails
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: AnimatedRotation(
                              turns: _showDetails ? 0.125 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _showDetails
                                    ? Icons.close_rounded
                                    : Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Post details overlay
          if (widget.post != null) _buildPostDetailsOverlay(),
          // Post Title, Likes, and Comments
          // Positioned(
          //   bottom: 20,
          //   top: 100,
          //   left: 0,
          //   right: 0,
          //   child: SingleChildScrollView(
          //     child: Container(
          //       color: Colors.white.withOpacity(0.2),
          //       child: Column(
          //         children: [
          //           if (isShown)
          //             InkWell(
          //                 onTap: () {
          //                   bottomSheetDialog();
          //                 },
          //                 child: Icon(
          //                   Icons.keyboard_arrow_down_rounded,
          //                   color: Colors.white,
          //                 ))
          //           else
          //             InkWell(
          //                 onTap: () {
          //                   setState(() {
          //                     isShown = true;
          //                   });
          //                 },
          //                 child: const Icon(
          //                   Icons.keyboard_arrow_up_rounded,
          //                   color: Colors.white,
          //                 )),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Helper method to get current media URL based on carousel position
  String _getCurrentMediaUrl() {
    if (widget.mediaUrls != null && widget.mediaUrls!.length > 1) {
      return widget.mediaUrls![_currentCarouselIndex]['url'] ?? '';
    }
    return widget.imageUrl ?? '';
  }

  // OneUI 8.5 Style button with frosted glass effect
  Widget _buildOneUIButton({
    required VoidCallback onTap,
    required Widget child,
    double padding = 12,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  // OneUI 8.5 Style Download Button with frosted glass effect
  Widget _buildDownloadButton(String url, BuildContext context) {
    final isDownloadingCurrent = isDownloading[url] == true;
    final currentProgress = downloadProgress[url] ?? 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isDownloadingCurrent
                ? null
                : () => _downloadMedia(url, context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDownloadingCurrent
                    ? Colors.blue.withOpacity(0.25)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDownloadingCurrent
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: isDownloadingCurrent
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: currentProgress,
                            strokeWidth: 2.5,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          Text(
                            '${(currentProgress * 100).toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostDetailsOverlay() {
    if (!_showDetails) return const SizedBox.shrink();

    String fullText = widget.post?.title ?? '';
    List<String> words = fullText.split(' ');
    String textToShow = _isExpanded || words.length <= 25
        ? fullText
        : '${words.take(20).join(' ')}...';

    return AnimatedBuilder(
      animation: _detailsAnimation,
      builder: (context, child) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

        return Positioned(
          left: isTablet ? 40 : 20,
          right: isTablet ? 40 : 20,
          bottom: 100 + bottomPadding + (50 * (1 - _detailsAnimation.value)),
          child: Transform.scale(
            scale: (0.5 + (0.5 * _detailsAnimation.value)).clamp(0.5, 1.2),
            child: Opacity(
              opacity: _detailsAnimation.value.clamp(0.0, 1.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isTablet ? 28 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[400]!,
                                      Colors.purple[400]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.article_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Post Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Post content
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isHtml(textToShow))
                                  HtmlWidget(
                                    fullText,
                                    onTapUrl: (link) async {
                                      if (link.contains('doctak/jobs-detail')) {
                                        String jobID = Uri.parse(
                                          link,
                                        ).pathSegments.last;
                                        JobsDetailsScreen(
                                          jobId: jobID,
                                        ).launch(context);
                                      } else {
                                        PostUtils.launchURL(context, link);
                                      }
                                      return true;
                                    },
                                  )
                                else
                                  Text(
                                    textToShow,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins',
                                      height: 1.6,
                                    ),
                                  ),

                                // Show more/less button
                                if (words.length > 25)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _isExpanded = !_isExpanded;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue[400]!,
                                              Colors.purple[400]!,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _isExpanded
                                                  ? 'Show Less'
                                                  : 'Show More',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              _isExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Engagement stats
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.1),
                                  Colors.purple.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    Icons.favorite_rounded,
                                    '${widget.post?.likes?.length ?? 0}',
                                    translation(context).lbl_likes,
                                    Colors.red[400]!,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    Icons.chat_bubble_rounded,
                                    '${widget.post?.comments?.length ?? 0}',
                                    translation(context).lbl_comments,
                                    Colors.blue[400]!,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  bool _isHtml(String text) {
    // Simple regex to check if the string contains HTML tags
    final htmlTagPattern = RegExp(r'<[^>]*>');
    return htmlTagPattern.hasMatch(text);
  }
}
