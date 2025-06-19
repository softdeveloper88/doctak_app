import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_export.dart';

/// Helper class for managing themes and colors.

class ThemeHelper {
  // Updated modern dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF227DDE), // Using your primary blue
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF141414), // Darker background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF444444),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF444444),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF227DDE), // Using your primary blue
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF212121), // Darker input background
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF1D1D1D), // Slightly lighter than background
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF227DDE), // Using your primary blue
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      horizontalTitleGap: 8,
      visualDensity: VisualDensity.compact,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF333333),
      thickness: 1,
      space: 1,
    ),
    fontFamily: 'Raleway', // Using your app's font
  );

  // Modern Light Theme - Using your theme structure and colors
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF227DDE), // Using your primary blue
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8FA), // Light grey background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF0B0C0C), // Your onPrimary color
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF227DDE), // Your primary color
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: Color(0xFFE0E2E4)), // Your gray300
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE0E2E4), // Your gray300
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE0E2E4), // Your gray300
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF227DDE), // Your primary color
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF227DDE), // Your primary color
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      dense: true,
      horizontalTitleGap: 8,
      visualDensity: VisualDensity.compact,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E2E4), // Your gray300
      thickness: 1,
      space: 1,
    ),
    fontFamily: 'Raleway', // Using your app's font
  );

  // The current app theme
  final _appTheme = PrefUtils().getThemeData();

  // A map of custom color themes supported by the app
  final Map<String, PrimaryColors> _supportedCustomColor = {
    'primary': PrimaryColors()
  };

  // A map of color schemes supported by the app
  final Map<String, ColorScheme> _supportedColorScheme = {
    'primary': ColorSchemes.primaryColorScheme
  };

  /// Returns the primary colors for the current theme.
  PrimaryColors _getThemeColors() {
    //throw exception to notify given theme is not found or not generated by the generator
    if (!_supportedCustomColor.containsKey(_appTheme)) {
      throw Exception(
          "$_appTheme is not found.Make sure you have added this theme class in JSON Try running flutter pub run build_runner");
    }
    //return theme from map

    return _supportedCustomColor[_appTheme] ?? PrimaryColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    // Check if user has selected dark mode
    if (_appTheme == 'dark') {
      return darkTheme;
    }

    // Check if user has selected light mode
    if (_appTheme == 'light') {
      return lightTheme;
    }

    // Default fallback to your existing theme system
    //throw exception to notify given theme is not found or not generated by the generator
    if (!_supportedColorScheme.containsKey(_appTheme)) {
      throw Exception(
          "$_appTheme is not found.Make sure you have added this theme class in JSON Try running flutter pub run build_runner");
    }

    //return theme from map
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.primaryColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      textTheme: TextThemes.textTheme(colorScheme),
      scaffoldBackgroundColor: appTheme.whiteA700,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: appTheme.gray300,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          visualDensity: const VisualDensity(
            vertical: -4,
            horizontal: -4,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface;
        }),
        side: const BorderSide(
          width: 1,
        ),
        visualDensity: const VisualDensity(
          vertical: -4,
          horizontal: -4,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: appTheme.gray300,
      ),
    );
  }

  /// Returns the primary colors for the current theme.
  PrimaryColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

/// Class containing the supported text theme styles.
class TextThemes {
  static TextTheme textTheme(ColorScheme colorScheme) => TextTheme(
    bodyLarge: TextStyle(
      color: appTheme.gray500,
      fontSize: 16,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      color: appTheme.blueGray700,
      fontSize: 14,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      color: appTheme.gray500,
      fontSize: 12,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w400,
    ),
    displayMedium: TextStyle(
      color: appTheme.whiteA700,
      fontSize: 50,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      color: colorScheme.onPrimary,
      fontSize: 24,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w700,
    ),
    labelLarge: TextStyle(
      color: appTheme.gray500,
      fontSize: 12,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      color: appTheme.gray500,
      fontSize: 10,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      color: appTheme.gray500,
      fontSize: 8,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: colorScheme.onPrimary,
      fontSize: 22,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: colorScheme.onPrimary,
      fontSize: 16,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: appTheme.gray500,
      fontSize: 14,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w500,
    ),
  );
}

/// Class containing the supported color schemes.
class ColorSchemes {
  static final primaryColorScheme = const ColorScheme.light(
    // Primary colors
    primary: Color(0XFF227DDE),
    primaryContainer: Color(0XFF1A1F71),
    secondaryContainer: Color(0XFF219ADE),

    // Error colors
    errorContainer: Color(0XFF2B2E32),
    onError: Color(0XFF216DDE),
    onErrorContainer: Color(0XFFF4F9FD),

    // On colors(text colors)
    onPrimary: Color(0XFF0B0C0C),
    onPrimaryContainer: Color(0XFFC2C5C9),
  );
}

/// Class containing custom colors for a primary theme.
class PrimaryColors {
  // Amber
  Color get amber500 => const Color(0XFFFBBC05);

  // Black
  Color get black900 => const Color(0XFF000000);

  // Blue
  Color get blue300 => const Color(0XFF6FAAEA);
  Color get blue50 => const Color(0XFFDEEBFA);

  // BlueGray
  Color get blueGray400 => const Color(0XFF848B93);
  Color get blueGray700 => const Color(0XFF4C5157);

  // Gray
  Color get gray100 => const Color(0XFFF2F4F6);
  Color get gray300 => const Color(0XFFE0E2E4);
  Color get gray500 => const Color(0XFF90979E);
  Color get gray600 => const Color(0XFF6D747C);
  Color get gray60014 => const Color(0X147C7C7C);

  // Green
  Color get green600 => const Color(0XFF359766);

  // Red
  Color get red50 => const Color(0XFFFFEAEA);
  Color get red500 => const Color(0XFFEA4335);
  Color get red700 => const Color(0XFFD13329);
  Color get redA200 => const Color(0XFFFF5C5C);

  // White
  Color get whiteA700 => const Color(0XFFFFFFFF);
}

PrimaryColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();