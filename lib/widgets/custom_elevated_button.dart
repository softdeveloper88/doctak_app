import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/base_button.dart';
import 'package:flutter/material.dart';

/// OneUI 8.5 styled elevated button
class CustomElevatedButton extends BaseButton {
  const CustomElevatedButton({
    super.key,
    this.decoration,
    this.leftIcon,
    this.rightIcon,
    super.margin,
    super.onPressed,
    super.buttonStyle,
    super.alignment,
    super.buttonTextStyle,
    super.isDisabled,
    super.height,
    super.width,
    required super.text,
  });

  final BoxDecoration? decoration;
  final Widget? leftIcon;
  final Widget? rightIcon;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return alignment != null ? Align(alignment: alignment ?? Alignment.center, child: _buildButton(context, theme)) : _buildButton(context, theme);
  }

  Widget _buildButton(BuildContext context, OneUITheme theme) {
    return Container(
      height: height ?? 52,
      width: width ?? double.maxFinite,
      margin: margin,
      decoration: decoration,
      child: FilledButton(
        onPressed: isDisabled ?? false ? null : onPressed ?? () {},
        style:
            buttonStyle ??
            FilledButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: theme.surfaceVariant,
              disabledForegroundColor: theme.textTertiary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leftIcon != null) ...[leftIcon!, const SizedBox(width: 8)],
            Text(text, style: buttonTextStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (rightIcon != null) ...[const SizedBox(width: 8), rightIcon!],
          ],
        ),
      ),
    );
  }
}
