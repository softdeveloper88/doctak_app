import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// ignore: must_be_immutable
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.height,
    this.leadingWidth,
    this.leading,
    this.title,
    this.centerTitle,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
  });

  final double? height;
  final double? leadingWidth;
  final Widget? leading;
  final Widget? title;
  final bool? centerTitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final effectiveBg = backgroundColor ?? theme.appBarBackground;

    Widget? effectiveLeading = leading;
    double? effectiveLeadingWidth = leadingWidth ?? 0;

    if (showBackButton && leading == null) {
      effectiveLeadingWidth = 48;
      effectiveLeading = IconButton(
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        icon: Icon(CupertinoIcons.back, color: theme.iconColor, size: 22),
        tooltip: 'Back',
      );
    }

    return Container(
      decoration: theme.appBarDecoration.copyWith(color: effectiveBg),
      child: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: height ?? 56,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        leadingWidth: effectiveLeadingWidth,
        leading: effectiveLeading,
        title: title,
        titleSpacing: leading == null && !showBackButton ? 16 : 0,
        centerTitle: centerTitle ?? false,
        actions: actions,
        iconTheme: IconThemeData(color: theme.iconColor),
      ),
    );
  }

  @override
  Size get preferredSize => Size(100.w, height ?? 56);
}
