import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Drawer menu SVG icons extracted from the DocTak Mobile reference HTML.
abstract final class DrawerIconAssets {
  static const _base = 'assets/icon/drawer';

  static const close = '$_base/ic_close.svg';
  static const verified = '$_base/ic_verified.svg';
  static const star = '$_base/ic_star.svg';
  static const doctakAi = '$_base/ic_doctak_ai.svg';
  static const chevronRight = '$_base/ic_chevron_right.svg';
  static const signOut = '$_base/ic_sign_out.svg';

  static const jobs = '$_base/ic_jobs.svg';
  static const drugs = '$_base/ic_drugs.svg';
  static const guidelines = '$_base/ic_guidelines.svg';
  static const cme = '$_base/ic_cme.svg';
  static const diagnosis = '$_base/ic_diagnosis.svg';
  static const discussions = '$_base/ic_discussions.svg';
  static const groups = '$_base/ic_groups.svg';
  static const conferences = '$_base/ic_conferences.svg';
  static const meetings = '$_base/ic_meetings.svg';
  static const suggestions = '$_base/ic_suggestions.svg';
  static const settings = '$_base/ic_settings.svg';
  static const moderation = '$_base/ic_moderation.svg';
  static const privacy = '$_base/ic_privacy.svg';
  static const about = '$_base/ic_about.svg';
}

class DrawerIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const DrawerIcon({
    super.key,
    required this.asset,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (_) => Icon(Icons.circle_outlined, size: size, color: color),
      errorBuilder: (_, __, ___) => Icon(Icons.circle_outlined, size: size, color: color),
    );
  }
}
