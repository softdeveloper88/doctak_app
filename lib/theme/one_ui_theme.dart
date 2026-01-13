import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// One UI 8.5 Design System - Centralized Theme
/// This file provides a single source of truth for all One UI 8.5 styling
/// across the entire app, ensuring consistency and reducing code duplication.
///
/// Usage:
/// ```dart
/// final theme = OneUITheme.of(context);
/// Container(color: theme.cardBackground);
/// Text('Hello', style: theme.titleStyle);
/// ```

class OneUITheme {
  final BuildContext context;
  late final bool isDark;

  OneUITheme._(this.context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
  }

  /// Factory constructor to create theme from context
  static OneUITheme of(BuildContext context) => OneUITheme._(context);

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary brand color - Samsung One UI Blue
  Color get primary => const Color(0xFF0A84FF);

  /// Secondary accent color
  Color get secondary => const Color(0xFF5AC8FA);

  /// Success/Positive color
  Color get success => const Color(0xFF34C759);

  /// Warning color
  Color get warning => const Color(0xFFFF9500);

  /// Error/Destructive color
  Color get error => const Color(0xFFFF3B30);

  /// Like/Heart color
  Color get likeColor => const Color(0xFFFF3B30);

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main scaffold/page background
  Color get scaffoldBackground =>
      isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F7F7);

  /// Card/Surface background
  Color get cardBackground => isDark ? const Color(0xFF1B2838) : Colors.white;

  /// Secondary surface (for nested cards, etc.)
  Color get surfaceVariant =>
      isDark ? const Color(0xFF2D3E50) : const Color(0xFFF0F0F0);

  /// Navigation bar background
  Color get navBarBackground => isDark ? const Color(0xFF152232) : Colors.white;

  /// App bar background
  Color get appBarBackground => isDark ? const Color(0xFF1B2838) : Colors.white;

  /// Input field background
  Color get inputBackground =>
      isDark ? const Color(0xFF2D3E50) : const Color(0xFFF5F5F5);

  /// Avatar/placeholder background
  Color get avatarBackground =>
      isDark ? const Color(0xFF2D3E50) : const Color(0xFFE5F2FF);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary text color (headings, important content)
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1C1C1E);

  /// Secondary text color (subtitles, descriptions)
  Color get textSecondary =>
      isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF8E8E93);

  /// Tertiary text color (hints, timestamps)
  Color get textTertiary =>
      isDark ? Colors.white.withOpacity(0.5) : const Color(0xFFAEAEB2);

  /// Link/Action text color
  Color get textLink => primary;

  /// Avatar text color (initials)
  Color get avatarText =>
      isDark ? const Color(0xFF5AC8FA) : const Color(0xFF0A84FF);

  /// Verified badge color
  Color get verifiedBadge => primary;

  /// Delete/destructive red color
  Color get deleteRed => error;

  // ═══════════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default icon color
  Color get iconColor =>
      isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF636366);

  /// Active/Selected icon color
  Color get iconActive => primary;

  /// Inactive icon color
  Color get iconInactive =>
      isDark ? Colors.white.withOpacity(0.5) : const Color(0xFFAEAEB2);

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER & DIVIDER COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard divider color
  Color get divider =>
      isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06);

  /// Subtle border color
  Color get border =>
      isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

  /// Avatar border color
  Color get avatarBorder =>
      isDark ? primary.withOpacity(0.4) : primary.withOpacity(0.2);

  /// Input field border color
  Color get inputBorder =>
      isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);

  /// Focus border color
  Color get focusBorder => primary;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUTTON COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary button background
  Color get buttonPrimary => primary;

  /// Primary button text
  Color get buttonPrimaryText => Colors.white;

  /// Secondary button background
  Color get buttonSecondary =>
      isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

  /// Secondary button text
  Color get buttonSecondaryText =>
      isDark ? Colors.white : const Color(0xFF1C1C1E);

  /// Icon button background
  Color get iconButtonBg =>
      isDark ? Colors.white.withOpacity(0.08) : primary.withOpacity(0.04);

  /// More button background (3-dot menu)
  Color get moreButtonBg =>
      isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORATIONS & SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard card decoration
  BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border, width: 0.5),
    boxShadow: cardShadow,
  );

  /// App bar decoration
  BoxDecoration get appBarDecoration => BoxDecoration(
    color: appBarBackground,
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.08),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Navigation bar decoration
  BoxDecoration get navBarDecoration => BoxDecoration(
    color: navBarBackground,
    border: Border(top: BorderSide(color: divider, width: 0.5)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, -4),
      ),
    ],
  );

  /// Standard card shadow
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: isDark
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.06),
      blurRadius: isDark ? 8 : 12,
      offset: const Offset(0, 2),
      spreadRadius: isDark ? 0 : 1,
    ),
  ];

  /// Elevated shadow (for floating elements)
  List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: isDark
          ? Colors.black.withOpacity(0.5)
          : Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Icon button decoration - Circular for OneUI 8.5 style
  BoxDecoration iconButtonDecoration({
    Color? customColor,
    bool isCircular = true,
  }) => BoxDecoration(
    color: customColor ?? iconButtonBg,
    shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
    borderRadius: isCircular ? null : BorderRadius.circular(12),
    border: Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.08)
          : primary.withOpacity(0.12),
      width: 0.5,
    ),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.15)
            : primary.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Large title style (screen titles)
  TextStyle get titleLarge => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    color: textPrimary,
    letterSpacing: -0.5,
  );

  /// Medium title style (section headers)
  TextStyle get titleMedium => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: textPrimary,
    letterSpacing: -0.3,
  );

  /// Small title style (card titles, names)
  TextStyle get titleSmall => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: textPrimary,
    letterSpacing: -0.2,
  );

  /// Body text style
  TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Poppins',
    color: textPrimary,
  );

  /// Secondary body text
  TextStyle get bodySecondary => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Poppins',
    color: textSecondary,
  );

  /// Caption/small text
  TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Poppins',
    color: textTertiary,
  );

  /// Button text style
  TextStyle get buttonText => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: Colors.white,
  );

  /// App bar title style
  TextStyle get appBarTitle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    color: primary,
    letterSpacing: 0.3,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extra small radius (4)
  BorderRadius get radiusXS => BorderRadius.circular(4);

  /// Small radius (8)
  BorderRadius get radiusS => BorderRadius.circular(8);

  /// Medium radius (12)
  BorderRadius get radiusM => BorderRadius.circular(12);

  /// Large radius (16)
  BorderRadius get radiusL => BorderRadius.circular(16);

  /// Extra large radius (24)
  BorderRadius get radiusXL => BorderRadius.circular(24);

  /// Full/pill radius (999)
  BorderRadius get radiusFull => BorderRadius.circular(999);

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT DECORATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard input decoration
  InputDecoration inputDecoration({
    String? hint,
    String? label,
    Widget? prefix,
    Widget? suffix,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    labelText: label,
    hintStyle: bodySecondary,
    labelStyle: bodySecondary,
    prefix: prefix,
    suffix: suffix,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: inputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: radiusM,
      borderSide: BorderSide(color: inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radiusM,
      borderSide: BorderSide(color: inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radiusM,
      borderSide: BorderSide(color: focusBorder, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radiusM,
      borderSide: BorderSide(color: error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radiusM,
      borderSide: BorderSide(color: error, width: 1.5),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build a standard One UI divider
  Widget buildDivider({double? indent, double? endIndent, double? height}) =>
      Divider(
        height: height ?? 1,
        thickness: 0.5,
        color: divider,
        indent: indent,
        endIndent: endIndent,
      );

  /// Build a vertical divider
  Widget buildVerticalDivider({double? width, double? height}) =>
      Container(width: width ?? 0.5, height: height ?? 32, color: divider);

  /// Build a standard icon button - Circular OneUI 8.5 style
  Widget buildIconButton({
    required Widget child,
    required VoidCallback onPressed,
    double size = 44,
    Color? backgroundColor,
    bool isCircular = true,
  }) => Material(
    color: Colors.transparent,
    shape: isCircular
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: radiusM),
    child: InkWell(
      onTap: onPressed,
      customBorder: isCircular
          ? const CircleBorder()
          : RoundedRectangleBorder(borderRadius: radiusM),
      child: Container(
        width: size,
        height: size,
        decoration: iconButtonDecoration(
          customColor: backgroundColor,
          isCircular: isCircular,
        ),
        child: Center(child: child),
      ),
    ),
  );

  /// Build a badge (notification count, etc.)
  Widget buildBadge(int count, {Color? color, double size = 18}) => Container(
    constraints: BoxConstraints(minWidth: size, minHeight: size),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: color ?? error,
      borderRadius: radiusFull,
      boxShadow: [
        BoxShadow(
          color: (color ?? error).withOpacity(0.4),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Center(
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );

  /// Build an avatar with One UI styling
  Widget buildAvatar({
    String? imageUrl,
    String? fallbackText,
    double size = 48,
    VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: avatarBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(isDark ? 0.2 : 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildAvatarFallback(fallbackText ?? 'U', size),
              )
            : _buildAvatarFallback(fallbackText ?? 'U', size),
      ),
    ),
  );

  Widget _buildAvatarFallback(String text, double size) => Container(
    color: avatarBackground,
    child: Center(
      child: Text(
        text.isNotEmpty ? text[0].toUpperCase() : 'U',
        style: TextStyle(
          color: avatarText,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );

  /// Build a verification badge
  Widget buildVerifiedBadge({double size = 14}) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Icon(
      CupertinoIcons.checkmark_alt,
      size: size * 0.7,
      color: Colors.white,
    ),
  );

  /// Build action button (like, comment, share row)
  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = isActive ? (activeColor ?? primary) : iconColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radiusM,
        splashColor: (activeColor ?? primary).withOpacity(0.1),
        highlightColor: (activeColor ?? primary).withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? (activeColor ?? primary) : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH SCREEN HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Auth screen background gradient
  BoxDecoration get authBackground => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [scaffoldBackground, const Color(0xFF152232)]
          : [Colors.white, const Color(0xFFE3F2FD).withOpacity(0.6)],
      stops: const [0.3, 1.0],
    ),
  );

  /// Auth card decoration
  BoxDecoration get authCardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: border, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.06),
        blurRadius: 24,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Auth logo container decoration
  BoxDecoration get authLogoDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(isDark ? 0.2 : 0.12),
        blurRadius: 24,
        spreadRadius: 1,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Auth primary button decoration
  BoxDecoration get authPrimaryButtonDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.35),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  /// Auth social button decoration
  BoxDecoration authSocialButtonDecoration({Color? iconColor}) => BoxDecoration(
    shape: BoxShape.circle,
    color: cardBackground,
    border: Border.all(color: border, width: 1),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.25)
            : Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Auth input decoration (field label style)
  TextStyle get authLabelStyle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: textSecondary,
  );

  /// Auth title style
  TextStyle get authTitleStyle => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins',
    color: primary,
    letterSpacing: -0.3,
  );

  /// Auth subtitle style
  TextStyle get authSubtitleStyle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFamily: 'Poppins',
    color: textSecondary,
  );

  /// Auth link text style
  TextStyle get authLinkStyle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    color: primary,
  );

  /// Build auth text field with One UI styling
  InputDecoration authInputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: textTertiary,
    ),
    filled: true,
    fillColor: inputBackground,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: error, width: 1.5),
    ),
  );

  /// Build One UI styled checkbox row
  Widget buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    Widget? richText,
  }) => Row(
    children: [
      SizedBox(
        height: 24,
        width: 24,
        child: Checkbox(
          value: value,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          activeColor: primary,
          checkColor: Colors.white,
          side: BorderSide(color: border, width: 1.5),
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child:
            richText ??
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
      ),
    ],
  );

  /// Build One UI primary auth button with built-in loading state
  ///
  /// For async operations, use [onPressedAsync] instead of [onPressed].
  /// The button will automatically show a loading spinner and disable itself
  /// until the async operation completes.
  Widget buildAuthPrimaryButton({
    required String label,
    VoidCallback? onPressed,
    Future<void> Function()? onPressedAsync,
    bool isLoading = false,
    IconData? icon,
  }) {
    // If async callback is provided, use internal loading state management
    if (onPressedAsync != null) {
      return _AuthPrimaryButtonWithLoading(
        label: label,
        onPressedAsync: onPressedAsync,
        icon: icon,
        decoration: authPrimaryButtonDecoration,
      );
    }

    // Otherwise use the classic implementation with external isLoading state
    return Container(
      width: double.infinity,
      height: 56,
      decoration: authPrimaryButtonDecoration,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Build social login button
  Widget buildSocialButton({
    required Widget icon,
    required VoidCallback onTap,
    double size = 56,
  }) => Container(
    width: size,
    height: size,
    decoration: authSocialButtonDecoration(),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: Center(child: icon),
      ),
    ),
  );

  /// Build OR divider
  Widget buildOrDivider({String text = 'OR'}) => Row(
    children: [
      Expanded(child: Container(height: 1, color: divider)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: textTertiary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      Expanded(child: Container(height: 1, color: divider)),
    ],
  );

  /// Build auth nav link row (e.g., "Don't have an account? Sign up")
  Widget buildAuthNavLink({
    required String message,
    required String actionText,
    required VoidCallback onTap,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: textSecondary,
          fontFamily: 'Poppins',
        ),
      ),
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(actionText, style: authLinkStyle),
        ),
      ),
    ],
  );
} // End of OneUITheme class

