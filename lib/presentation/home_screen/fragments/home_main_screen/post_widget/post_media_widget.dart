import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/photo_grid_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/lazy_video_player_widget.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';

class PostMediaWidget extends StatelessWidget {
  final List<Media> mediaList;
  final String imageUrlBase;
  final Function(String imageUrl) onImageTap;
  final Function(String videoUrl) onVideoTap;
  final Function(List<Map<String, String>> mediaUrls) onExpandImageUrls;

  const PostMediaWidget({
    super.key,
    required this.mediaList,
    required this.imageUrlBase,
    required this.onImageTap,
    required this.onVideoTap,
    required this.onExpandImageUrls,
  });

  /// Helper to construct and validate media URL
  String? _buildMediaUrl(String? mediaPath) {
    if (mediaPath == null || mediaPath.isEmpty || mediaPath == 'null') {
      return null;
    }

    // If the path already starts with http, it's a full URL
    if (mediaPath.startsWith('http://') || mediaPath.startsWith('https://')) {
      return mediaPath;
    }

    // Remove leading slash if present to avoid double slashes
    String cleanPath = mediaPath.startsWith('/')
        ? mediaPath.substring(1)
        : mediaPath;

    // Construct full URL
    return imageUrlBase.endsWith('/')
        ? '$imageUrlBase$cleanPath'
        : '$imageUrlBase/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> mediaWidgets = [];
    List<Map<String, String>> mediaUrls = [];

    for (var media in mediaList) {
      final String? fullUrl = _buildMediaUrl(media.mediaPath);

      // Skip if URL is invalid
      if (fullUrl == null) continue;

      if (media.mediaType == 'image') {
        Map<String, String> newMedia = {"url": fullUrl, "type": "image"};
        mediaUrls.add(newMedia);
        mediaWidgets.add(
          GestureDetector(
            onTap: () => onImageTap(fullUrl),
            child: Container(
              color: svGetBgColor(),
              child: CustomImageView(
                imagePath: fullUrl,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        );
      } else if (media.mediaType == 'video') {
        Map<String, String> newMedia = {"url": fullUrl, "type": "video"};
        mediaUrls.add(newMedia);

        // Use lazy video player for better scroll performance
        mediaWidgets.add(
          GestureDetector(
            onTap: () => onVideoTap(fullUrl),
            child: LazyVideoPlayerWidget(videoUrl: fullUrl),
          ),
        );
      }
    }

    if (mediaUrls.length > 1) {
      return PhotoGrid(
        imageUrls: mediaUrls,
        onImageClicked: (i) => onImageTap(mediaUrls[i]["url"]!),
        onExpandClicked: () => onExpandImageUrls(mediaUrls),
        maxImages: 2,
      );
    } else {
      return Column(children: mediaWidgets);
    }
  }
}

// Example usage:
// List<Media> mediaList = [...]; // Populate this with media objects
// String imageUrlBase = "https://example.com/";
// PostMediaWidget(
//   mediaList: mediaList,
//   imageUrlBase: imageUrlBase,
//   onImageTap: (url) {
//     // Handle image tap
//   },
//   onVideoTap: (url) {
//     // Handle video tap
//   },
// );
