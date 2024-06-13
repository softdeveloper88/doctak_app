import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/photo_grid_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_image_view.dart';
import 'package:flutter/material.dart';

class PostMediaWidget extends StatelessWidget {
  final List<Media> mediaList;
  final String imageUrlBase;
  final Function(String imageUrl) onImageTap;
  final Function(String videoUrl) onVideoTap;
  final Function( List<Map<String, String>> mediaUrls) onExpandImageUrls;

  PostMediaWidget({
    required this.mediaList,
    required this.imageUrlBase,
    required this.onImageTap,
    required this.onVideoTap,
    required this.onExpandImageUrls,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> mediaWidgets = [];
    List<Map<String, String>> mediaUrls = [];

    for (var media in mediaList) {
      if (media.mediaType == 'image') {
        String fullImageUrl = imageUrlBase + media.mediaPath.toString();
        Map<String, String> newMedia = {"url": fullImageUrl, "type": "image"};
        mediaUrls.add(newMedia);
        mediaWidgets.add(
          GestureDetector(
            onTap: () => onImageTap(fullImageUrl),
            child: Container(
              color: svGetBgColor(),
              child: CustomImageView(
                imagePath: fullImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),
            ),
          ),
        );
      } else if (media.mediaType == 'video') {
        String fullVideoUrl = imageUrlBase + media.mediaPath.toString();
        Map<String, String> newMedia = {"url": fullVideoUrl, "type": "video"};
        mediaUrls.add(newMedia);

        mediaWidgets.add(
          GestureDetector(
            onTap: () => onVideoTap(fullVideoUrl),
            child: VideoPlayerWidget(videoUrl: fullVideoUrl),
          ),
        );
      }
    }

    if (mediaUrls.length > 1) {
      return PhotoGrid(
        imageUrls: mediaUrls,
        onImageClicked: (i) => onImageTap(mediaUrls[i]["url"]!),
        onExpandClicked: () =>onExpandImageUrls(mediaUrls), // You can add expand functionality here
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
