import 'dart:math';

import 'package:doctak_app/core/utils/media_type_detector.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class PhotoGrid extends StatelessWidget {
  final int maxImages;
  final List<Map<String, String>> imageUrls;
  final Function(int) onImageClicked;
  final Function onExpandClicked;

  const PhotoGrid({required this.imageUrls, required this.onImageClicked, required this.onExpandClicked, this.maxImages = 2, super.key});

  @override
  Widget build(BuildContext context) {
    var images = buildImages(context);

    return SizedBox(
      height: 200,
      child: GridView(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, crossAxisSpacing: 2, mainAxisSpacing: 2),
        children: images,
      ),
    );
  }

  /// Builds an image widget via the shared R2-aware cached image loader.
  Widget _buildImageWidget(String imageUrl, double width, double height) {
    return AppCachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
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
            return GestureDetector(child: _buildImageWidget(imageUrl, context.width() - 32, 300), onTap: () => onImageClicked(index));
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
                    child: VideoPlayerWidget(videoUrl: imageUrl, showMinimalControls: true),
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
                  GestureDetector(child: _buildImageWidget(imageUrl, context.width() - 32, 300), onTap: () => onImageClicked(index))
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
                          child: VideoPlayerWidget(videoUrl: imageUrl, showMinimalControls: true),
                        ),
                      ),
                    ),
                    onTap: () => onImageClicked(index),
                  ),
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.black54,
                    child: Text('+$remaining', style: const TextStyle(fontSize: 32, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mediaType == "image") {
          return GestureDetector(child: _buildImageWidget(imageUrl, context.width() - 32, 300), onTap: () => onImageClicked(index));
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
                  child: VideoPlayerWidget(videoUrl: imageUrl, showMinimalControls: true),
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
