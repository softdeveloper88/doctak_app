import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/media_type_detector.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';
import 'package:doctak_app/widgets/s3_image_loader.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class PhotoGrid extends StatelessWidget {
  final int maxImages;
  final List<Map<String, String>> imageUrls;
  final Function(int) onImageClicked;
  final Function onExpandClicked;

  PhotoGrid({
    required this.imageUrls,
    required this.onImageClicked,
    required this.onExpandClicked,
    this.maxImages = 2,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var images = buildImages(context);

    return SizedBox(
      height: 200,
      child: GridView(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        children: images,
      ),
    );
  }

  /// Helper method to determine if URL is an S3 URL
  bool _isS3Url(String url) {
    return url.contains('s3.') || url.contains('.amazonaws.com') || url.contains('s3-');
  }

  /// Helper method to build image widget with appropriate loader
  Widget _buildImageWidget(String imageUrl, double width, double height) {
    if (_isS3Url(imageUrl)) {
      print('🔍 Using S3ImageLoader for URL: $imageUrl');
      return S3ImageLoader(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        height: height,
        width: width,
        httpHeaders: const {
          'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.grey,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('🚨 Image load error for URL: $url');
          print('🚨 Error details: $error');
          print('🚨 Error type: ${error.runtimeType}');
          
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    color: Colors.grey,
                    size: 32,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Image failed to load',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  List<Widget> buildImages(BuildContext context) {
    int numImages = imageUrls.length;
    return List<Widget>.generate(min(numImages, maxImages), (index) {
      String imageUrl = imageUrls[index]["url"] ?? '';
      String urlType = imageUrls[index]["type"] ?? '';
      
      // Auto-detect media type if not properly set or validate existing type
      String actualMediaType = MediaTypeDetector.getMediaType(imageUrl);

      // Validate and warn if there's a mismatch
      if (urlType.isNotEmpty && !MediaTypeDetector.validateMediaType(imageUrl, urlType)) {
        print('🔧 Auto-correcting media type for: $imageUrl');
        print('📝 Original type: $urlType → Corrected type: $actualMediaType');
      }
      
      // Use the detected media type for better accuracy
      final mediaType = actualMediaType;

      // If its the last image
      if (index == maxImages - 1) {
        // Check how many more images are left
        int remaining = numImages - maxImages;

        // If no more are remaining return a simple image widget
        if (remaining == 0) {
          if (mediaType == "image") {
            return GestureDetector(
              child: _buildImageWidget(imageUrl, context.width() - 32, 300),
              onTap: () => onImageClicked(index),
            );
          } else {
            return GestureDetector(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: VideoPlayerWidget(
                      videoUrl: imageUrl,
                      showMinimalControls: true,
                    ),
                  ),
                ),
              ),
              onTap: () => onImageClicked(index),
            );
          }
        } else {
          // Create the facebook like effect for the last image with number of remaining  images
          return GestureDetector(
            onTap: () => onExpandClicked(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image.network(imageUrl, fit: BoxFit.cover),
                if (mediaType == "image")
                  GestureDetector(
                    child: _buildImageWidget(imageUrl, context.width() - 32, 300),
                    onTap: () => onImageClicked(index),
                  )
                else
                  GestureDetector(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: VideoPlayerWidget(
                            videoUrl: imageUrl,
                            showMinimalControls: true,
                          ),
                        ),
                      ),
                    ),
                    onTap: () => onImageClicked(index),
                  ),
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.black54,
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mediaType == "image") {
          return GestureDetector(
            child: _buildImageWidget(imageUrl, context.width() - 32, 300),
            onTap: () => onImageClicked(index),
          );
        } else {
          return GestureDetector(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: VideoPlayerWidget(
                    videoUrl: imageUrl,
                    showMinimalControls: true,
                  ),
                ),
              ),
            ),
            onTap: () => onImageClicked(index),
          );
        }
      }
      //   return GestureDetector(
      //     child: Image.network(
      //       imageUrl,
      //       fit: BoxFit.cover,
      //     ),
      //     onTap: () => widget.onImageClicked(index),
      //   );
      // }
    });
  }
}
