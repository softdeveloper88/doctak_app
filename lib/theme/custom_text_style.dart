import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../presentation/home_screen/utils/SVColors.dart';

/// A collection of pre-defined text styles for customizing text appearance,
/// categorized by different font families and weights.
/// Additionally, this class includes extensions on [TextStyle] to easily apply specific font families to text.

class CustomTextStyles {
  // Body text style
  static TextStyle get bodyLargeBluegray400 => theme.textTheme.bodyLarge!.copyWith(color: appTheme.blueGray400);
  static TextStyle get bodyMediumBluegray400 => theme.textTheme.bodyMedium!.copyWith(color: appTheme.blueGray400);
  static TextStyle get bodyMediumGray500 => theme.textTheme.bodyMedium!.copyWith(color: appTheme.gray500);
  static TextStyle get bodyMediumGray600 => theme.textTheme.bodyMedium!.copyWith(color: appTheme.gray600);
  static TextStyle get bodyMediumOnPrimary => theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onPrimary);
  static TextStyle get bodyMediumSFProDisplayErrorContainer => theme.textTheme.bodyMedium!.sFProDisplay.copyWith(color: theme.colorScheme.errorContainer);
  static TextStyle get bodyMediumWhiteA700 => theme.textTheme.bodyMedium!.copyWith(color: appTheme.whiteA700);
  static TextStyle get bodySmallBluegray400 => theme.textTheme.bodySmall!.copyWith(color: appTheme.blueGray400);
  static TextStyle get bodySmallBluegray700 => theme.textTheme.bodySmall!.copyWith(color: appTheme.blueGray700);
  static TextStyle get bodySmallGray600 => theme.textTheme.bodySmall!.copyWith(color: appTheme.gray600);
  static TextStyle get bodySmallOnPrimary => theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onPrimary);
  // Headline text style
  static TextStyle get headlineSmallPrimary => theme.textTheme.headlineSmall!.copyWith(color: theme.colorScheme.primary, fontSize: 25.sp);
  static TextStyle get headlineSmallSemiBold => theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600);
  // Label text style
  static TextStyle get labelLargeAmber500 => theme.textTheme.labelLarge!.copyWith(color: appTheme.amber500);
  static TextStyle get labelLargeAmber500SemiBold => theme.textTheme.labelLarge!.copyWith(color: appTheme.amber500, fontWeight: FontWeight.w600);
  static TextStyle get labelLargeBluegray400 => theme.textTheme.labelLarge!.copyWith(color: appTheme.blueGray400);
  static TextStyle get labelLargeBluegray700 => theme.textTheme.labelLarge!.copyWith(color: appTheme.blueGray700);
  static TextStyle get labelLargeErrorContainer => theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.errorContainer, fontSize: 13.sp);
  static TextStyle get labelLargeOnPrimary => theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600);
  static TextStyle get labelLargePrimary => theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600);
  static TextStyle get labelLargePrimary_1 => theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.primary);
  static TextStyle get labelLargeWhiteA700 => theme.textTheme.labelLarge!.copyWith(color: appTheme.whiteA700, fontWeight: FontWeight.w600);
  static TextStyle get labelMediumBlue50 => theme.textTheme.labelMedium!.copyWith(color: appTheme.blue50, fontWeight: FontWeight.w600);
  static TextStyle get labelMediumPrimary => theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.primary);
  static TextStyle get labelSmallInterPrimary => theme.textTheme.labelSmall!.inter.copyWith(color: theme.colorScheme.primary, fontSize: 9.sp, fontWeight: FontWeight.w500);
  static TextStyle get labelSmallInterWhiteA700 => theme.textTheme.labelSmall!.inter.copyWith(color: appTheme.whiteA700, fontSize: 9.sp);
  // Title text style
  static TextStyle get titleLargeSemiBold => theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get titleMedium18 => theme.textTheme.titleMedium!.copyWith(fontSize: 18.sp);
  static TextStyle get titleMediumBlack900 => theme.textTheme.titleMedium!.copyWith(color: appTheme.black900);
  static TextStyle get titleMediumBold => theme.textTheme.titleMedium!.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700);
  static TextStyle get titleMediumErrorContainer => theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.errorContainer);
  static TextStyle get titleMediumGray500 => theme.textTheme.titleMedium!.copyWith(color: appTheme.gray500, fontWeight: FontWeight.w500);
  static TextStyle get titleMediumGray500Medium => theme.textTheme.titleMedium!.copyWith(color: appTheme.gray500, fontWeight: FontWeight.w500);
  static TextStyle get titleMediumGray500_1 => theme.textTheme.titleMedium!.copyWith(color: appTheme.gray500);
  static TextStyle get titleMediumGray600 => theme.textTheme.titleMedium!.copyWith(color: appTheme.gray600, fontWeight: FontWeight.w500);
  static TextStyle get titleMediumInterPrimaryContainer => theme.textTheme.titleMedium!.inter.copyWith(color: theme.colorScheme.primaryContainer, fontWeight: FontWeight.w900);
  static TextStyle get titleMediumMedium => theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get titleMediumMedium_1 => theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get titleMediumPrimary => theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.primary);
  static TextStyle get titleMediumRedA200 => theme.textTheme.titleMedium!.copyWith(color: appTheme.redA200);
  static TextStyle get titleMediumWhiteA700 => theme.textTheme.titleMedium!.copyWith(color: SVAppColorPrimary, fontStyle: FontStyle.italic);
  static TextStyle get titleMediumWhiteA70018 => theme.textTheme.titleMedium!.copyWith(color: appTheme.whiteA700, fontSize: 18.sp);
  static TextStyle get titleSmallAmber500 => theme.textTheme.titleSmall!.copyWith(color: appTheme.amber500, fontWeight: FontWeight.w600);
  static TextStyle get titleSmallBlack900 => theme.textTheme.titleSmall!.copyWith(color: appTheme.black900, fontWeight: FontWeight.w600);
  static TextStyle get titleSmallBluegray400 => theme.textTheme.titleSmall!.copyWith(color: appTheme.blueGray400);
  static TextStyle get titleSmallBluegray700 => theme.textTheme.titleSmall!.copyWith(color: appTheme.blueGray700, fontWeight: FontWeight.w600);
  static TextStyle get titleSmallErrorContainer => theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.errorContainer);
  static TextStyle get titleSmallOnPrimary => theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600);
  static TextStyle get titleSmallPrimary => theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary);
  static TextStyle get titleSmallPrimarySemiBold => theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600);
  static TextStyle get titleSmallWhiteA700 => theme.textTheme.titleSmall!.copyWith(color: appTheme.whiteA700);
  static TextStyle get titleSmallWhiteA700SemiBold => theme.textTheme.titleSmall!.copyWith(color: appTheme.whiteA700, fontWeight: FontWeight.w600);
}

extension on TextStyle {
  TextStyle get inter {
    return copyWith(fontFamily: 'Inter');
  }

  TextStyle get raleway {
    return copyWith(fontFamily: 'Raleway');
  }

  TextStyle get sFProDisplay {
    return copyWith(fontFamily: 'SF Pro Display');
  }
}
