import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// OneUI 8.5 styled App Button with optional scale animation
class AppButton extends StatefulWidget {
  final Function? onTap;
  final String? text;
  final double? width;
  final Color? color;
  final Color? textColor;
  final Color? disabledColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? splashColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final ShapeBorder? shapeBorder;
  final Widget? child;
  final double? elevation;
  final double? height;
  final bool enabled;
  final bool? enableScaleAnimation;
  final Color? disabledTextColor;

  const AppButton({
    this.onTap,
    this.text,
    this.width,
    this.color,
    this.textColor,
    this.padding,
    this.margin,
    this.textStyle,
    this.shapeBorder,
    this.child,
    this.elevation,
    this.enabled = true,
    this.height,
    this.disabledColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.enableScaleAnimation,
    this.disabledTextColor,
    super.key,
  });

  @override
  _AppButtonState createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  AnimationController? _controller;

  @override
  void initState() {
    if (widget.enableScaleAnimation.validate(value: enableAppButtonScaleAnimationGlobal)) {
      _controller =
          AnimationController(
            vsync: this,
            duration: Duration(milliseconds: appButtonScaleAnimationDurationGlobal ?? 50),
            lowerBound: 0.0,
            upperBound: 0.1,
          )..addListener(() {
            setState(() {});
          });
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && widget.enabled) {
      _scale = 1 - _controller!.value;
    }

    if (widget.enableScaleAnimation.validate(value: enableAppButtonScaleAnimationGlobal)) {
      return Listener(
        onPointerDown: (details) {
          _controller?.forward();
        },
        onPointerUp: (details) {
          _controller?.reverse();
        },
        child: Transform.scale(scale: _scale, child: _buildButton(context)),
      );
    } else {
      return _buildButton(context);
    }
  }

  Widget _buildButton(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: FilledButton(
        onPressed: widget.enabled
            ? widget.onTap != null
                  ? widget.onTap as void Function()?
                  : null
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: widget.color ?? theme.primary,
          foregroundColor: widget.textColor ?? Colors.white,
          disabledBackgroundColor: widget.disabledColor ?? theme.surfaceVariant,
          disabledForegroundColor: widget.disabledTextColor ?? theme.textTertiary,
          minimumSize: Size(widget.width ?? double.infinity, widget.height ?? 52),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: widget.elevation ?? 0,
          shape: widget.shapeBorder as OutlinedBorder? ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: widget.child ?? Text(widget.text.validate(), style: widget.textStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
