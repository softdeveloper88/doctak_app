import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:flutter/material.dart';

showFullScreenImage(context, int listCount, String? imageUrl, post,
    List<Map<String, String>> mediaUrl) {
  if (listCount == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          listCount: listCount,
          imageUrl: imageUrl,
          post: post,
          mediaUrls: mediaUrl,
        ),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          listCount: listCount,
          imageUrl: imageUrl,
          post: post,
          mediaUrls: mediaUrl,
        ),
      ),
    );
  }
}
