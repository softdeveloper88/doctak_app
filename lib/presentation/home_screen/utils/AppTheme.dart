import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SVAppLayoutBackground,
    primaryColor: SVAppColorPrimary,
    primaryColorDark: SVAppColorPrimary,
    hoverColor: Colors.white54,
    dividerColor: viewLineColor,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      color: SVAppLayoutBackground,
      iconTheme: IconThemeData(color: textPrimaryColor),
      systemOverlayStyle:
          SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
    cardTheme: const CardThemeData(color: Colors.white),
    cardColor: SVAppSectionBackground,
    iconTheme: const IconThemeData(color: textPrimaryColor),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: whiteColor),
    textTheme: const TextTheme(
      labelLarge: TextStyle(color: SVAppColorPrimary,fontFamily:  'Poppins',),
      titleLarge: TextStyle(color: textPrimaryColor,fontFamily:  'Poppins',),
      titleSmall: TextStyle(color: textSecondaryColor,fontFamily:  'Poppins',),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: const ColorScheme.light(primary: SVAppColorPrimary)
        .copyWith(error: Colors.red),
  ).copyWith(
    pageTransitionsTheme:
        const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: const OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: const OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: const OpenUpwardsPageTransitionsBuilder(),
    }),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: appBackgroundColorDark,
    highlightColor: appBackgroundColorDark,
    appBarTheme: const AppBarTheme(
      color: appBackgroundColorDark,
      iconTheme: IconThemeData(color: blackColor),
      systemOverlayStyle:
          SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
    ),
    primaryColor: color_primary_black,
    dividerColor: const Color(0xFFDADADA).withOpacity(0.3),
    primaryColorDark: color_primary_black,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.white),
    hoverColor: Colors.black12,
    fontFamily: 'Poppins',
    bottomSheetTheme:
        const BottomSheetThemeData(backgroundColor: appBackgroundColorDark),
    primaryTextTheme: TextTheme(
        titleLarge: primaryTextStyle(color: Colors.white),
        labelSmall: primaryTextStyle(color: Colors.white)),
    cardTheme: const CardThemeData(color: cardBackgroundBlackDark),
    cardColor: cardBackgroundBlackDark,
    iconTheme: const IconThemeData(color: whiteColor),
    textTheme: const TextTheme(
      labelLarge: TextStyle(color: color_primary_black,fontFamily:  'Poppins',fontWeight:FontWeight.w400),
      titleLarge: TextStyle(color: whiteColor,fontFamily:  'Poppins',fontWeight: FontWeight.w400),
      titleSmall: TextStyle(color: Colors.white54,fontFamily:  'Poppins',fontWeight:FontWeight.w300),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: const ColorScheme.dark(
            primary: appBackgroundColorDark, onPrimary: cardBackgroundBlackDark)
        .copyWith(secondary: whiteColor)
        .copyWith(error: Color(0xFFCF6676)),
  ).copyWith(
    pageTransitionsTheme:
        const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: const OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: const OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: const OpenUpwardsPageTransitionsBuilder(),
    }),
  );
}
