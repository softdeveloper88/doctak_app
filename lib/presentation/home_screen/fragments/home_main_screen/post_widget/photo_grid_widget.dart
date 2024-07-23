import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';
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

  List<Widget> buildImages(BuildContext context) {
    int numImages = imageUrls.length;
    return List<Widget>.generate(min(numImages, maxImages), (index) {
      String imageUrl = imageUrls[index]["url"] ?? '';
      String urlType = imageUrls[index]["type"] ?? '';

      // If its the last image
      if (index == maxImages - 1) {
        // Check how many more images are left
        int remaining = numImages - maxImages;

        // If no more are remaining return a simple image widget
        if (remaining == 0) {
          if (urlType == "image") {
            return GestureDetector(
              child: CustomImageView(
                imagePath: imageUrl,
                fit: BoxFit.cover,
                height: 300,
                width: context.width() - 32,
              ),
              onTap: () => onImageClicked(index),
            );
          } else {
            return GestureDetector(
              child: VideoPlayerWidget(
                videoUrl: imageUrl,
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
                if (urlType == "image")
                  GestureDetector(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      height: 300,
                      width: context.width() - 32,
                    ),
                    onTap: () => onImageClicked(index),
                  )
                else
                  GestureDetector(
                    child: VideoPlayerWidget(
                      videoUrl: imageUrl,
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
        if (urlType == "image") {
          return GestureDetector(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: 300,
              width: context.width() - 32,
            ),
            onTap: () => onImageClicked(index),
          );
        } else {
          return GestureDetector(
            child: VideoPlayerWidget(
              videoUrl: imageUrl,
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
