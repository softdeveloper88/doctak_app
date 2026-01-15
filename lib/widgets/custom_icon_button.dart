import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// OneUI 8.5 styled icon button
class CustomIconButton extends StatelessWidget {
  const CustomIconButton({super.key, this.alignment, this.height, this.width, this.padding, this.decoration, this.child, this.onTap});

  final Alignment? alignment;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return alignment != null ? Align(alignment: alignment ?? Alignment.center, child: _buildButton(theme)) : _buildButton(theme);
  }

  Widget _buildButton(OneUITheme theme) {
    return SizedBox(
      height: height ?? 44,
      width: width ?? 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Container(
          height: height ?? 44,
          width: width ?? 44,
          padding: padding ?? EdgeInsets.zero,
          decoration: decoration ?? BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(22)),
          child: child,
        ),
        onPressed: onTap,
      ),
    );
  }
}

/// Extension on [CustomIconButton] to facilitate inclusion of all types of border style
extension IconButtonStyleHelper on CustomIconButton {
  static BoxDecoration fillPrimary(OneUITheme theme) => BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(22));

  static BoxDecoration fillSurface(OneUITheme theme) => BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(22));

  static BoxDecoration fillError(OneUITheme theme) => BoxDecoration(color: theme.error, borderRadius: BorderRadius.circular(22));

  static BoxDecoration outlined(OneUITheme theme) => BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: theme.divider, width: 1),
  );
}
