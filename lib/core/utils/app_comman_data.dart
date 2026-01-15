import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

void log(Object? value) {
  if (!kReleaseMode) print(value);
}

bool hasMatch(String? s, String p) {
  return (s == null) ? false : RegExp(p).hasMatch(s);
}

Color getColorFromHex(String hexColor, {Color? defaultColor}) {
  if (hexColor.isEmpty) {
    if (defaultColor != null) {
      return defaultColor;
    } else {
      throw ArgumentError('Can not parse provided hex $hexColor');
    }
  }

  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}

void toast(String? value, {ToastGravity? gravity, length = Toast.LENGTH_SHORT, Color? bgColor, Color? textColor, bool print = false}) {
  // Handle null or empty value safely without using nb_utils extensions
  final message = value ?? '';
  if (message.isEmpty || (!kIsWeb && Platform.isLinux)) {
    log(message.isEmpty ? 'Empty toast message' : message);
  } else {
    try {
      Fluttertoast.showToast(msg: message, gravity: gravity ?? ToastGravity.CENTER, toastLength: length, backgroundColor: bgColor, textColor: textColor, timeInSecForIosWeb: 2);
      if (print) log(message);
    } catch (e) {
      log('Toast error: $e - Message: $message');
    }
  }
}

/// Returns MaterialColor from Color
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(r + ((ds < 0 ? r : (255 - r)) * ds).round(), g + ((ds < 0 ? g : (255 - g)) * ds).round(), b + ((ds < 0 ? b : (255 - b)) * ds).round(), 1);
  }
  return MaterialColor(color.value, swatch);
}

class DefaultValues {
  final String defaultLanguage = "en";
}

Future<void> launchInBrowser(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

DefaultValues defaultValues = DefaultValues();
