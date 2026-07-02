import 'package:flutter/material.dart';

/// Shared screen inset and card spacing for case discussion screens.
abstract final class CaseDiscussionLayout {
  static const double screenHorizontal = 16;
  static const double screenTop = 12;
  static const double sectionGap = 10;
  static const double cardInner = 16;
  static const double listBottom = 80;

  static const EdgeInsets screenInset = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  static const EdgeInsets sectionMargin = EdgeInsets.fromLTRB(
    screenHorizontal,
    sectionGap,
    screenHorizontal,
    0,
  );

  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(
    screenHorizontal,
    8,
    screenHorizontal,
    listBottom,
  );
}
