# One UI 8.5 Design System Guide

## Complete A-Z Reference for Flutter App Conversion

This guide provides comprehensive guidelines for converting Flutter app UI to Samsung One UI 8.5 design language.

---

## 📋 Table of Contents

1. [Color System](#color-system)
2. [Typography](#typography)
3. [Spacing & Layout](#spacing--layout)
4. [Components](#components)
5. [Icons](#icons)
6. [Animations & Transitions](#animations--transitions)
7. [Dark Mode](#dark-mode)
8. [Accessibility](#accessibility)
9. [Flutter Implementation](#flutter-implementation)

---

## 🎨 Color System

### Primary Colors

```dart
// One UI 8.5 Core Colors
class OneUIColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF0A84FF);        // Samsung Blue
  static const Color primaryLight = Color(0xFF4DA3FF);   // Light accent
  static const Color primaryDark = Color(0xFF0056B3);    // Dark accent
  
  // Background Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF0D1B2A);     // Deep navy - Main bg
  static const Color surfaceDark = Color(0xFF1B2838);        // Card/surface bg
  static const Color surfaceVariantDark = Color(0xFF2D3E50); // Elevated surface
  static const Color navBarDark = Color(0xFF152232);         // Bottom nav bg
  
  // Background Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF7F7F7);    // Main bg
  static const Color surfaceLight = Color(0xFFFFFFFF);       // Card/surface bg
  static const Color surfaceVariantLight = Color(0xFFF0F0F0);// Elevated surface
  static const Color navBarLight = Color(0xFFFFFFFF);        // Bottom nav bg
  
  // Semantic Colors
  static const Color success = Color(0xFF34C759);    // Green
  static const Color warning = Color(0xFFFF9500);    // Orange
  static const Color error = Color(0xFFFF3B30);      // Red
  static const Color info = Color(0xFF5AC8FA);       // Light Blue
  
  // Text Colors (Dark Theme)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xB3FFFFFF);  // 70% white
  static const Color textTertiaryDark = Color(0x80FFFFFF);   // 50% white
  static const Color textDisabledDark = Color(0x4DFFFFFF);   // 30% white
  
  // Text Colors (Light Theme)
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textTertiaryLight = Color(0xFFC7C7CC);
  static const Color textDisabledLight = Color(0xFFD1D1D6);
  
  // Divider & Border Colors
  static const Color dividerDark = Color(0x1AFFFFFF);        // 10% white
  static const Color dividerLight = Color(0x1A000000);       // 10% black
  static const Color borderDark = Color(0x33FFFFFF);         // 20% white
  static const Color borderLight = Color(0x33000000);        // 20% black
}
```

### Color Usage Guidelines

| Element | Dark Theme | Light Theme |
|---------|------------|-------------|
| Main Background | `#0D1B2A` | `#F7F7F7` |
| Card/Container | `#1B2838` | `#FFFFFF` |
| Floating Elements | `#2D3E50` | `#F0F0F0` |
| Bottom Navigation | `#152232` | `#FFFFFF` |
| Primary Action | `#0A84FF` | `#0A84FF` |
| Destructive Action | `#FF3B30` | `#FF3B30` |
| Success State | `#34C759` | `#34C759` |
| Warning State | `#FF9500` | `#FF9500` |

---

## 📝 Typography

### Font Family

One UI 8.5 uses **SamsungOne** font family. For Flutter, use:
- **Primary**: `Roboto` (Android default)
- **iOS Alternative**: `SF Pro` (iOS default)
- **Custom**: Import Samsung One if available

### Type Scale

```dart
class OneUITypography {
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}
```

---

## 📐 Spacing & Layout

### Spacing Scale

```dart
class OneUISpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}
```

### Border Radius

```dart
class OneUIRadius {
  static const double none = 0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double round = 100.0;  // Fully rounded (pills, circles)
  
  // Component-specific
  static const double button = 20.0;
  static const double card = 16.0;
  static const double dialog = 24.0;
  static const double bottomSheet = 28.0;
  static const double fab = 22.0;
  static const double chip = 8.0;
  static const double textField = 12.0;
}
```

### Elevation & Shadows

```dart
class OneUIShadows {
  static List<BoxShadow> elevation1(bool isDark) => [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> elevation2(bool isDark) => [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevation3(bool isDark) => [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.4 : 0.16),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevation4(bool isDark) => [
    BoxShadow(
      color: Colors.black.withOpacity(isDark ? 0.45 : 0.20),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
```

---

## 🧩 Components

### Buttons

#### Primary Button
```dart
Widget buildOneUIPrimaryButton({
  required String label,
  required VoidCallback onPressed,
  bool isLoading = false,
  bool isDisabled = false,
  IconData? icon,
}) {
  return Material(
    color: isDisabled 
        ? OneUIColors.primary.withOpacity(0.4) 
        : OneUIColors.primary,
    borderRadius: BorderRadius.circular(OneUIRadius.button),
    child: InkWell(
      onTap: isDisabled || isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(OneUIRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OneUISpacing.xl,
          vertical: OneUISpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: OneUISpacing.xs),
              ],
              Text(
                label,
                style: OneUITypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
```

#### Secondary Button
```dart
Widget buildOneUISecondaryButton({
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
  bool isDark = true,
}) {
  final bgColor = isDark ? OneUIColors.surfaceVariantDark : OneUIColors.surfaceVariantLight;
  final textColor = isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight;
  
  return Material(
    color: bgColor,
    borderRadius: BorderRadius.circular(OneUIRadius.button),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(OneUIRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OneUISpacing.xl,
          vertical: OneUISpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: OneUISpacing.xs),
            ],
            Text(
              label,
              style: OneUITypography.labelLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

#### Icon Button
```dart
Widget buildOneUIIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  double size = 44,
  bool isDark = true,
  bool isActive = false,
  Color? activeColor,
}) {
  final bgColor = isActive
      ? (activeColor ?? OneUIColors.primary)
      : (isDark ? OneUIColors.surfaceVariantDark : OneUIColors.surfaceVariantLight);
  final iconColor = isActive 
      ? Colors.white 
      : (isDark ? Colors.white.withOpacity(0.9) : OneUIColors.textPrimaryLight);
  
  return Material(
    color: bgColor,
    borderRadius: BorderRadius.circular(OneUIRadius.fab),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(OneUIRadius.fab),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    ),
  );
}
```

### Cards

```dart
Widget buildOneUICard({
  required Widget child,
  EdgeInsets? padding,
  bool isDark = true,
  bool hasShadow = true,
}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(OneUISpacing.md),
    decoration: BoxDecoration(
      color: isDark ? OneUIColors.surfaceDark : OneUIColors.surfaceLight,
      borderRadius: BorderRadius.circular(OneUIRadius.card),
      boxShadow: hasShadow ? OneUIShadows.elevation2(isDark) : null,
    ),
    child: child,
  );
}
```

### App Bar

```dart
AppBar buildOneUIAppBar({
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool isDark = true,
  bool centerTitle = false,
  double elevation = 0,
}) {
  return AppBar(
    title: Text(
      title,
      style: OneUITypography.titleLarge.copyWith(
        color: isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight,
      ),
    ),
    centerTitle: centerTitle,
    backgroundColor: isDark ? OneUIColors.backgroundDark : OneUIColors.backgroundLight,
    elevation: elevation,
    leading: leading,
    actions: actions,
    iconTheme: IconThemeData(
      color: isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight,
    ),
  );
}
```

### Bottom Navigation Bar

```dart
Widget buildOneUIBottomNavBar({
  required int currentIndex,
  required Function(int) onTap,
  required List<BottomNavItem> items,
  bool isDark = true,
}) {
  final bgColor = isDark ? OneUIColors.navBarDark : OneUIColors.navBarLight;
  final activeColor = OneUIColors.primary;
  final inactiveColor = isDark 
      ? OneUIColors.textSecondaryDark 
      : OneUIColors.textSecondaryLight;
  
  return Container(
    decoration: BoxDecoration(
      color: bgColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OneUISpacing.md,
          vertical: OneUISpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;
            
            return GestureDetector(
              onTap: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: OneUITypography.labelSmall.copyWith(
                      color: isSelected ? activeColor : inactiveColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

class BottomNavItem {
  final IconData icon;
  final String label;
  
  BottomNavItem({required this.icon, required this.label});
}
```

### Text Fields

```dart
Widget buildOneUITextField({
  required TextEditingController controller,
  String? label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffix,
  bool obscureText = false,
  TextInputType? keyboardType,
  bool isDark = true,
  String? errorText,
}) {
  final bgColor = isDark ? OneUIColors.surfaceVariantDark : OneUIColors.surfaceVariantLight;
  final textColor = isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight;
  final hintColor = isDark ? OneUIColors.textTertiaryDark : OneUIColors.textTertiaryLight;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text(
          label,
          style: OneUITypography.labelMedium.copyWith(
            color: isDark ? OneUIColors.textSecondaryDark : OneUIColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: OneUISpacing.xs),
      ],
      Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(OneUIRadius.textField),
          border: errorText != null
              ? Border.all(color: OneUIColors.error, width: 1)
              : null,
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: OneUITypography.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: OneUITypography.bodyLarge.copyWith(color: hintColor),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: hintColor, size: 22)
                : null,
            suffix: suffix,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OneUISpacing.md,
              vertical: OneUISpacing.md,
            ),
          ),
        ),
      ),
      if (errorText != null) ...[
        const SizedBox(height: OneUISpacing.xxs),
        Text(
          errorText,
          style: OneUITypography.labelSmall.copyWith(
            color: OneUIColors.error,
          ),
        ),
      ],
    ],
  );
}
```

### Dialog

```dart
Future<T?> showOneUIDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool isDark = true,
  bool isDestructive = false,
}) {
  final bgColor = isDark ? OneUIColors.surfaceDark : OneUIColors.surfaceLight;
  final textColor = isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight;
  final secondaryTextColor = isDark ? OneUIColors.textSecondaryDark : OneUIColors.textSecondaryLight;
  
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneUIRadius.dialog),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OneUISpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: OneUITypography.headlineSmall.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OneUISpacing.md),
            Text(
              message,
              style: OneUITypography.bodyMedium.copyWith(color: secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OneUISpacing.xl),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: buildOneUISecondaryButton(
                      label: cancelText,
                      onPressed: () {
                        onCancel?.call();
                        Navigator.of(context).pop();
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: OneUISpacing.md),
                ],
                Expanded(
                  child: Material(
                    color: isDestructive ? OneUIColors.error : OneUIColors.primary,
                    borderRadius: BorderRadius.circular(OneUIRadius.button),
                    child: InkWell(
                      onTap: () {
                        onConfirm?.call();
                        Navigator.of(context).pop(true);
                      },
                      borderRadius: BorderRadius.circular(OneUIRadius.button),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: OneUISpacing.md),
                        alignment: Alignment.center,
                        child: Text(
                          confirmText ?? 'OK',
                          style: OneUITypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Bottom Sheet

```dart
Future<T?> showOneUIBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDark = true,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  final bgColor = isDark ? OneUIColors.surfaceDark : OneUIColors.surfaceLight;
  
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(OneUIRadius.bottomSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: OneUISpacing.sm),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Flexible(child: child),
        ],
      ),
    ),
  );
}
```

### List Tile

```dart
Widget buildOneUIListTile({
  required String title,
  String? subtitle,
  IconData? leadingIcon,
  Widget? trailing,
  VoidCallback? onTap,
  bool isDark = true,
  bool showDivider = true,
}) {
  final textColor = isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight;
  final subtitleColor = isDark ? OneUIColors.textSecondaryDark : OneUIColors.textSecondaryLight;
  final iconColor = isDark ? OneUIColors.textSecondaryDark : OneUIColors.textSecondaryLight;
  final dividerColor = isDark ? OneUIColors.dividerDark : OneUIColors.dividerLight;
  
  return Column(
    children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OneUISpacing.md,
            vertical: OneUISpacing.md,
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? OneUIColors.surfaceVariantDark 
                        : OneUIColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(OneUIRadius.sm),
                  ),
                  child: Icon(leadingIcon, color: iconColor, size: 22),
                ),
                const SizedBox(width: OneUISpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OneUITypography.bodyLarge.copyWith(color: textColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: OneUITypography.bodySmall.copyWith(color: subtitleColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
      if (showDivider)
        Divider(
          height: 1,
          color: dividerColor,
          indent: leadingIcon != null ? 72 : OneUISpacing.md,
          endIndent: OneUISpacing.md,
        ),
    ],
  );
}
```

### Chips / Tags

```dart
Widget buildOneUIChip({
  required String label,
  bool isSelected = false,
  VoidCallback? onTap,
  IconData? icon,
  bool isDark = true,
}) {
  final bgColor = isSelected
      ? OneUIColors.primary
      : (isDark ? OneUIColors.surfaceVariantDark : OneUIColors.surfaceVariantLight);
  final textColor = isSelected
      ? Colors.white
      : (isDark ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight);
  
  return Material(
    color: bgColor,
    borderRadius: BorderRadius.circular(OneUIRadius.chip),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OneUIRadius.chip),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OneUISpacing.sm,
          vertical: OneUISpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: OneUITypography.labelMedium.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Switch / Toggle

```dart
Widget buildOneUISwitch({
  required bool value,
  required ValueChanged<bool> onChanged,
  bool isDark = true,
}) {
  return Switch(
    value: value,
    onChanged: onChanged,
    activeColor: OneUIColors.primary,
    activeTrackColor: OneUIColors.primary.withOpacity(0.4),
    inactiveThumbColor: isDark ? Colors.white : Colors.grey[400],
    inactiveTrackColor: isDark 
        ? Colors.white.withOpacity(0.2) 
        : Colors.black.withOpacity(0.1),
  );
}
```

---

## 🔣 Icons

### Icon Sizes

```dart
class OneUIIconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

### Icon Style Guidelines

- Use **outlined icons** by default
- Use **filled icons** for selected/active states
- Maintain consistent stroke width
- Prefer Cupertino icons on iOS, Material icons on Android

---

## 🎬 Animations & Transitions

### Duration Standards

```dart
class OneUIAnimation {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration emphasis = Duration(milliseconds: 500);
}
```

### Curve Standards

```dart
class OneUICurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
}
```

### Page Transitions

```dart
PageRouteBuilder oneUIPageRoute({
  required Widget page,
  RouteSettings? settings,
}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      
      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: OneUIAnimation.normal,
    reverseTransitionDuration: OneUIAnimation.fast,
  );
}
```

---

## 🌙 Dark Mode

### Theme Implementation

```dart
ThemeData oneUIDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: OneUIColors.backgroundDark,
    primaryColor: OneUIColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: OneUIColors.primary,
      secondary: OneUIColors.primaryLight,
      surface: OneUIColors.surfaceDark,
      error: OneUIColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: OneUIColors.backgroundDark,
      elevation: 0,
      iconTheme: IconThemeData(color: OneUIColors.textPrimaryDark),
      titleTextStyle: TextStyle(
        color: OneUIColors.textPrimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: OneUIColors.navBarDark,
      selectedItemColor: OneUIColors.primary,
      unselectedItemColor: OneUIColors.textSecondaryDark,
    ),
    cardTheme: CardTheme(
      color: OneUIColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneUIRadius.card),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: OneUIColors.dividerDark,
      thickness: 1,
    ),
  );
}

ThemeData oneUILightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: OneUIColors.backgroundLight,
    primaryColor: OneUIColors.primary,
    colorScheme: const ColorScheme.light(
      primary: OneUIColors.primary,
      secondary: OneUIColors.primaryLight,
      surface: OneUIColors.surfaceLight,
      error: OneUIColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: OneUIColors.backgroundLight,
      elevation: 0,
      iconTheme: IconThemeData(color: OneUIColors.textPrimaryLight),
      titleTextStyle: TextStyle(
        color: OneUIColors.textPrimaryLight,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: OneUIColors.navBarLight,
      selectedItemColor: OneUIColors.primary,
      unselectedItemColor: OneUIColors.textSecondaryLight,
    ),
    cardTheme: CardTheme(
      color: OneUIColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OneUIRadius.card),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: OneUIColors.dividerLight,
      thickness: 1,
    ),
  );
}
```

---

## ♿ Accessibility

### Touch Targets

- **Minimum touch target size**: 44x44 logical pixels
- **Recommended touch target size**: 48x48 logical pixels
- **Spacing between targets**: Minimum 8 logical pixels

### Text Scaling

```dart
// Ensure text scales with system settings
Text(
  'Label',
  style: OneUITypography.bodyMedium,
  textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.5),
)
```

### Semantic Labels

```dart
// Always provide semantic labels for icons
IconButton(
  icon: const Icon(Icons.menu),
  onPressed: openMenu,
  tooltip: 'Open menu',  // Important for accessibility
)
```

---

## 📱 Flutter Implementation

### Complete Theme Setup

```dart
// lib/core/theme/one_ui_theme.dart

import 'package:flutter/material.dart';

class OneUITheme {
  // Use this in MaterialApp
  static ThemeData get dark => oneUIDarkTheme();
  static ThemeData get light => oneUILightTheme();
  
  // Helper to check current theme
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  // Get appropriate color based on theme
  static Color surface(BuildContext context) {
    return isDark(context) ? OneUIColors.surfaceDark : OneUIColors.surfaceLight;
  }
  
  static Color background(BuildContext context) {
    return isDark(context) ? OneUIColors.backgroundDark : OneUIColors.backgroundLight;
  }
  
  static Color textPrimary(BuildContext context) {
    return isDark(context) ? OneUIColors.textPrimaryDark : OneUIColors.textPrimaryLight;
  }
  
  static Color textSecondary(BuildContext context) {
    return isDark(context) ? OneUIColors.textSecondaryDark : OneUIColors.textSecondaryLight;
  }
}
```

### Usage in App

```dart
// main.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One UI 8.5 App',
      theme: OneUITheme.light,
      darkTheme: OneUITheme.dark,
      themeMode: ThemeMode.system,  // Follow system theme
      home: const HomeScreen(),
    );
  }
}
```

---

## ✅ Checklist for UI Conversion

### Pre-Conversion
- [ ] Audit all screens and components
- [ ] Create component inventory
- [ ] Set up theme files
- [ ] Import color and typography constants

### Core Elements
- [ ] Update `MaterialApp` with One UI themes
- [ ] Convert all Scaffold backgrounds
- [ ] Update AppBar styles
- [ ] Convert bottom navigation bars
- [ ] Update floating action buttons

### Components
- [ ] Convert all buttons (primary, secondary, icon)
- [ ] Update text fields and forms
- [ ] Convert cards and containers
- [ ] Update dialogs and bottom sheets
- [ ] Convert list tiles and list views
- [ ] Update chips and badges
- [ ] Convert switches and checkboxes
- [ ] Update sliders and progress indicators

### Typography
- [ ] Replace all text styles with One UI typography
- [ ] Ensure proper text colors for theme
- [ ] Update font weights and letter spacing

### Spacing & Layout
- [ ] Apply consistent spacing scale
- [ ] Update border radius values
- [ ] Apply proper shadows and elevation

### Polish
- [ ] Add page transitions
- [ ] Implement loading states
- [ ] Add micro-interactions
- [ ] Test dark/light mode switching
- [ ] Verify accessibility compliance

---

## 📚 Resources

- [Samsung One UI Design Guidelines](https://developer.samsung.com/one-ui)
- [Material Design 3](https://m3.material.io/)
- [Flutter Documentation](https://flutter.dev/docs)

---

*Last Updated: January 2026*
*Version: One UI 8.5 Compatible*
