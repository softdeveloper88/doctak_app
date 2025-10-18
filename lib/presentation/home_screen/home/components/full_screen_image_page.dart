// full_screen_image_page.dart
import 'dart:io';
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
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image with interactive viewer
          InteractiveViewer(
            panEnabled: false,
            // Set it to false to prevent panning.
            // boundaryMargin: const EdgeInsets.all(10),
            // minScale: 5.5,
            // maxScale: 10,
            child: widget.listCount == 2
                ? CarouselSlider(
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height - 100,
                      // aspectRatio: 16/12,
                      viewportFraction: 0.9,
                      initialPage: 0,
                      enableInfiniteScroll: true,
                      reverse: false,
                      autoPlay: false,
                      // autoPlayInterval: Duration(seconds: 3),
                      // autoPlayAnimationDuration: Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: true,
                      // enlargeFactor: 0.3,
                      // onPageChanged: callbackFunction,
                      scrollDirection: Axis.horizontal,
                    ),
                    // options: CarouselOptions(height: 400.0),
                    items: widget.mediaUrls?.map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          if (i['type'] == "image") {
                            return Stack(
                              children: [
                                Center(
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
                                          if (loadingProgress == null)
                                            return child;
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
                                Positioned(
                                  right: 16,
                                  top: 80,
                                  child: _buildDownloadButton(
                                    i['url']!,
                                    context,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Stack(
                              children: [
                                Center(
                                  child: VideoPlayerWidget(videoUrl: i['url']!),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 80,
                                  child: _buildDownloadButton(
                                    i['url']!,
                                    context,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    }).toList(),
                  )
                : Image.network(
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
          // Enhanced Header
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Enhanced back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Download button for single image
                  if (widget.listCount == 1)
                    _buildDownloadButton(widget.imageUrl!, context),
                ],
              ),
            ),
          ),
          // Progress overlay
          _buildProgressOverlay(),

          // Enhanced floating action button for post details
          if (widget.post != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30, right: 20),
                  child: GestureDetector(
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.purple[600]!],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: _showDetails ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _showDetails
                              ? Icons.close_rounded
                              : Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 28,
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

  Widget _buildDownloadButton(String url, BuildContext context) {
    final isDownloadingCurrent = isDownloading[url] == true;
    final currentProgress = downloadProgress[url] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: isDownloadingCurrent
              ? null
              : () => _downloadMedia(url, context),
          child: Container(
            padding: const EdgeInsets.all(14),
            child: isDownloadingCurrent
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: currentProgress,
                          strokeWidth: 3,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                      Text(
                        '${(currentProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                : const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 28,
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
        return Positioned(
          left: 20,
          right: 20,
          bottom: 100 + bottomPadding + (50 * (1 - _detailsAnimation.value)),
          child: Transform.scale(
            scale: (0.5 + (0.5 * _detailsAnimation.value)).clamp(0.5, 1.2),
            child: Opacity(
              opacity: _detailsAnimation.value.clamp(0.0, 1.0),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.grey[900]!.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(0, -5),
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
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
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
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
