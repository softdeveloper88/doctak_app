import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

void showFullScreenImage(
  BuildContext context,
  int listCount,
  String? imageUrl,
  dynamic post,
  List<Map<String, String>> mediaUrl,
) {
  AppNavigator.push(
    context,
    FullScreenImagePage(
      listCount: listCount,
      imageUrl: imageUrl,
      post: post,
      mediaUrls: mediaUrl,
    ),
  );
}

/// Opens the full-screen gallery from a [FeedItem] (home feed cards).
void showFeedPostImageViewer(
  BuildContext context, {
  required FeedItem item,
  required List<Map<String, String>> mediaUrls,
  String? initialUrl,
}) {
  final urls = mediaUrls.isNotEmpty
      ? mediaUrls
      : <Map<String, String>>[];
  if (urls.isEmpty) return;

  final postId = int.tryParse(item.id);
  final details = PostImageDetailsContext(
    title: item.str('title'),
    body: item.str('body') ?? item.str('content'),
    authorName: item.str('authorName'),
    likeCount: item.engagement.likes,
    commentCount: item.engagement.comments,
    onOpenPost: postId != null
        ? () {
            Navigator.of(context).pop();
            PostDetailsScreen(postId: postId).launch(context);
          }
        : null,
  );

  AppNavigator.push(
    context,
    FullScreenImagePage(
      listCount: 1,
      imageUrl: initialUrl ?? urls.first['url'],
      mediaUrls: urls,
      detailsContext: details,
    ),
  );
}

/// Image-only viewer when no feed post context is available.
void showImageGalleryViewer(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
}) {
  if (imageUrls.isEmpty) return;
  final media = imageUrls.map((u) => {'url': u, 'type': 'image'}).toList();
  AppNavigator.push(
    context,
    FullScreenImagePage(
      listCount: 1,
      imageUrl: imageUrls[initialIndex.clamp(0, imageUrls.length - 1)],
      mediaUrls: media,
    ),
  );
}
