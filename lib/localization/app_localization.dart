// import 'en_us/en_us_translations.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/cupertino.dart';
// import '../core/app_export.dart';
// class AppLocalization {
//   AppLocalization(this.locale);
//
//   Locale locale;
//
//   static final Map<String, Map<String, String>> _localizedValues = {'en': enUs};
//
//   static AppLocalization of() {
//     return Localizations.of<AppLocalization>(
//         NavigatorService.navigatorKey.currentContext!, AppLocalization)!;
//   }
//
//   static List<String> languages() => _localizedValues.keys.toList();
//   String getString(String text) =>
//       _localizedValues[locale.languageCode]![text] ?? text;
// }
//
// class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctak_app/l10n/app_localizations.dart';

const String LAGUAGE_CODE = 'languageCode';

//languages code
const String ENGLISH = 'en';
const String FARSI = 'fa';
const String ARABIC = 'ar';
const String FRENCH = 'fr';
const String SPANISH = 'es';
const String GERMAN = 'de';
const String HINDI = 'hi';
const String URDU = 'ur';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String languageCode = _prefs.getString(LAGUAGE_CODE) ?? ENGLISH;
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case ENGLISH:
      return const Locale(ENGLISH, '');
    case FARSI:
      return const Locale(FARSI, "");
    case ARABIC:
      return const Locale(ARABIC, "");
    case FRENCH:
      return const Locale(FRENCH, "");
    case SPANISH:
      return const Locale(SPANISH, "");
    case GERMAN:
      return const Locale(GERMAN, "");
    case HINDI:
      return const Locale(HINDI, "");
    case URDU:
      return const Locale(URDU, "");
    default:
      return const Locale(ENGLISH, '');
  }
}

AppLocalizations translation(BuildContext context) {
  return AppLocalizations.of(context)!;
}
