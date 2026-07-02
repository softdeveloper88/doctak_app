import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG paths extracted from the DocTak Mobile reference design.
abstract final class FeedIconAssets {
  static const _base = 'assets/icon/feed';

  // App bar
  static const menu = '$_base/ic_menu.svg';
  static const search = '$_base/ic_search.svg';
  static const bell = '$_base/ic_bell.svg';
  static const chat = '$_base/ic_chat.svg';

  // Composer
  static const composePost = '$_base/ic_compose_post.svg';
  static const composePoll = '$_base/ic_compose_poll.svg';
  static const composeBlog = '$_base/ic_compose_blog.svg';

  // Stories
  static const storyPhoto = '$_base/ic_story_photo.svg';
  static const storyPlus = '$_base/ic_story_plus.svg';

  // Post actions
  static const like = '$_base/ic_like.svg';
  static const comment = '$_base/ic_comment.svg';
  static const repost = '$_base/ic_repost.svg';
  static const send = '$_base/ic_send.svg';
  static const more = '$_base/ic_more.svg';
  static const globe = '$_base/ic_globe.svg';

  // Bottom nav
  static const navHome = '$_base/ic_nav_home.svg';
  static const navNetwork = '$_base/ic_nav_network.svg';
  static const navPost = '$_base/ic_nav_post.svg';
  static const navImages = '$_base/ic_nav_images.svg';

  static const allAssets = [
    menu,
    search,
    bell,
    chat,
    composePost,
    composePoll,
    composeBlog,
    storyPhoto,
    storyPlus,
    like,
    comment,
    repost,
    send,
    more,
    globe,
    navHome,
    navNetwork,
    navPost,
    navImages,
  ];
}

/// Fast Material icon fallback for feed list actions (avoids SVG parse per frame).
IconData? feedMaterialIconForAsset(String asset) {
  switch (asset) {
    case FeedIconAssets.like:
      return Icons.thumb_up_outlined;
    case FeedIconAssets.comment:
      return Icons.chat_bubble_outline_rounded;
    case FeedIconAssets.repost:
      return Icons.repeat_rounded;
    case FeedIconAssets.send:
      return Icons.send_rounded;
    case FeedIconAssets.more:
      return Icons.more_horiz_rounded;
    case FeedIconAssets.globe:
      return Icons.public;
    case FeedIconAssets.composePost:
      return Icons.edit_note_outlined;
    case FeedIconAssets.composePoll:
      return Icons.poll_outlined;
    case FeedIconAssets.composeBlog:
      return Icons.article_outlined;
    default:
      return null;
  }
}

/// Warm SVG asset cache once (call from home init — no [BuildContext] needed).
Future<void> precacheFeedSvgAssets() async {
  for (final asset in FeedIconAssets.allAssets) {
    try {
      final loader = SvgAssetLoader(asset);
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    } catch (_) {
      // Asset missing in a given flavor — skip.
    }
  }
}

/// Renders a reference-design SVG icon with optional tint.
class FeedIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const FeedIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (_) => _fallback(),
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Icon(
        Icons.image_outlined,
        size: size,
        color: color ?? Colors.grey,
      );
}
