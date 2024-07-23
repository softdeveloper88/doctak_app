import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: SVAppLayoutBackground,
    primaryColor: SVAppColorPrimary,
    primaryColorDark: SVAppColorPrimary,
    hoverColor: Colors.white54,
    dividerColor: viewLineColor,
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: AppBarTheme(
      color: SVAppLayoutBackground,
      iconTheme: IconThemeData(color: textPrimaryColor),
      systemOverlayStyle:
          SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black),
    cardTheme: CardTheme(color: Colors.white),
    cardColor: SVAppSectionBackground,
    iconTheme: IconThemeData(color: textPrimaryColor),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: whiteColor),
    textTheme: TextTheme(
      labelLarge: TextStyle(color: SVAppColorPrimary),
      titleLarge: TextStyle(color: textPrimaryColor),
      titleSmall: TextStyle(color: textSecondaryColor),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.light(primary: SVAppColorPrimary)
        .copyWith(error: Colors.red),
  ).copyWith(
    pageTransitionsTheme:
        PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
    }),
  );

  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: appBackgroundColorDark,
    highlightColor: appBackgroundColorDark,
    appBarTheme: AppBarTheme(
      color: appBackgroundColorDark,
      iconTheme: IconThemeData(color: blackColor),
      systemOverlayStyle:
          SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
    ),
    primaryColor: color_primary_black,
    dividerColor: Color(0xFFDADADA).withOpacity(0.3),
    primaryColorDark: color_primary_black,
    textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.white),
    hoverColor: Colors.black12,
    fontFamily: GoogleFonts.inter().fontFamily,
    bottomSheetTheme:
        BottomSheetThemeData(backgroundColor: appBackgroundColorDark),
    primaryTextTheme: TextTheme(
        titleLarge: primaryTextStyle(color: Colors.white),
        labelSmall: primaryTextStyle(color: Colors.white)),
    cardTheme: CardTheme(color: cardBackgroundBlackDark),
    cardColor: cardBackgroundBlackDark,
    iconTheme: IconThemeData(color: whiteColor),
    textTheme: TextTheme(
      labelLarge: TextStyle(color: color_primary_black),
      titleLarge: TextStyle(color: whiteColor),
      titleSmall: TextStyle(color: Colors.white54),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.dark(
            primary: appBackgroundColorDark, onPrimary: cardBackgroundBlackDark)
        .copyWith(secondary: whiteColor)
        .copyWith(error: Color(0xFFCF6676)),
  ).copyWith(
    pageTransitionsTheme:
        PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
    }),
  );
}
