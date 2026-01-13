import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// OneUI 8.5 Professional Loading Button
/// A reusable button component with built-in loading state management.
///
/// Usage:
/// ```dart
/// LoadingButton(
///   text: 'Login',
///   onPressed: () async {
///     await performLoginAction();
///   },
/// )
/// ```
///
/// The button automatically:
/// - Shows a loading spinner when clicked
/// - Disables itself during loading to prevent double-taps
/// - Restores to normal state after async action completes
class LoadingButton extends StatefulWidget {
  /// The text to display on the button
  final String text;

  /// Async callback when button is pressed. The button will show loading state
  /// until this future completes.
  final Future<void> Function()? onPressed;

  /// Optional custom width. Defaults to full width.
  final double? width;

  /// Optional custom height. Defaults to 52.
  final double? height;

  /// Button background color. Defaults to theme primary.
  final Color? color;

  /// Text/icon color. Defaults to white.
  final Color? textColor;

  /// Custom text style for the button text
  final TextStyle? textStyle;

  /// Custom child widget instead of text
  final Widget? child;

  /// Whether the button is enabled. Defaults to true.
  final bool enabled;

  /// Optional icon to show before text
  final IconData? icon;

  /// Border radius. Defaults to 26.
  final double borderRadius;

  /// Button variant style
  final LoadingButtonVariant variant;

  /// External loading state control
  final bool? isLoading;

  /// Padding inside the button
  final EdgeInsetsGeometry? padding;

  /// Margin outside the button
  final EdgeInsetsGeometry? margin;

  const LoadingButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.color,
    this.textColor,
    this.textStyle,
    this.child,
    this.enabled = true,
    this.icon,
    this.borderRadius = 26,
    this.variant = LoadingButtonVariant.filled,
    this.isLoading,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

/// Button variant styles
enum LoadingButtonVariant {
  /// Solid filled button (primary action)
  filled,

  /// Outlined button (secondary action)
  outlined,

  /// Text-only button (tertiary action)
  text,

  /// Tonal button (soft background)
  tonal,
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isLoading => widget.isLoading ?? _isLoading;

  bool get isEnabled =>
      widget.enabled && !isLoading && widget.onPressed != null;

  Future<void> _handlePress() async {
    if (!isEnabled) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _controller.forward() : null,
        onTapUp: isEnabled ? (_) => _controller.reverse() : null,
        onTapCancel: isEnabled ? () => _controller.reverse() : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _buildButton(context, theme),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, OneUITheme theme) {
    switch (widget.variant) {
      case LoadingButtonVariant.filled:
        return _buildFilledButton(theme);
      case LoadingButtonVariant.outlined:
        return _buildOutlinedButton(theme);
      case LoadingButtonVariant.text:
        return _buildTextButton(theme);
      case LoadingButtonVariant.tonal:
        return _buildTonalButton(theme);
    }
  }

  Widget _buildFilledButton(OneUITheme theme) {
    final bgColor = widget.color ?? theme.primary;
    final fgColor = widget.textColor ?? Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width ?? double.infinity,
      height: widget.height ?? 52,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: [bgColor, bgColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : theme.surfaceVariant,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _handlePress : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: fgColor.withOpacity(0.1),
          highlightColor: fgColor.withOpacity(0.05),
          child: Padding(
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildButtonContent(
              fgColor: isEnabled ? fgColor : theme.textTertiary,
              theme: theme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(OneUITheme theme) {
    final borderColor = widget.color ?? theme.primary;
    final fgColor = widget.textColor ?? theme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width ?? double.infinity,
      height: widget.height ?? 52,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.transparent : theme.surfaceVariant,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isEnabled ? borderColor : theme.border,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _handlePress : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: borderColor.withOpacity(0.1),
          highlightColor: borderColor.withOpacity(0.05),
          child: Padding(
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildButtonContent(
              fgColor: isEnabled ? fgColor : theme.textTertiary,
              theme: theme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(OneUITheme theme) {
    final fgColor = widget.textColor ?? theme.primary;

    return SizedBox(
      width: widget.width,
      height: widget.height ?? 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _handlePress : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: fgColor.withOpacity(0.1),
          highlightColor: fgColor.withOpacity(0.05),
          child: Padding(
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildButtonContent(
              fgColor: isEnabled ? fgColor : theme.textTertiary,
              theme: theme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTonalButton(OneUITheme theme) {
    final bgColor = (widget.color ?? theme.primary).withOpacity(0.12);
    final fgColor = widget.textColor ?? theme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width ?? double.infinity,
      height: widget.height ?? 52,
      decoration: BoxDecoration(
        color: isEnabled ? bgColor : theme.surfaceVariant,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _handlePress : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: fgColor.withOpacity(0.1),
          highlightColor: fgColor.withOpacity(0.05),
          child: Padding(
            padding:
                widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _buildButtonContent(
              fgColor: isEnabled ? fgColor : theme.textTertiary,
              theme: theme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent({
    required Color fgColor,
    required OneUITheme theme,
  }) {
    if (widget.child != null && !isLoading) {
      return widget.child!;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? _buildLoadingIndicator(fgColor)
          : _buildTextContent(fgColor),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    return Row(
      key: const ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CupertinoActivityIndicator(color: color),
        ),
        const SizedBox(width: 12),
        Text(
          'Please wait...',
          style:
              widget.textStyle?.copyWith(color: color) ??
              TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildTextContent(Color color) {
    return Row(
      key: const ValueKey('content'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: color),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style:
              widget.textStyle?.copyWith(color: color) ??
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: color,
              ),
        ),
      ],
    );
  }
}

/// A small loading button variant for inline actions
class LoadingIconButton extends StatefulWidget {
  final IconData icon;
  final Future<void> Function()? onPressed;
  final Color? color;
  final double size;
  final bool enabled;
  final String? tooltip;
  final bool? isLoading;

  const LoadingIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
    this.enabled = true,
    this.tooltip,
    this.isLoading,
  }) : super(key: key);

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton> {
  bool _isLoading = false;

  bool get isLoading => widget.isLoading ?? _isLoading;
  bool get isEnabled =>
      widget.enabled && !isLoading && widget.onPressed != null;

  Future<void> _handlePress() async {
    if (!isEnabled) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final iconColor = widget.color ?? theme.iconColor;

    Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: widget.size,
              height: widget.size,
              child: CupertinoActivityIndicator(color: iconColor),
            )
          : Icon(
              key: const ValueKey('icon'),
              widget.icon,
              size: widget.size,
              color: isEnabled ? iconColor : theme.textTertiary,
            ),
    );

    child = IconButton(
      onPressed: isEnabled ? _handlePress : null,
      icon: child,
      splashRadius: widget.size + 8,
    );

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    return child;
  }
}

/// Extension for easy usage with existing button patterns
extension LoadingButtonExtension on BuildContext {
  /// Shows a loading button with the app's OneUI theme
  Widget loadingButton({
    required String text,
    required Future<void> Function()? onPressed,
    LoadingButtonVariant variant = LoadingButtonVariant.filled,
    IconData? icon,
    bool enabled = true,
    double? width,
    double? height,
  }) {
    return LoadingButton(
      text: text,
      onPressed: onPressed,
      variant: variant,
      icon: icon,
      enabled: enabled,
      width: width,
      height: height,
    );
  }
}
