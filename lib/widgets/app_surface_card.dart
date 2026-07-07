import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared list-card spacing for modules using [OneUITheme.cardDecoration].
abstract final class AppCardLayout {
  static const double radius = 16;
  static const double listGap = 10;
  static const double horizontalInset = 16;
  static const EdgeInsets listItemMargin =
      EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, listGap);
  static const EdgeInsets listItemPadding = EdgeInsets.all(16);
}

/// Standard surface card — delegates to [OneUITheme.cardDecoration].
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Jobs / drugs / conferences / meetings list row — same surface as jobs screen.
  const AppSurfaceCard.listItem({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.margin = AppCardLayout.listItemMargin,
    EdgeInsetsGeometry? padding,
    this.clipBehavior = Clip.antiAlias,
  }) : padding = padding ?? AppCardLayout.listItemPadding;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final decoration = borderColor == null
        ? theme.cardDecoration
        : theme.cardDecoration.copyWith(
            border: Border.all(color: borderColor!),
          );

    Widget card = Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: decoration,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppCardLayout.radius),
        child: card,
      ),
    );
  }
}

/// Titled section card for profile, business profile, and settings blocks.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.margin,
    this.padding = AppCardLayout.listItemPadding,
    this.titleStyle,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return AppSurfaceCard(
      margin: margin,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle ??
                theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
