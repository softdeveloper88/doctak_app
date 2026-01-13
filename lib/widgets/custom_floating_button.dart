import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// OneUI 8.5 styled floating action button
class CustomFloatingButton extends StatelessWidget {
  const CustomFloatingButton({
    Key? key,
    this.alignment,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
    this.decoration,
    this.child,
  }) : super(key: key);

  final Alignment? alignment;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: _buildFab(theme),
          )
        : _buildFab(theme);
  }

  Widget _buildFab(OneUITheme theme) {
    return FloatingActionButton(
      backgroundColor: backgroundColor ?? theme.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
      child: Container(
        alignment: Alignment.center,
        width: width ?? 56,
        height: height ?? 56,
        decoration: decoration,
        child: child,
      ),
    );
  }
}
