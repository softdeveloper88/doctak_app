import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/base_button.dart';
import 'package:flutter/material.dart';

/// OneUI 8.5 styled outlined button
class CustomOutlinedButton extends BaseButton {
  const CustomOutlinedButton({
    super.key,
    this.decoration,
    this.leftIcon,
    this.rightIcon,
    this.label,
    super.onPressed,
    super.buttonStyle,
    super.buttonTextStyle,
    super.isDisabled,
    super.alignment,
    super.height,
    super.width,
    super.margin,
    required super.text,
  });

  final BoxDecoration? decoration;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Widget? label;

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
      child: OutlinedButton(
        style:
            buttonStyle ??
            OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
        onPressed: isDisabled ?? false ? null : onPressed ?? () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leftIcon != null) ...[leftIcon!, const SizedBox(width: 8)],
            Text(
              text,
              style: buttonTextStyle ?? TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.primary),
            ),
            if (rightIcon != null) ...[const SizedBox(width: 8), rightIcon!],
          ],
        ),
      ),
    );
  }
}
