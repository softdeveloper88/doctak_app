import 'dart:io';

import 'package:doctak_app/presentation/home_screen/fragments/add_post/components/check_place_bottom_sheet.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/components/tag_friends_list_bottom_sheet.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import 'SVConstants.dart';

InputDecoration svInputDecoration(BuildContext context,
    {String? hint,
    String? label,
    TextStyle? hintStyle,
    TextStyle? labelStyle,
    Widget? prefix,
    EdgeInsetsGeometry? contentPadding,
    Widget? prefixIcon}) {
  return InputDecoration(
    contentPadding: contentPadding,
    labelText: label,
    hintText: hint,
    hintStyle: hintStyle ?? secondaryTextStyle(),
    labelStyle: labelStyle ?? secondaryTextStyle(),
    prefix: prefix,
    prefixIcon: prefixIcon,
    errorMaxLines: 2,
    errorStyle: primaryTextStyle(color: Colors.red, size: 12),
    enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: SVAppBorderColor)),
    focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: SVAppColorPrimary)),
    border: const UnderlineInputBorder(
        borderSide: BorderSide(color: SVAppColorPrimary)),
    focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.0)),
    errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.0)),
    alignLabelWithHint: true,
  );
}

Widget svRobotoText(
    {required String text,
    Color? color,
    FontStyle? fontStyle,
    Function? onTap,
    TextAlign? textAlign}) {
  return Text(
    text,
    style: secondaryTextStyle(
      fontFamily: svFontRoboto,
      color: color ?? svGetBodyColor(),
      fontStyle: fontStyle ?? FontStyle.normal,
    ),
    textAlign: textAlign ?? TextAlign.center,
  ).onTap(onTap,
      splashColor: Colors.transparent, highlightColor: Colors.transparent);
}

Color svGetBodyColor() {
  if (appStore.isDarkMode) {
    return SVBodyDark;
  } else {
    return SVBodyWhite;
  }
}

Color svGetBgColor() {
  if (appStore.isDarkMode) {
    return appBackgroundColorDark;
  } else {
    return  SVCardGray;
  }
}

Color svGetScaffoldColor() {
  if (appStore.isDarkMode) {
    return appBackgroundColorDark;
  } else {
    return defaultBgColor;
  }
}

Widget svHeaderContainer(
    {required Widget child, required BuildContext context}) {
  return Stack(
    alignment: Alignment.bottomCenter,
    children: [
      Container(
        width: context.width(),
        decoration: BoxDecoration(
            color: SVAppColorPrimary,
            borderRadius: radiusOnly(
                topLeft: SVAppContainerRadius, topRight: SVAppContainerRadius)),
        padding: const EdgeInsets.all(24),
        child: child,
      ),
      Container(
        height: 20,
        decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radiusOnly(
                topLeft: SVAppContainerRadius, topRight: SVAppContainerRadius)),
      )
    ],
  );
}

Widget svAppButton(
    {required String text,
    required Function onTap,
    double? width,
    Color? color,
    required BuildContext context}) {
  return AppButton(
    shapeBorder: RoundedRectangleBorder(borderRadius: radius(10)),
    text: text,
    textStyle: boldTextStyle(color: Colors.white),
    onTap: onTap,
    elevation: 0,
    color: color??SVAppColorPrimary,
    width: width ?? context.width() - 32,
    height: 50,
  );
}

Future<File> svGetImageSource() async {
  final picker = ImagePicker();
  final pickedImage = await picker.pickImage(source: ImageSource.camera);
  return File(pickedImage!.path);
}

void svShowShareBottomSheet(BuildContext context, searchPeopleBloc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: context.cardColor,
    shape: RoundedRectangleBorder(
        borderRadius: radiusOnly(topLeft: 30, topRight: 30)),
    builder: (context) {
      return TagFriendsListBottomSheet(searchPeopleBloc);
    },
  );
}

void checkInPlaceBottomSheet(BuildContext context, addPostBloc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: context.cardColor,
    shape: RoundedRectangleBorder(
        borderRadius: radiusOnly(topLeft: 30, topRight: 30)),
    builder: (context) {
      return CheckPlaceBottomSheet(addPostBloc);
    },
  );
}
