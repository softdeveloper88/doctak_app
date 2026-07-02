import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

/// Safe circular avatar for groups — never throws on bad/missing image URLs.
class GroupCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  const GroupCircleAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 36,
    this.borderWidth = 0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final resolvedUrl = AppData.fullImageUrl(imageUrl);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    final fallback = ColoredBox(
      color: theme.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: theme.primary,
          ),
        ),
      ),
    );

    Widget avatar = !AppData.isValidHttpImageUrl(resolvedUrl)
        ? fallback
        : AppCachedNetworkImage(
            imageUrl: resolvedUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          );

    if (borderWidth > 0) {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? theme.cardBackground,
            width: borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: avatar,
      );
    } else {
      avatar = ClipOval(child: SizedBox(width: size, height: size, child: avatar));
    }

    return SizedBox(width: size, height: size, child: avatar);
  }
}
