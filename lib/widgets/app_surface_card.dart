import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared list-card spacing for modules using [OneUITheme.cardDecoration].
abstract final class AppCardLayout {
  static const double radius = 16;
  static const double listGap = 10;
  static const double horizontalInset = 16;
  static const EdgeInsets listItemMargin =
      EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, listGap);
}

/// Standard surface card — delegates to [OneUITheme.cardDecoration].
class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    Widget card = Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: theme.cardDecoration,
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
