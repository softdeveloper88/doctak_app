import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// A reusable DocTak app bar widget that provides consistent One UI 8.5 styling
class DoctakAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final bool centerTitle;
  final double toolbarHeight;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Widget? customLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final String? titleFontFamily;
  final bool automaticallyImplyLeading;

  const DoctakAppBar({
    super.key,
    required this.title,
    this.titleIcon,
    this.actions,
    this.centerTitle = true,
    this.toolbarHeight = 70,
    this.onBackPressed,
    this.showBackButton = true,
    this.customLeading,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.titleColor,
    this.titleFontSize = 18,
    this.titleFontWeight = FontWeight.w600,
    this.titleFontFamily = 'Poppins',
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      decoration: theme.appBarDecoration.copyWith(color: backgroundColor ?? theme.appBarBackground),
      child: AppBar(
        toolbarHeight: toolbarHeight,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: theme.iconColor),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: automaticallyImplyLeading ? customLeading ?? (showBackButton ? _buildBackButton(context, theme) : null) : null,
        title: _buildTitle(context, theme),
        actions: actions,
        bottom: bottom,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onBackPressed ?? () => Navigator.pop(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: theme.iconButtonDecoration(),
            child: Icon(CupertinoIcons.back, color: theme.primary, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, OneUITheme theme) {
    final effectiveTitleColor = titleColor ?? theme.primary;

    if (titleIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, fontFamily: titleFontFamily, color: effectiveTitleColor, letterSpacing: -0.2),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, fontFamily: titleFontFamily, color: effectiveTitleColor, letterSpacing: -0.2),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

/// A custom sliver app bar for screens that need scrollable content with One UI 8.5 styling
class DoctakSliverAppBar extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final bool centerTitle;
  final double expandedHeight;
  final bool floating;
  final bool pinned;
  final bool snap;
  final Widget? flexibleSpace;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Widget? customLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final String? titleFontFamily;
  final double? collapsedHeight;

  const DoctakSliverAppBar({
    super.key,
    required this.title,
    this.titleIcon,
    this.actions,
    this.centerTitle = true,
    this.expandedHeight = 120.0,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.flexibleSpace,
    this.onBackPressed,
    this.showBackButton = true,
    this.customLeading,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.titleColor,
    this.titleFontSize = 18,
    this.titleFontWeight = FontWeight.w600,
    this.titleFontFamily = 'Poppins',
    this.collapsedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      collapsedHeight: collapsedHeight,
      backgroundColor: backgroundColor ?? theme.appBarBackground,
      surfaceTintColor: backgroundColor ?? theme.appBarBackground,
      iconTheme: IconThemeData(color: theme.iconColor),
      elevation: elevation,
      centerTitle: centerTitle,
      leading: customLeading ?? (showBackButton ? _buildBackButton(context, theme) : null),
      title: _buildTitle(context, theme),
      actions: actions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
    );
  }

  Widget _buildBackButton(BuildContext context, OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onBackPressed ?? () => Navigator.pop(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: theme.iconButtonDecoration(),
            child: Icon(CupertinoIcons.back, color: theme.primary, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, OneUITheme theme) {
    final effectiveTitleColor = titleColor ?? theme.primary;

    if (titleIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, fontFamily: titleFontFamily, color: effectiveTitleColor, letterSpacing: -0.2),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, fontFamily: titleFontFamily, color: effectiveTitleColor, letterSpacing: -0.2),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