// ═══════════════════════════════════════════════════════════════════════════
// ONE UI DROPDOWN FORM FIELD WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// One UI 8.5 styled dropdown form field widget
/// This widget provides consistent dropdown styling across the app
/// and handles overflow issues automatically with isExpanded: true
///
/// Usage:
/// ```dart
/// OneUIDropdownFormField<String>(
///   value: selectedValue,
///   items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
///   onChanged: (value) => setState(() => selectedValue = value),
///   labelText: 'Select Option',
///   hintText: 'Choose an option',
///   prefixIcon: Icons.category_outlined,
/// )
/// ```
class OneUIDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool showContainer;
  final EdgeInsetsGeometry? contentPadding;
  final Color? containerColor;
  final double borderRadius;
  final bool enabled;

  const OneUIDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.showContainer = true,
    this.contentPadding,
    this.containerColor,
    this.borderRadius = 12,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    final dropdown = DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true, // Prevents overflow
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: theme.textSecondary,
        size: 24,
      ),
      dropdownColor: theme.cardBackground,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: theme.textPrimary,
        overflow: TextOverflow.ellipsis,
      ),
      decoration: InputDecoration(
        border: showContainer
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: theme.primary.withOpacity(0.3)),
              ),
        enabledBorder: showContainer
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: theme.border),
              ),
        focusedBorder: showContainer
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: theme.primary, width: 1.5),
              ),
        errorBorder: showContainer
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: theme.error),
              ),
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: theme.textTertiary,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: theme.textSecondary,
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: theme.primary.withOpacity(0.6), size: 20)
            : null,
      ),
      validator: validator,
      selectedItemBuilder: (context) => items.map((item) {
        return Container(
          alignment: Alignment.centerLeft,
          child: Text(
            item.child is Text ? (item.child as Text).data ?? '' : '',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: theme.textPrimary,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );

    if (!showContainer) {
      return dropdown;
    }

    return Container(
      decoration: BoxDecoration(
        color: containerColor ?? theme.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: dropdown,
    );
  }
}

/// Compact dropdown variant for inline/row usage
class OneUICompactDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final double? width;
  final bool enabled;

  const OneUICompactDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.width,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.textSecondary,
            size: 20,
          ),
          dropdownColor: theme.cardBackground,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: theme.textPrimary,
          ),
          hint: hintText != null
              ? Text(
                  hintText!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: theme.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          selectedItemBuilder: (context) => items.map((item) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon, size: 16, color: theme.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      item.child is Text ? (item.child as Text).data ?? '' : '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: theme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Internal StatefulWidget for auth button with loading state management
class _AuthPrimaryButtonWithLoading extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressedAsync;
  final IconData? icon;
  final BoxDecoration decoration;

  const _AuthPrimaryButtonWithLoading({
    required this.label,
    required this.onPressedAsync,
    required this.decoration,
    this.icon,
  });

  @override
  State<_AuthPrimaryButtonWithLoading> createState() =>
      _AuthPrimaryButtonWithLoadingState();
}

class _AuthPrimaryButtonWithLoadingState
    extends State<_AuthPrimaryButtonWithLoading>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressedAsync();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isLoading ? null : (_) => _scaleController.forward(),
      onTapUp: _isLoading ? null : (_) => _scaleController.reverse(),
      onTapCancel: _isLoading ? null : () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: widget.decoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _handlePress,
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isLoading
                      ? Row(
                          key: const ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Please wait...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('content'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSION FOR EASY ACCESS
// ═══════════════════════════════════════════════════════════════════════════

extension OneUIThemeExtension on BuildContext {
  /// Quick access to One UI theme: `context.oneUI.primary`
  OneUITheme get oneUI => OneUITheme.of(this);
}
