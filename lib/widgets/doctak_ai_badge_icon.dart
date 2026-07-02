import 'package:flutter/material.dart';

class DoctakAiBadgeIcon extends StatelessWidget {
  const DoctakAiBadgeIcon({
    super.key,
    this.size = 24,
    this.padding,
    this.backgroundGradient,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.iconColor = Colors.white,
    this.showShadow = false,
  });

  final double size;
  final EdgeInsetsGeometry? padding;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final Color iconColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient =
        backgroundGradient ??
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D8CFF), Color(0xFF00C9A7)],
        );
    final effectiveShadowColor = switch (effectiveGradient) {
      LinearGradient(colors: final colors) when colors.isNotEmpty =>
        colors.first,
      _ => const Color(0xFF2D8CFF),
    };

    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: effectiveGradient,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: effectiveShadowColor.withValues(alpha: 0.28),
                  spreadRadius: size * 0.04,
                  blurRadius: size * 0.34,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(Icons.auto_awesome, color: iconColor, size: size * 0.48),
      ),
    );
  }
}
