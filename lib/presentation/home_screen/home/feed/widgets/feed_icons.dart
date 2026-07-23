import 'package:doctak_app/core/utils/asset_guard.dart';
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
    case FeedIconAssets.navHome:
      return Icons.home_outlined;
    case FeedIconAssets.navNetwork:
      return Icons.people_outline_rounded;
    case FeedIconAssets.navPost:
      return Icons.add_rounded;
    case FeedIconAssets.navImages:
      return Icons.image_outlined;
    default:
      return null;
  }
}

/// Warm SVG asset cache once (call from home init — no [BuildContext] needed).
Future<void> precacheFeedSvgAssets() async {
  await AssetGuard.warmUp();
  for (final asset in FeedIconAssets.allAssets) {
    if (!AssetGuard.has(asset)) continue;
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
///
/// Bottom-nav icons prefer SVG so a broken / tree-shaken MaterialIcons font
/// (which can paint CJK glyphs for PUA codepoints) never shows in the tab bar.
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

  static bool _isNavAsset(String asset) =>
      asset == FeedIconAssets.navHome ||
      asset == FeedIconAssets.navNetwork ||
      asset == FeedIconAssets.navPost ||
      asset == FeedIconAssets.navImages;

  @override
  Widget build(BuildContext context) {
    // Old store releases patched via Shorebird may not contain SVGs that were
    // added later (patches can't ship assets). Skip the load entirely so we
    // never throw "Unable to load asset" — the top Crashlytics issue.
    if (!AssetGuard.has(asset)) return _fallback();
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (_) => _fallback(),
      errorBuilder: (_, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    final tint = color ?? Colors.grey;
    if (_isNavAsset(asset)) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _NavShapePainter(asset: asset, color: tint),
        ),
      );
    }
    return Icon(
      feedMaterialIconForAsset(asset) ?? Icons.image_outlined,
      size: size,
      color: tint,
    );
  }
}

/// Fontless shapes so nav never shows CJK glyphs when MaterialIcons is missing.
class _NavShapePainter extends CustomPainter {
  _NavShapePainter({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.shortestSide;
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);

    switch (asset) {
      case FeedIconAssets.navPost:
        canvas.drawLine(
          o + Offset(s * 0.5, s * 0.22),
          o + Offset(s * 0.5, s * 0.78),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.22, s * 0.5),
          o + Offset(s * 0.78, s * 0.5),
          paint,
        );
        break;
      case FeedIconAssets.navHome:
        final path = Path()
          ..moveTo(o.dx + s * 0.18, o.dy + s * 0.48)
          ..lineTo(o.dx + s * 0.5, o.dy + s * 0.18)
          ..lineTo(o.dx + s * 0.82, o.dy + s * 0.48)
          ..lineTo(o.dx + s * 0.82, o.dy + s * 0.82)
          ..lineTo(o.dx + s * 0.55, o.dy + s * 0.82)
          ..lineTo(o.dx + s * 0.55, o.dy + s * 0.58)
          ..lineTo(o.dx + s * 0.45, o.dy + s * 0.58)
          ..lineTo(o.dx + s * 0.45, o.dy + s * 0.82)
          ..lineTo(o.dx + s * 0.18, o.dy + s * 0.82)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case FeedIconAssets.navNetwork:
        canvas.drawCircle(o + Offset(s * 0.35, s * 0.32), s * 0.12, paint);
        canvas.drawCircle(o + Offset(s * 0.65, s * 0.32), s * 0.12, paint);
        canvas.drawArc(
          Rect.fromCenter(
            center: o + Offset(s * 0.35, s * 0.72),
            width: s * 0.42,
            height: s * 0.32,
          ),
          3.4,
          2.5,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: o + Offset(s * 0.65, s * 0.72),
            width: s * 0.42,
            height: s * 0.32,
          ),
          3.4,
          2.5,
          false,
          paint,
        );
        break;
      case FeedIconAssets.navImages:
      default:
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + s * 0.18, o.dy + s * 0.22, s * 0.64, s * 0.56),
          Radius.circular(s * 0.08),
        );
        canvas.drawRRect(rrect, paint);
        canvas.drawCircle(o + Offset(s * 0.38, s * 0.4), s * 0.07, paint);
        canvas.drawLine(
          o + Offset(s * 0.22, s * 0.68),
          o + Offset(s * 0.42, s * 0.52),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.42, s * 0.52),
          o + Offset(s * 0.78, s * 0.7),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NavShapePainter oldDelegate) =>
      oldDelegate.asset != asset || oldDelegate.color != color;
}
